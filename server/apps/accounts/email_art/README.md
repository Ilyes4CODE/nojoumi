# email_art/

PNG copies of the drawings used in `templates/accounts/email/password_reset.html`.

**These are not app assets and not static files.** They are read off disk by
`mailer.py` and carried inside each message as `related` parts, so nothing here is
served over HTTP and nothing here is in the APK.

| File | Subject |
|---|---|
| `logo_mark.png` | the Lunio mark, 112 px square (drawn at 56) |
| `key_friendly.png` | a friendly violet key with a small smile and sparkles, 300 px square (drawn at 150) |
| `shield.png` | the violet shield with a check mark, 80 px square (drawn at 40) |

## Why PNG and why twice the drawn size

**PNG** because Outlook renders through Word and has no WebP decoder; a WebP
illustration is a broken-image icon there. The Article 13 budget that forces WebP
on the app does not apply — none of this ships to a phone.

**Twice** the pixel size the template draws at, because a phone mail client is a
2x or 3x display and a 150 px image drawn at 150 px is visibly soft on it.

## Missing files are fine

`mailer.py` skips any file that is not here and the template drops the matching
`<img>`. The message still reads correctly — which it has to anyway, because a
large share of clients block images regardless of what we attach.

All three are produced by `tools/convert_art.py`, which writes the app's WebP
and this folder's PNG from the same source drawing in `illustrators and logo/`:

```
python tools/convert_art.py key_friendly shield logo_mark
```

`key_friendly` is shared with the app's forgot-password screen, so the parent
who asks for a code in the app and then opens their inbox sees the same drawing
twice. That repetition is the cheapest thing we can do about a message which
otherwise has the shape of a phishing attempt.
