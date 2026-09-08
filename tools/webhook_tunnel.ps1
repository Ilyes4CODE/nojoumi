# A public HTTPS address for the Chargily webhook, during development.
#
# Article 7.3 has the gateway POST to our server, and Chargily cannot reach
# `localhost`. Open question Q19: Article 19 only commits the client to a VPS
# before Phase 7, while payments are Phase 6 - so until that server exists, a
# tunnel is what closes the loop.
#
# **cloudflared rather than ngrok.** ngrok now requires an account and an
# authtoken before it will open a tunnel; cloudflared's quick tunnels need
# neither, which matters for a step the client may have to repeat on their own
# machine. The trade is that the address is random and changes every run.
#
# ## What this script learned on 2026-08-30
#
# Five checkouts were created against a tunnel that had been dead since the
# previous night. Each one sat at "waiting for Chargily to confirm" for ever, because
# the gateway had nowhere to call back to. Two things had gone wrong, and this
# script now handles both:
#
#  * **the address was printed and left to be copied by hand.** It now writes
#    `CHARGILY_WEBHOOK_URL` into `server\.env` itself. A step a human has to
#    repeat correctly every single run is a step that eventually gets skipped.
#  * **the tunnel registered once and then failed for twenty hours**, filling
#    its log with retries while the window sat there looking healthy. The
#    address is now *tested through the public internet* before this script
#    claims success, and the process is watched afterwards.
#
# Usage, with the Django server already running on port 8000:
#
#     powershell -ExecutionPolicy Bypass -File tools\webhook_tunnel.ps1
#
# Leave the window open. Closing it closes the tunnel. **Restart the Django
# server afterwards** - it reads .env once, at startup.

$ErrorActionPreference = 'Stop'

$exe = Join-Path $PSScriptRoot 'bin\cloudflared.exe'
if (-not (Test-Path $exe)) {
    Write-Output "cloudflared is missing. Download it once with:"
    Write-Output '  curl.exe -sL -o tools\bin\cloudflared.exe https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe'
    exit 1
}

# Fail early and clearly rather than opening a tunnel to nothing.
try {
    Invoke-WebRequest -Uri 'http://127.0.0.1:8000/api/health/' -TimeoutSec 5 -UseBasicParsing | Out-Null
} catch {
    Write-Output "The Django server is not answering on port 8000."
    Write-Output "Start it first:  python manage.py runserver 0.0.0.0:8000"
    exit 1
}

# One tunnel at a time. A second cloudflared gets its own address, and then half
# the run is pointing at a hostname nothing wrote down.
Get-Process cloudflared -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 500

$log = Join-Path $env:TEMP 'lunio-tunnel.log'
if (Test-Path $log) { Remove-Item $log }

Write-Output "Opening a tunnel to http://localhost:8000 ..."
$proc = Start-Process -FilePath $exe `
    -ArgumentList '--no-autoupdate', 'tunnel', '--url', 'http://localhost:8000' `
    -RedirectStandardError $log -RedirectStandardOutput "$log.out" `
    -NoNewWindow -PassThru

# cloudflared prints the address into a banner a second or two after start.
$url = $null
for ($i = 0; $i -lt 30 -and -not $url; $i++) {
    Start-Sleep -Milliseconds 500
    if (Test-Path $log) {
        $match = Select-String -Path $log -Pattern 'https://[a-z0-9-]+\.trycloudflare\.com' |
                 Select-Object -First 1
        if ($match) { $url = $match.Matches[0].Value }
    }
}

if (-not $url) {
    Write-Output "The tunnel did not report an address. Full log: $log"
    Stop-Process -Id $proc.Id -Force
    exit 1
}

# Printing an address is not the same as having one that works. Chargily will
# reach this from the public internet, so that is where it gets tested from -
# the edge needs a few seconds to start routing a fresh quick tunnel.
Write-Output "Checking the address actually answers from outside ..."
$live = $false
for ($i = 0; $i -lt 20 -and -not $live; $i++) {
    Start-Sleep -Seconds 1
    try {
        Invoke-WebRequest -Uri "$url/api/health/" -TimeoutSec 5 -UseBasicParsing | Out-Null
        $live = $true
    } catch {
        # 4xx and 5xx still prove the tunnel routes; only a transport failure
        # means it does not.
        if ($_.Exception.Response) { $live = $true }
    }
}

if (-not $live) {
    Write-Output ""
    Write-Output "The tunnel opened but nothing answers through it. Full log: $log"
    Write-Output ".env was NOT changed - a checkout created now could never be confirmed."
    Stop-Process -Id $proc.Id -Force
    exit 1
}

$webhook = "$url/api/payments/webhook/chargily/"

# Write it where the server reads it. This is the step that used to be a
# human's job and was the cause of the 2026-08-30 stranded payments.
$envPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'server\.env'
if (Test-Path $envPath) {
    $lines = Get-Content $envPath
    if ($lines -match '^CHARGILY_WEBHOOK_URL=') {
        $lines = $lines -replace '^CHARGILY_WEBHOOK_URL=.*', "CHARGILY_WEBHOOK_URL=$webhook"
    } else {
        $lines += "CHARGILY_WEBHOOK_URL=$webhook"
    }
    # Explicitly BOM-less. `Set-Content -Encoding utf8` on PowerShell 5.1
    # writes a byte-order mark, and a BOM on the first line of .env makes
    # python-dotenv read the first key with the mark glued to its name - the
    # server would then start with no secret key, because of a webhook address.
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllLines($envPath, $lines, $utf8NoBom)
    $wrote = "written to server\.env"
} else {
    $wrote = "server\.env not found - set CHARGILY_WEBHOOK_URL by hand"
}

Write-Output ""
Write-Output "================================================================"
Write-Output " Tunnel is live and answering."
Write-Output ""
Write-Output "   CHARGILY_WEBHOOK_URL=$webhook"
Write-Output ""
Write-Output " $wrote"
Write-Output ""
Write-Output " NOW RESTART THE DJANGO SERVER. It reads .env once, at startup,"
Write-Output " so until it does it still holds the previous address."
Write-Output ""
Write-Output " The address changes every run. Keep this window open."
Write-Output "================================================================"
Write-Output ""
Write-Output "Ctrl+C to close the tunnel."

Wait-Process -Id $proc.Id
