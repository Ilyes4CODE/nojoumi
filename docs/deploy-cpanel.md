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
| **PostgreSQL** | Databases → *PostgreSQL Databases* | See §2 — this is a stack decision, not a workaround |
| **SSH access** | Advanced → *Terminal*, or SSH Access | Everything below is still possible through the file manager, slower |
| **SSL on the domain** | Already **Actif** on `bafisslunio.com` | The webhook must be `https://`, never `http://` |

## 2. The database question, honestly

The fixed stack names **PostgreSQL**. Most shared cPanel plans offer **MySQL/MariaDB only**.

If PostgreSQL is not in the Databases section, there are two honest options and no third:

* **Ask the host to enable PostgreSQL.** Some plans have it and simply do not show it.
* **Move to MySQL**, which is a change to the agreed stack and needs the client's written agreement. The code
  cost is small — Django abstracts it and no raw SQL is used outside two migrations — but it is not a decision
  to take quietly.

Do not run the acceptance on one engine and deliver on the other.

---

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

DATABASE_URL=postgres://<user>:<password>@localhost:5432/<database>

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

## 7. Migrate and collect

```bash
python manage.py migrate
python manage.py collectstatic --noinput
python manage.py createsuperuser
```

Then **Restart** the application from the Setup Python App page. Passenger caches aggressively; a code change
without a restart is a code change that did not happen.

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
