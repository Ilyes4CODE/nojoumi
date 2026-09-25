"""Give every existing device a row in the new join table.

Without this, a phone bound under the old one-account rule counts **zero**
accounts in `InstallAccount`, so `bind()` would happily add three more on top of
the one already in `Install.parent` — four accounts on a phone whose limit is
three.

Reversible on purpose: the reverse drops only the rows this created, so rolling
back to 0002 leaves a device's later sign-ins alone.
"""

from __future__ import annotations

from django.db import migrations


def backfill(apps, schema_editor):
    Install = apps.get_model("devices", "Install")
    InstallAccount = apps.get_model("devices", "InstallAccount")

    rows = [
        InstallAccount(install_id=install.id, parent_id=install.parent_id)
        for install in Install.objects.filter(parent_id__isnull=False).iterator()
    ]
    # ignore_conflicts, because a device whose owner has already signed in since
    # 0002 landed has the row and must not make the deploy fail.
    InstallAccount.objects.bulk_create(rows, ignore_conflicts=True, batch_size=500)


def unbackfill(apps, schema_editor):
    Install = apps.get_model("devices", "Install")
    InstallAccount = apps.get_model("devices", "InstallAccount")

    for install in Install.objects.filter(parent_id__isnull=False).iterator():
        InstallAccount.objects.filter(
            install_id=install.id, parent_id=install.parent_id
        ).delete()


class Migration(migrations.Migration):
    dependencies = [("devices", "0002_installaccount_and_more")]

    operations = [migrations.RunPython(backfill, unbackfill)]
