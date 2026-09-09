#!/usr/bin/env python
"""Django management entry point.

### Why this is not a one-line file

It used to default to `config.settings.dev` unconditionally. On 2026-09-09 that
sent a production deployment's `migrate` into **SQLite on the server** — nineteen
migrations applied, every line reporting OK, and the MySQL database left empty.
Nothing failed. `check --database default` passed too, because SQLite always
connects.

The web application would then have booted through `passenger_wsgi.py`, which
*does* state production, found MySQL with no tables, and returned 500 to every
request — with the cause several steps behind and invisible.

So the settings module is **chosen from the environment that is actually
present**: a `.env` saying `DJANGO_DEBUG=0` is a production host, and there is no
sensible reading of `manage.py` on such a host that means "use the development
database". The choice is printed rather than made quietly, because a tool that
silently picks a database is how this went wrong in the first place.

An explicit `DJANGO_SETTINGS_MODULE` or `--settings=` always wins.
"""

import os
import pathlib
import sys


def _settings_from_environment() -> str:
    """`config.settings.prod` when a production `.env` is sitting next door."""
    env_file = pathlib.Path(__file__).resolve().parent / ".env"
    if not env_file.exists():
        return "config.settings.dev"

    for line in env_file.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line.startswith("DJANGO_DEBUG"):
            continue
        _, _, value = line.partition("=")
        if value.strip() == "0":
            return "config.settings.prod"
    return "config.settings.dev"


def main() -> None:
    chosen = os.environ.get("DJANGO_SETTINGS_MODULE") or _settings_from_environment()
    os.environ.setdefault("DJANGO_SETTINGS_MODULE", chosen)

    # Said out loud, and only for production: a developer running tests all day
    # does not need a banner, but anyone touching a live database does.
    if chosen.endswith(".prod") and "--settings" not in " ".join(sys.argv):
        print(f"[settings] {chosen}", file=sys.stderr)

    from django.core.management import execute_from_command_line

    execute_from_command_line(sys.argv)


if __name__ == "__main__":
    main()
