# Deploying the backend to cPanel

The development server has been a laptop behind a `trycloudflare` tunnel. That was always temporary, and it is
**not adequate for live payments**: the tunnel died three times in two days, and a live payment whose webhook
never arrives cannot be recovered by the parent who made it.

This is the sequence for `bafisslunio.com`. It cannot be verified from a build machine — the host's Python
version, its database offering and whether SSH is enabled are all things only the cPanel account can answer.
Each step therefore says what to check.

---

## 0. Before anything: rotate the Chargily keys

The live secret key was pasted into a chat window. **Regenerate it in the Chargily dashboard
(«إعادة توليد») before the first real payment.** Anyone holding that string can create checkouts and refunds on
the account.

The new key goes **only** into the server's `.env`, by hand, over SSH or the cPanel file manager. Never into
git, never into a message, never into `.env.example` (Art. 7.7).

---

## 1. What the host has to provide

Check these in cPanel before starting, because two of them decide the shape of everything after:

| Need | Where to look | If it is missing |
|---|---|---|
| **Python 3.10+** | Software → *Setup Python App* | No Passenger, no Django. Ask the host. |
| **A database** | Databases → *Manage My Databases* | Answered: MySQL only. See §2 |
| **SSH access** | Advanced → *Terminal*, or SSH Access | Everything below is still possible through the file manager, slower |
| **SSL on the domain** | Already **Actif** on `bafisslunio.com` | The webhook must be `https://`, never `http://` |

## 2. The database: MySQL, and that is an amendment

**Settled on 2026-08-31 by looking at the account.** The Databases section offers phpMyAdmin, Manage My
Databases and a wizard — MySQL/MariaDB. There is no PostgreSQL on this plan.

Article 3 names PostgreSQL, so this is a **change to the agreed stack and needs the client's written
agreement** (decisions.md D-88). The code cost is genuinely small: Django's ORM covers it, no raw SQL exists
outside migrations, and the longest indexed column is 160 characters — comfortably under MySQL's legacy
767-byte index limit even at four bytes per character.

Two things had to change and are already in the repository:

* **PyMySQL** instead of `mysqlclient`. The latter is a C extension needing a compiler and MySQL headers,
  which shared hosting rarely provides. PyMySQL is pure Python; `config/__init__.py` registers it under the
  name Django expects.
* **utf8mb4 and STRICT_TRANS_TABLES.** MySQL's "utf8" is three bytes and silently truncates anything outside
  the basic plane. Strict mode makes a value that does not fit an error rather than a silent coercion — a
  ledger that rounds because a column was small is worse than an insert that fails (AD-4).

Do not run the acceptance on one engine and deliver on the other.

## 3. Create the Python application

cPanel → **Setup Python App** → Create Application.

| Field | Value |
|---|---|
| Python version | 3.10 or newer |
| Application root | `nojoumi` |
| Application URL | `bafisslunio.com` (or a subdomain such as `api.bafisslunio.com`) |
| Application startup file | `passenger_wsgi.py` |
| Application Entry point | `application` |

cPanel prints a line beginning `source /home/…/virtualenv/…/bin/activate`. **Copy it** — every command below
runs inside that environment.

## 4. Put the code on the server

```bash
cd ~/nojoumi
git clone https://github.com/Ilyes4CODE/nojoumi.git .
```

Only `server/` is needed on the host; the Flutter app and the Kotlin modules are built locally and shipped as
an APK. Cloning the whole repository is simpler than splitting it and costs a few megabytes.

## 5. `passenger_wsgi.py` — already in the repository

Passenger looks for it in the application root, one level above `server/`, which is exactly where the clone
puts it. Nothing to write.

It states `config.settings.prod` rather than defaulting to it: a host with `DJANGO_SETTINGS_MODULE` unset would
otherwise serve the site with `DEBUG=True`, which renders every key in `.env` to whoever triggers a 500.

## 6. Install and configure

```bash
source /home/<user>/virtualenv/nojoumi/3.10/bin/activate
cd ~/nojoumi/server
pip install -r requirements.txt
```

Then create `~/nojoumi/server/.env` — **by hand, on the server**:

```
DJANGO_SECRET_KEY=<a fresh 50-character random string, not the development one>
DJANGO_DEBUG=0
DJANGO_ALLOWED_HOSTS=bafisslunio.com,www.bafisslunio.com

DATABASE_URL=mysql://zebqkuzf_Ilyes:<password>@localhost:3306/zebqkuzf_db

LESSON_PROCESSOR=groq
GROQ_API_KEY=<key>
ANTHROPIC_API_KEY=<key, for the acceptance run — Art. 3 names Claude>

SUBSCRIPTION_SIGNING_KEY_HEX=<see below>

CHARGILY_LIVE_MODE=1
CHARGILY_BASE_URL=
CHARGILY_PUBLIC_KEY=<live public key>
CHARGILY_SECRET_KEY=<the REGENERATED live secret key>
CHARGILY_WEBHOOK_URL=https://bafisslunio.com/api/payments/webhook/chargily/
```

Three of those lines are traps worth naming:

* **`CHARGILY_BASE_URL` must stay empty.** Setting it overrides `CHARGILY_LIVE_MODE` completely, so the flag
  can read `1` while every request still goes to the sandbox. The key/mode guard in `chargily.py` refuses that
  combination now, but only because it reads the override too.
* **`DJANGO_DEBUG=0` is not optional.** With debug on, a 500 renders the settings — including every key on this
  page — to whoever triggered it.
* **`SUBSCRIPTION_SIGNING_KEY_HEX`**: keep the development key *only* if the installed app was built with the
  matching public key. Generating a new pair invalidates every subscription snapshot already on a phone. If you
  do generate one (`python manage.py generate_signing_key`), the public half must go into the app build as
  `LUNIO_SNAPSHOT_PUBLIC_KEY` and the APK must be reinstalled.

## 6b. The mailbox for password resets

The server sends exactly one kind of message: the six-digit password-reset code (D-92). It needs a real mailbox
on the site's own domain — not a Gmail address, not a personal one.

1. cPanel → **Email Accounts** → **Create**. Address `no-reply@bafisslunio.com`, a long password.
2. On the new account, **Connect Devices** → read the **Secure SSL/TLS Settings**. The outgoing server is
   normally `mail.bafisslunio.com` on port **465**.
3. Put the four values in `server/.env`:

```
EMAIL_HOST=mail.bafisslunio.com
EMAIL_PORT=465
EMAIL_HOST_USER=no-reply@bafisslunio.com
EMAIL_HOST_PASSWORD=the-password-you-just-set
EMAIL_USE_SSL=1
EMAIL_USE_TLS=0
DEFAULT_FROM_EMAIL=Lunio <no-reply@bafisslunio.com>
```

`EMAIL_USE_SSL` and `EMAIL_USE_TLS` are **not** both on. Port 465 is implicit TLS (`SSL=1`); port 587 is
STARTTLS (`SSL=0`, `TLS=1`). Django refuses to start with both, and `prod.py` says which one to turn off.

`DEFAULT_FROM_EMAIL` must be a mailbox on the same domain the site serves. SPF and DMARC are checked against
**that** domain, and a mismatch is the commonest reason a code lands in spam.

**The application will not start without these.** That is deliberate: a reset that silently goes nowhere looks
exactly like one that worked, and the parent is left refreshing an inbox and then calling you.

### Prove it before the client does

```bash
cd ~/nojoumi/server
python manage.py shell -c "
from django.core.mail import send_mail
from django.conf import settings
send_mail('Lunio test', 'test', settings.DEFAULT_FROM_EMAIL, ['your-own-address@gmail.com'])
print('sent')
"
```

Then send yourself a real one through the API and look at it in a phone mail client, not a webmail preview:

```bash
curl -s -X POST https://bafisslunio.com/api/accounts/password/reset/   -H 'Content-Type: application/json' -d '{"email":"an-account-you-own@example.com"}'
```

Check three things: it arrives, it is **not** in spam, and the illustrations are visible without pressing
"show images".

## 7. Migrate and collect

```bash
python manage.py migrate
python manage.py collectstatic --noinput
python manage.py createsuperuser
```

Then **Restart** the application from the Setup Python App page. Passenger caches aggressively; a code change
without a restart is a code change that did not happen.

### One thing this release does to signed-in parents

`accounts.0002` adds the reset-code table, and `SIMPLE_JWT["CHECK_REVOKE_TOKEN"]` starts binding a hash of the
password into every token. Tokens issued before this deploy carry no such hash and are refused, so **every
parent already signed in signs in once more**. Nothing is lost: stars, blocking and saved lessons are all on
the phone (Art. 7.1). Tell the client to expect it rather than let them report it.

## 8. Check it from outside, not from the server

```bash
curl -i https://bafisslunio.com/api/health/
curl -i https://bafisslunio.com/api/payments/webhook/chargily/
```

Expected: `200` on the first, **`405`** on the second. A 405 is the right answer — the endpoint exists and
refuses GET. A 404 means the URL never reached Django; a 500 means it did and something else is wrong.

## 9. Point the app at it

```powershell
flutter build apk --release `
  --dart-define=LUNIO_API_BASE=https://bafisslunio.com `
  --dart-define=LUNIO_SNAPSHOT_PUBLIC_KEY=<64 hex characters>
```

The payment page follows automatically: `AppConfig.payUrl` defaults to `/pay/` on the API origin.

## 10. Only now, live mode

With the server answering on HTTPS and the webhook reachable, `CHARGILY_LIVE_MODE=1` is safe to set.

**Make one real payment of the smallest amount and watch it end to end** — checkout, webhook received, code
issued, code redeemed in the app. Article 11.7 measures exactly this cycle, and doing it once with real money
before announcing anything is cheaper than discovering it with a customer.

---

## What live mode changes, beyond the endpoint

* **Refunds and chargebacks become real** and are outside the agreed scope (Art. 17). Decide with the client,
  in writing, who handles a parent who asks for their money back.
* **The acceptance run (Art. 11.7) is specified in test mode.** Switching to live before acceptance is the
  client's decision, not a technical one — say so before doing it.
* **The webhook must stay up.** Chargily retries, but not for ever. A server that is down for a day is a
  payment that has to be reconciled by hand.

---

# Updating an already-deployed server

Everything above is the first deployment. This is the short list for every release after it.

```bash
# 1. The virtualenv line cPanel prints on the Python App page.
source /home/<user>/virtualenv/nojoumi/3.10/bin/activate
cd ~/nojoumi/server

# 2. What is about to change.
git fetch origin
git log --oneline HEAD..origin/master
git diff --stat HEAD origin/master -- requirements.txt

# 3. Take it.
git pull origin master

# 4. Only if requirements.txt moved in step 2.
pip install -r requirements.txt

# 5. Only if migrations came with it.
python manage.py showmigrations --plan | grep "\[ \]"
python manage.py migrate

# 6. Only if anything under static/ moved.
python manage.py collectstatic --noinput

# 7. Restart. Passenger watches this file's timestamp.
touch ~/nojoumi/tmp/restart.txt
```

Then check from **outside** the server, never from a shell on it:

```bash
curl -s https://bafisslunio.com/api/health/
```

## The steps people skip, and what skipping them looks like

* **Not restarting.** `touch tmp/restart.txt` is the whole deployment as far as Passenger is concerned. Without
  it the old code keeps serving and the change appears not to have happened, which sends you looking in the
  wrong place for an hour.
* **`pip install` outside the virtualenv.** The packages land in the system Python, the app keeps using the old
  ones, and the error is a `ModuleNotFoundError` for something you just watched install successfully.
* **Editing `.env` and expecting it to take.** It is read at import time. Restart.
