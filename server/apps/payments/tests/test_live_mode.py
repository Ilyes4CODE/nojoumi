"""A key on the wrong endpoint is refused before any payment is attempted.

`base_url`'s docstring has always promised this — "a key that looks like a test
key on a live endpoint, or the reverse, should fail at configuration time and not
at the first real payment". Nothing enforced it until the switch to live mode was
actually about to happen.

**The two mistakes are not symmetrical, and both are silent.**

* A **live key on the test endpoint** charges nobody while looking like a working
  system. It is discovered by a parent whose payment never arrives.
* A **test key on the live endpoint** fails every payment, on the day the client
  announces the app.

Neither shows up in a test suite, a deploy log, or a browser. They show up when a
real person is holding a phone, which is why the check belongs at configuration
time.
"""

from __future__ import annotations

from django.test import SimpleTestCase, override_settings

from apps.payments import chargily

LIVE = "live_sk_" + "x" * 32
TEST = "test_sk_" + "x" * 32


class TheKeyMustMatchTheEndpoint(SimpleTestCase):
    @override_settings(
        CHARGILY_SECRET_KEY=LIVE, CHARGILY_LIVE_MODE=True, CHARGILY_BASE_URL=""
    )
    def test_a_live_key_in_live_mode_is_accepted(self):
        self.assertEqual(chargily._secret_key(), LIVE)

    @override_settings(
        CHARGILY_SECRET_KEY=TEST, CHARGILY_LIVE_MODE=False, CHARGILY_BASE_URL=""
    )
    def test_a_test_key_in_test_mode_is_accepted(self):
        self.assertEqual(chargily._secret_key(), TEST)

    @override_settings(
        CHARGILY_SECRET_KEY=TEST, CHARGILY_LIVE_MODE=True, CHARGILY_BASE_URL=""
    )
    def test_a_test_key_in_live_mode_is_refused(self):
        with self.assertRaises(chargily.ChargilyNotConfigured) as caught:
            chargily._secret_key()
        self.assertIn("test key", str(caught.exception))

    @override_settings(
        CHARGILY_SECRET_KEY=LIVE, CHARGILY_LIVE_MODE=False, CHARGILY_BASE_URL=""
    )
    def test_a_live_key_in_test_mode_is_refused(self):
        with self.assertRaises(chargily.ChargilyNotConfigured) as caught:
            chargily._secret_key()
        self.assertIn("CHARGILY_LIVE_MODE=1", str(caught.exception))


class TheBaseUrlOverrideCountsAsTheMode(SimpleTestCase):
    """Setting `CHARGILY_BASE_URL` bypasses the mode flag entirely.

    So the flag can read `1` while every request still goes to the sandbox — a
    configuration that looks live in `.env` and is not. The guard reads the
    override rather than the flag when one is present.
    """

    @override_settings(
        CHARGILY_SECRET_KEY=LIVE,
        CHARGILY_LIVE_MODE=True,
        CHARGILY_BASE_URL=chargily.TEST_BASE_URL,
    )
    def test_a_live_key_pointed_at_the_sandbox_is_refused(self):
        with self.assertRaises(chargily.ChargilyNotConfigured):
            chargily._secret_key()

    @override_settings(
        CHARGILY_SECRET_KEY=LIVE,
        CHARGILY_LIVE_MODE=False,
        CHARGILY_BASE_URL=chargily.LIVE_BASE_URL,
    )
    def test_a_live_key_pointed_at_live_is_accepted_whatever_the_flag_says(self):
        self.assertEqual(chargily._secret_key(), LIVE)

    @override_settings(
        CHARGILY_SECRET_KEY="", CHARGILY_LIVE_MODE=True, CHARGILY_BASE_URL=""
    )
    def test_an_empty_key_still_reports_the_empty_key(self):
        # The older, more common mistake must not be masked by the new one.
        with self.assertRaises(chargily.ChargilyNotConfigured) as caught:
            chargily._secret_key()
        self.assertIn("empty", str(caught.exception))
