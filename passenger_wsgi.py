"""Passenger entry point for the cPanel host.

cPanel's "Setup Python App" runs Passenger, which looks for this file in the
application root and imports `application` from it. The Django project lives one
directory down in `server/`, so the only work here is putting that on the path.

**The settings module is not defaulted to development.** `setdefault` would mean
a host that happens to have `DJANGO_SETTINGS_MODULE` unset serves the site with
`DEBUG=True` — which renders every key in `.env` into the browser of whoever
triggers a 500. Production is stated, and `config.settings.prod` refuses to start
if the environment is incomplete.

See `docs/deploy-cpanel.md`.
"""

import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "server"))

os.environ["DJANGO_SETTINGS_MODULE"] = "config.settings.prod"

from django.core.wsgi import get_wsgi_application  # noqa: E402

application = get_wsgi_application()
