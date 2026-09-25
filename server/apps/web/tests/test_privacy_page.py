"""The privacy policy, and the one way it can quietly become false.

Google Play requires a policy at a public URL, and this app is in the category
that gets read rather than skimmed: it binds an AccessibilityService, it draws
over other apps, and children use it. A reviewer opens the page and compares it
against the manifest.

So the interesting test here is not "does the page load". It is **does the page
still describe every permission the app asks for** — because the way this goes
wrong is not someone editing the policy, it is someone adding a permission and
never thinking about the policy at all. Six months later Play rejects an update
and nobody can see why.

## What this cannot see

It reads the manifests in the repository. It cannot see permissions contributed
by a Flutter plugin's own manifest, which are merged in at build time —
`VIBRATE` arrives that way today. So a green run here means "nothing we wrote is
undocumented", not "the APK asks for nothing else".

The complete list comes from the built artefact:

    aapt2 dump permissions build/app/outputs/flutter-apk/app-release.apk

and that is worth running before every Play submission. It is not automated here
because a server test suite that needs a compiled APK on disk is a suite that
fails for the wrong reason on every clean checkout.
"""

from __future__ import annotations

import pathlib
import re

from django.test import SimpleTestCase
from django.urls import reverse

REPO = pathlib.Path(__file__).resolve().parents[4]
MANIFESTS = (
    REPO / "app" / "android" / "app" / "src" / "main" / "AndroidManifest.xml",
    REPO / "native" / "blocking" / "src" / "main" / "AndroidManifest.xml",
)

#: Permission → a phrase the policy must contain if the app asks for it.
#:
#: The phrase is what a parent would recognise, not the constant: a policy that
#: lists `SYSTEM_ALERT_WINDOW` has disclosed nothing to the person reading it.
EXPLAINED_BY = {
    "INTERNET": "الإنترنت",
    "SYSTEM_ALERT_WINDOW": "الرسم فوق التطبيقات",
    "FOREGROUND_SERVICE": "خدمة تعمل في المقدّمة",
    "FOREGROUND_SERVICE_SPECIAL_USE": "خدمة تعمل في المقدّمة",
    "RECEIVE_BOOT_COMPLETED": "التشغيل عند الإقلاع",
    "REQUEST_IGNORE_BATTERY_OPTIMIZATIONS": "تحسين البطارية",
    "POST_NOTIFICATIONS": "الإشعارات",
    "VIBRATE": "الاهتزاز",
    # Not a permission the app requests but one the system grants to the
    # service, and the single most scrutinised thing about this app.
    "BIND_ACCESSIBILITY_SERVICE": "خدمة إمكانية الوصول",
}


def declared_permissions() -> set[str]:
    found: set[str] = set()
    for manifest in MANIFESTS:
        if not manifest.is_file():
            continue
        found.update(
            re.findall(r"android\.permission\.([A-Z_]+)", manifest.read_text("utf-8"))
        )
    return found


class ThePolicyIsReachable(SimpleTestCase):
    def test_it_loads_without_an_account(self):
        # A policy behind a login is not a policy. A reviewer opens it cold, and
        # so does a parent who has not installed anything yet.
        response = self.client.get(reverse("privacy"))
        self.assertEqual(response.status_code, 200)

    def test_it_is_in_arabic_and_right_to_left(self):
        page = self.client.get(reverse("privacy")).content.decode()
        self.assertIn('dir="rtl"', page)
        self.assertIn("سياسة", page)

    def test_it_carries_an_english_translation(self):
        # Two audiences who do not overlap: the parents who use the app, and the
        # reviewer deciding whether it ships.
        page = self.client.get(reverse("privacy")).content.decode()
        self.assertIn("Privacy Policy (English)", page)
        self.assertIn("Accessibility Service", page)


class ThePolicyMatchesTheManifest(SimpleTestCase):
    def setUp(self):
        self.page = self.client.get(reverse("privacy")).content.decode()

    def test_every_permission_we_declare_is_explained(self):
        missing = []
        for permission in sorted(declared_permissions()):
            phrase = EXPLAINED_BY.get(permission)
            if phrase is None:
                missing.append(f"{permission} — no entry in EXPLAINED_BY")
            elif phrase not in self.page:
                missing.append(f"{permission} — policy never says «{phrase}»")

        self.assertEqual(
            missing,
            [],
            "the manifest asks for something the privacy policy does not "
            "mention. Play compares the two, and the rejection arrives months "
            "later on an unrelated update:\n  " + "\n  ".join(missing),
        )

    def test_the_accessibility_service_says_what_it_does_not_do(self):
        # The disclosure Play actually reads. "We use accessibility to provide
        # features" is the sentence that gets an app removed; naming the limits
        # is what gets it through.
        for claim in ("لا تقرأ محتوى الشاشة", "ولا كلمات المرور"):
            self.assertIn(claim, self.page)

    def test_it_states_that_the_server_holds_nothing_about_the_child(self):
        # Article 14 and AD-6. It is also the most reassuring true sentence we
        # have, and burying it would be a waste.
        self.assertIn("لا يُنشأ لطفلك أي حساب", self.page)
        self.assertIn("تُحذف من الخادم فورًا", self.page)

    def test_it_promises_no_advertising_and_no_tracking(self):
        self.assertIn("لا يوجد في التطبيق أي إعلان", self.page)

    def test_it_gives_a_route_to_deletion(self):
        # Required by Play's data-deletion policy, and it has to be an address a
        # person can actually write to.
        self.assertIn("no-reply@bafisslunio.com", self.page)
