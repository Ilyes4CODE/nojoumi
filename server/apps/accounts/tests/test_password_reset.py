"""Password reset, from the mail that arrives to the session that ends.

Grouped by the thing that would go wrong rather than by endpoint, because the
interesting failures here cross endpoints: an attempt budget that can be widened
by switching views, a code that survives a second request, a reset that changes
the password and leaves the intruder signed in.
"""

from __future__ import annotations

import pathlib
import tempfile
from datetime import timedelta
from unittest import mock

from django.contrib.auth import get_user_model
from django.core import mail
from django.core.cache import cache
from django.test import TestCase
from django.urls import reverse
from django.utils import timezone
from rest_framework.test import APIClient

from apps.accounts import mailer, reset_codes
from apps.accounts.reset_codes import PasswordResetCode

ParentUser = get_user_model()

REQUEST = reverse("accounts:password-reset")
VERIFY = reverse("accounts:password-reset-verify")
CONFIRM = reverse("accounts:password-reset-confirm")
ME = reverse("accounts:me")
TOKEN = reverse("accounts:token")

GOOD = "n7-Sabah-Khayr-2026"
NEW = "K8-Masaa-Noor-2026"

#: Stands in for a checkout where the artwork has not been added yet.
NO_ART = pathlib.Path(tempfile.mkdtemp())


def code_from_outbox() -> str:
    """The six digits, read out of the message that was actually sent."""
    body = mail.outbox[-1].body
    digits = [word for word in body.split() if word.isdigit() and len(word) == 6]
    assert digits, f"no six-digit code in the message body:\n{body}"
    return digits[0]


class ResetBase(TestCase):
    def setUp(self):
        # Throttle counters live in the cache, which is a process-wide
        # dictionary here and survives between tests. Left alone, the first few
        # tests spend the hour's budget and everything after them sees 429.
        cache.clear()

        self.api = APIClient()
        self.parent = ParentUser.objects.create_user(email="wali@bayt.dz", password=GOOD)
        mail.outbox.clear()

    def ask(self, email: str | None = None):
        return self.api.post(
            REQUEST, {"email": email or self.parent.email}, format="json"
        )

    def verify(self, code: str, email: str | None = None):
        return self.api.post(
            VERIFY, {"email": email or self.parent.email, "code": code}, format="json"
        )


class RequestingACode(ResetBase):
    def test_a_code_is_mailed_and_stored_only_as_a_hash(self):
        self.assertEqual(self.ask().status_code, 200)
        self.assertEqual(len(mail.outbox), 1)

        code = code_from_outbox()
        row = PasswordResetCode.objects.get()

        # Six digits is a million possibilities, which is nothing to a laptop.
        # Anyone who reads this table must not come away holding live resets.
        self.assertNotIn(code, row.code_hash)
        self.assertTrue(row.code_hash.startswith("pbkdf2_"))

    def test_an_unknown_address_is_told_so(self):
        # The client's choice, 2026-09-25: a parent who mistyped their address
        # should learn it now, not after waiting for a message that never comes.
        # This test used to assert the opposite.
        unknown = self.api.post(REQUEST, {"email": "nobody@bayt.dz"}, format="json")

        self.assertEqual(unknown.status_code, 404)
        self.assertIn("لا يوجد حساب", unknown.json()["detail"])
        self.assertEqual(mail.outbox, [])

    def test_the_address_is_matched_however_it_was_typed(self):
        # Stored lowercased; a phone keyboard happily capitalises the first
        # letter. Matching as typed would answer "no account" to its owner.
        response = self.ask(email="  WALI@Bayt.DZ ")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(mail.outbox), 1)

    def test_asking_twice_in_a_minute_sends_one_message(self):
        # Otherwise anyone who knows an address can bury its owner's inbox, and
        # the owner cannot tell which of forty codes is the live one.
        self.ask()
        second = self.ask()

        self.assertEqual(second.status_code, 200)
        self.assertEqual(len(mail.outbox), 1)
        # And it says the first code still stands, rather than implying a second
        # one is on its way.
        self.assertIn("ما زال صالحاً", second.json()["detail"])

    def test_a_second_code_retires_the_first(self):
        self.ask()
        first = code_from_outbox()

        PasswordResetCode.objects.update(
            created_at=timezone.now() - timedelta(minutes=5)
        )
        self.ask()
        second = code_from_outbox()
        self.assertNotEqual(first, second)

        self.assertEqual(self.verify(first).status_code, 400)
        self.assertEqual(self.verify(second).status_code, 200)

    def test_a_mail_server_failure_is_told_to_the_parent(self):
        # This used to be swallowed so that a failure would not reveal a real
        # address. Once the endpoint says openly whether an address exists,
        # silence protects nothing — and it cost a day: a mailbox the shell could
        # reach and the web process could not looked exactly like one that
        # worked.
        with self.assertLogs("apps.accounts.reset_views", level="ERROR") as logged:
            with mock.patch.object(
                mailer.EmailMultiAlternatives, "send", side_effect=OSError("smtp down")
            ):
                response = self.ask()

        self.assertEqual(response.status_code, 503)
        self.assertIn("تعذّر إرسال البريد", response.json()["detail"])
        self.assertIn("could not send", " ".join(logged.output))

    def test_a_code_that_was_never_delivered_is_not_left_valid(self):
        # The parent never received it. A live code nobody has is only an open
        # door — and leaving it would also trip the cooldown, so their retry a
        # minute later would be told "we sent you one" when we had not.
        with mock.patch.object(
            mailer.EmailMultiAlternatives, "send", side_effect=OSError("smtp down")
        ):
            with self.assertLogs("apps.accounts.reset_views", level="ERROR"):
                self.ask()

        self.assertFalse(
            PasswordResetCode.objects.filter(used_at__isnull=True).exists()
        )
        # So the retry goes out immediately rather than waiting out a cooldown
        # for a message that never left.
        self.assertEqual(self.ask().status_code, 200)
        self.assertEqual(len(mail.outbox), 1)

class GuessingACode(ResetBase):
    def setUp(self):
        super().setUp()
        self.ask()
        self.code = code_from_outbox()
        # One in a million, and it would flake exactly once in someone's CI.
        self.miss = "000000" if self.code != "000000" else "111111"

    def test_five_wrong_guesses_kill_the_code(self):
        for _ in range(reset_codes.ATTEMPTS):
            self.assertEqual(self.verify(self.miss).status_code, 400)

        self.assertEqual(self.verify(self.code).status_code, 400)

    def test_the_budget_cannot_be_widened_by_switching_endpoints(self):
        # The reason verify and confirm spend from one row rather than each
        # holding a counter: three guesses here and three there would be six.
        for _ in range(3):
            self.verify(self.miss)
        for _ in range(2):
            self.api.post(
                CONFIRM,
                {"email": self.parent.email, "code": self.miss, "password": NEW},
                format="json",
            )

        right = self.api.post(
            CONFIRM,
            {"email": self.parent.email, "code": self.code, "password": NEW},
            format="json",
        )
        self.assertEqual(right.status_code, 400)
        self.parent.refresh_from_db()
        self.assertTrue(self.parent.check_password(GOOD))

    def test_an_expired_code_is_refused(self):
        PasswordResetCode.objects.update(
            expires_at=timezone.now() - timedelta(seconds=1)
        )
        self.assertEqual(self.verify(self.code).status_code, 400)

    def test_wrong_expired_and_unknown_all_say_the_same_sentence(self):
        wrong = self.verify(self.miss).json()["detail"]

        PasswordResetCode.objects.update(
            expires_at=timezone.now() - timedelta(seconds=1)
        )
        expired = self.verify(self.code).json()["detail"]
        unknown = self.verify(self.code, email="nobody@bayt.dz").json()["detail"]

        self.assertEqual(wrong, expired)
        self.assertEqual(expired, unknown)


class SettingTheNewPassword(ResetBase):
    def setUp(self):
        super().setUp()
        self.ask()
        self.code = code_from_outbox()

    def confirm(self, password=NEW, code=None):
        return self.api.post(
            CONFIRM,
            {
                "email": self.parent.email,
                "code": code or self.code,
                "password": password,
            },
            format="json",
        )

    def test_the_password_changes_and_the_old_one_stops_working(self):
        self.assertEqual(self.confirm().status_code, 200)

        self.parent.refresh_from_db()
        self.assertTrue(self.parent.check_password(NEW))
        self.assertFalse(self.parent.check_password(GOOD))

    def test_a_code_cannot_be_used_twice(self):
        self.confirm()
        again = self.confirm(password="Third-Passphrase-2026")

        self.assertEqual(again.status_code, 400)
        self.parent.refresh_from_db()
        self.assertTrue(self.parent.check_password(NEW))

    def test_a_weak_password_is_refused_without_spending_an_attempt(self):
        response = self.confirm(password="123456")
        self.assertEqual(response.status_code, 400)

        self.assertEqual(PasswordResetCode.objects.get().attempts, 0)
        self.assertEqual(self.confirm().status_code, 200)

    def test_the_new_password_signs_in(self):
        self.confirm()
        response = self.api.post(
            TOKEN, {"email": self.parent.email, "password": NEW}, format="json"
        )
        self.assertEqual(response.status_code, 200)
        self.assertIn("access", response.json())


class EndingTheOtherSessions(ResetBase):
    """A reset that leaves the intruder signed in has done nothing.

    This is what `SIMPLE_JWT["CHECK_REVOKE_TOKEN"]` is in the settings for, and
    that setting is one line nothing else would notice going missing.
    """

    def signed_in(self) -> dict:
        return self.api.post(
            TOKEN, {"email": self.parent.email, "password": GOOD}, format="json"
        ).json()

    def reset_from_another_device(self):
        other = APIClient()
        other.post(REQUEST, {"email": self.parent.email}, format="json")
        other.post(
            CONFIRM,
            {"email": self.parent.email, "code": code_from_outbox(), "password": NEW},
            format="json",
        )

    def test_a_token_issued_before_the_reset_stops_working(self):
        tokens = self.signed_in()
        self.api.credentials(HTTP_AUTHORIZATION=f"Bearer {tokens['access']}")
        self.assertEqual(self.api.get(ME).status_code, 200)

        self.reset_from_another_device()

        self.assertEqual(self.api.get(ME).status_code, 401)

    def test_refreshing_an_old_token_does_not_get_around_it(self):
        tokens = self.signed_in()
        self.reset_from_another_device()

        renewed = self.api.post(
            reverse("accounts:token-refresh"),
            {"refresh": tokens["refresh"]},
            format="json",
        )

        # The refresh endpoint never looks the parent up, so it may well answer
        # 200 — with a token carrying the *old* password hash, copied from the
        # refresh token. The refusal happens where the token is used, which is
        # the place that decides anything.
        if renewed.status_code == 200:
            self.api.credentials(
                HTTP_AUTHORIZATION=f"Bearer {renewed.json()['access']}"
            )
            self.assertEqual(self.api.get(ME).status_code, 401)


class TheMessageItself(ResetBase):
    def test_it_carries_a_text_part_and_an_html_part(self):
        self.ask()
        message = mail.outbox[0]

        self.assertTrue(
            message.body.strip(),
            "a message with no text part scores badly with spam filters",
        )
        html = [body for body, kind in message.alternatives if kind == "text/html"]
        self.assertEqual(len(html), 1)
        self.assertIn(code_from_outbox(), html[0])

    def test_the_code_is_in_the_subject_so_the_inbox_list_shows_it(self):
        self.ask()
        self.assertIn(code_from_outbox(), mail.outbox[0].subject)

    def test_the_illustrations_are_attached_inline_rather_than_linked(self):
        self.ask()
        message = mail.outbox[0]
        html = message.alternatives[0][0]

        # A remote <img> is blocked by default in Outlook and proxied by Gmail,
        # so it arrives as a broken box on the one message a parent is already
        # unsure about. Everything visual must travel inside the message.
        self.assertNotIn("http://", html)
        self.assertNotIn("https://", html)
        self.assertEqual(message.mixed_subtype, "related")

        ids, files = mailer._art()
        self.assertEqual(len(message.attachments), len(files))
        for cid in ids.values():
            self.assertIn(f"cid:{cid}", html)

    def test_it_reads_correctly_with_every_illustration_missing(self):
        # Which is also what an image-blocking client shows, so the degraded
        # case is the common one rather than a rare one worth tolerating.
        with mock.patch.object(mailer, "ART_DIR", NO_ART):
            self.ask()

        message = mail.outbox[0]
        html = message.alternatives[0][0]

        self.assertEqual(message.attachments, [])
        self.assertNotIn("cid:", html)
        self.assertIn(code_from_outbox(), html)
        self.assertIn("نسيت كلمة المرور", html)

class ItSurvivesAMailClient(ResetBase):
    """Three things Gmail broke, each invisible to every other test here.

    A template renders perfectly in a browser and still arrives wrong, because a
    mail client is not a browser. These pin the specific repairs made on
    2026-09-20 after looking at the message in Gmail.
    """

    def setUp(self):
        super().setUp()
        self.ask()
        self.html = mail.outbox[0].alternatives[0][0]

    def test_the_direction_is_declared_where_gmail_can_see_it(self):
        # Gmail keeps the contents of <body> and throws the rest of the document
        # away, so `dir` on <html> never reaches the text. Counted rather than
        # merely found: one occurrence would mean only the <html> tag has it.
        self.assertGreater(
            self.html.count('dir="rtl"'),
            6,
            "Arabic needs its direction on the tables and cells themselves, not "
            "only on <html>, which Gmail discards",
        )

    def test_backgrounds_are_written_as_attributes_too(self):
        # `background:` is stripped where `bgcolor` is honoured. Without this the
        # page tint and the band behind the illustration both vanish and the
        # message is white on white.
        for colour in ("#F8F7FC", "#FFFFFF", "#EDE8FC"):
            self.assertIn(
                f'bgcolor="{colour}"',
                self.html,
                f"{colour} will not survive Gmail as CSS alone",
            )

    def test_the_font_stack_names_fonts_that_exist_on_a_reader_machine(self):
        # Tajawal is bundled in the APK. A mail client cannot reach it, and a
        # webfont cannot be loaded because Gmail drops <link> and @import, so
        # naming it here only means "pick something, I do not mind".
        self.assertNotIn("Tajawal", self.html)
        self.assertIn("Tahoma", self.html)


class TheLookupStaysFast(ResetBase):
    """The address lookup is one index jump, and stays one.

    `email__iexact` planned as `SCAN TABLE` — every row read on every reset,
    getting slower with each parent the client signs up. Addresses are stored
    lowercased, so an exact match on the lowercased input reaches the unique
    index directly. This pins the plan, so a well-meant return to `iexact`
    fails here rather than degrading quietly as the account list grows.
    """

    def test_the_reset_lookup_uses_the_email_index(self):
        from apps.accounts.models import normalised_email

        plan = ParentUser.objects.filter(
            email=normalised_email("Wali@Bayt.DZ"), is_active=True
        ).explain()

        self.assertIn("USING INDEX", plan)
        self.assertNotIn("SCAN TABLE", plan)

    def test_sign_in_uses_the_same_index(self):
        # Sign-in goes through `get_by_natural_key`, and before 2026-09-25 it
        # compared the address as typed, which also bypassed the lowercase the
        # storage relied on.
        from apps.accounts.models import normalised_email

        plan = ParentUser.objects.filter(email=normalised_email("WALI@bayt.dz")).explain()
        self.assertIn("USING INDEX", plan)


class TheAddressCaseCannotLockAParentOut(ResetBase):
    def test_a_parent_can_reset_and_then_sign_in_with_the_same_capitalised_address(self):
        # The bug this pins: the reset path lowercased and sign-in did not, so a
        # parent typing `Wali@...` reset successfully and was then told their
        # brand-new password was wrong.
        typed = "  Wali@Bayt.DZ "

        self.assertEqual(self.ask(email=typed).status_code, 200)
        confirmed = self.api.post(
            CONFIRM,
            {"email": typed, "code": code_from_outbox(), "password": NEW},
            format="json",
        )
        self.assertEqual(confirmed.status_code, 200)

        signed_in = self.api.post(
            TOKEN, {"email": typed, "password": NEW}, format="json"
        )
        self.assertEqual(signed_in.status_code, 200, signed_in.json())
