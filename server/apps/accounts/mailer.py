"""Sending the reset email, with its illustrations attached rather than linked.

**Attached, not linked.** Outlook blocks remote images by default, Gmail proxies
them, and Apple Mail's privacy relay fetches them from somewhere else entirely. A
message whose artwork lives at a URL therefore arrives looking broken for a large
share of the people it is sent to — and this is the one message where looking
broken matters, because a parent who has just asked for a password reset is
primed to wonder whether the mail is a phishing attempt. So each drawing is
carried in the message as a `related` part and referenced by `cid:`.

**PNG, not WebP.** The app ships WebP to meet the Article 13 size budget on a
2 GB phone. Outlook has no WebP decoder at all, and the budget does not apply
here — nothing in this folder is in the APK. The email keeps its own copies.

**The message must be good with every image gone.** Missing art is not an error:
`art()` returns only the files that exist, the template's `{% if %}` blocks drop
out, and what remains is type, colour and the code itself. That is also exactly
what an image-blocking client shows, so the degraded case is not a rare one worth
tolerating — it is the common one, and it has to be designed.
"""

from __future__ import annotations

import logging
import mimetypes
from email.mime.image import MIMEImage
from pathlib import Path

from django.conf import settings
from django.core.mail import EmailMultiAlternatives
from django.template.loader import render_to_string

from . import reset_codes

log = logging.getLogger(__name__)

ART_DIR = Path(__file__).resolve().parent / "email_art"

#: Template variable → filename. See `email_art/README.md` for the subjects.
ART = {
    "logo": "logo_mark.png",
    "hero": "key_friendly.png",
    "shield": "shield.png",
}


def _art() -> tuple[dict[str, str], list[tuple[str, Path]]]:
    """The content ids the template can use, and the files behind them.

    A content id has to be unique within the message and is what `cid:` resolves
    against. Deriving it from the filename keeps the two ends readable when
    somebody views the raw source of a message that did not render.
    """
    ids: dict[str, str] = {}
    files: list[tuple[str, Path]] = []

    for key, name in ART.items():
        path = ART_DIR / name
        if not path.is_file():
            continue
        cid = f"lunio-{key}"
        ids[key] = cid
        files.append((cid, path))

    return ids, files


def send_reset_code(parent, code: str) -> None:
    """Mail `code` to `parent`.

    Raises whatever the mail backend raises. The caller decides what a failure
    means — and for the reset endpoint it must **not** mean an error the caller
    can see, because a 500 for one address and a 200 for another is an account
    enumeration oracle wearing a different hat.
    """
    ids, files = _art()
    context = {
        "code": code,
        "email": parent.email,
        "minutes": int(reset_codes.LIFETIME.total_seconds() // 60),
        "art": ids,
    }

    message = EmailMultiAlternatives(
        subject=f"رمز استعادة كلمة المرور: {code}",
        body=render_to_string("accounts/email/password_reset.txt", context),
        from_email=settings.DEFAULT_FROM_EMAIL,
        to=[parent.email],
    )
    message.attach_alternative(
        render_to_string("accounts/email/password_reset.html", context), "text/html"
    )

    # `related` is what tells a client that these parts belong to the HTML rather
    # than being files the reader should see listed as attachments. Left as
    # `mixed`, the illustrations show up as three downloads on a message that
    # already looks suspicious.
    message.mixed_subtype = "related"

    for cid, path in files:
        subtype = (mimetypes.guess_type(path.name)[0] or "image/png").split("/")[1]
        image = MIMEImage(path.read_bytes(), _subtype=subtype)
        image.add_header("Content-ID", f"<{cid}>")
        # Without this some clients list the part as an attachment anyway, even
        # under `related`.
        image.add_header("Content-Disposition", "inline", filename=path.name)
        message.attach(image)

    message.send(fail_silently=False)
    log.info("password reset code sent to parent %s", parent.pk)


def send_device_silent(parent, *, last_heard) -> None:
    """Tell `parent` that Lunio has gone quiet on a phone they are bound to.

    Raises whatever the backend raises. Unlike the reset code there is nothing
    to hide here — the caller is a cron job, not an HTTP client — so a failure
    is left to propagate and the job does not mark the device as reported,
    which means it tries again an hour later instead of giving up in silence.
    """
    from django.utils import formats, timezone

    ids, files = _art()
    local = timezone.localtime(last_heard)
    context = {
        "email": parent.email,
        "since": formats.date_format(local, "DATETIME_FORMAT"),
        "art": ids,
    }

    message = EmailMultiAlternatives(
        subject="Lunio لم يعد يتواصل من هاتف طفلك",
        body=render_to_string("accounts/email/device_silent.txt", context),
        from_email=settings.DEFAULT_FROM_EMAIL,
        to=[parent.email],
    )
    message.attach_alternative(
        render_to_string("accounts/email/device_silent.html", context), "text/html"
    )
    message.mixed_subtype = "related"
    for cid, path in files:
        if cid != "lunio-logo":
            # Only the mark. The key and the shield belong to the password reset,
            # and a lock drawn on a "your child may have deleted the app" message
            # reads as an accusation.
            continue
        image = MIMEImage(path.read_bytes(), _subtype="png")
        image.add_header("Content-ID", f"<{cid}>")
        image.add_header("Content-Disposition", "inline", filename=path.name)
        message.attach(image)

    message.send(fail_silently=False)
    log.info("device-silent alert sent to parent %s", parent.pk)
