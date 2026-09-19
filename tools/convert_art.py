"""Turn a delivered illustration into the files the app and the email ship.

Run it from the repository root:

    python tools/convert_art.py key_friendly mail_sent
    python tools/convert_art.py --all

Sources are the generator's PNGs in `illustrators and logo/`. Outputs are
`app/assets/illustrations/<name>.webp` and, for anything in [EMAIL], a PNG copy
in `server/apps/accounts/email_art/`.

`assets/README.md` has described this pipeline since the first batch, but the
script itself lived in a scratchpad and was thrown away with it. Committed now,
because a documented process nobody can run is a process that drifts.

## What it does, and the one thing it deliberately does not

1. **Despeckle.** Any pixel under alpha 16 is forced to zero. Several delivered
   files carry faint coloured dust in the fully transparent area — magenta
   specks inside the padlock's shackle, white specks around the shield. Left
   alone it survives the resize as visible grit. At alpha 16 over the app's
   canvas the change is under 6% of one channel, so nothing visible is lost.

2. **Trim to content, then pad back to square.** The first batch arrived using
   about 60% of its box; trimming and re-squaring makes a drawing fill the frame
   the widget gives it at the same file size.

3. **Resize** to the density the app draws at — three times the dp size, for a
   3x phone.

4. **Encode.** WebP quality 88 for the app, stepping down only if a file misses
   the Article 13 budget of 150 KB. PNG for the email, because Outlook renders
   through Word and has no WebP decoder.

**It does not try to remove the soft halo** some drawings carry — a pale fog
extending well past the silhouette, which looks alarming in an image viewer
against black. That was tried on 2026-09-20 with a dilate-and-cut: keep partial
alpha only within a few pixels of solid pixels, zero it elsewhere. The result
was **worse**, and visibly so at 1:1 — the cut passes through the middle of the
soft matte and leaves a hard white rim around every shape, where before there
was a gradient nobody could see.

The reason nobody could see it: these drawings only ever sit on `#F8F7FC` (the
app canvas) or `#EDE8FC` (the email's band). A pale fog on a pale background is
not a defect, it is stationery. Judge artwork composited on the colour it will
actually sit on, never on the checkerboard.
"""

from __future__ import annotations

import argparse
import pathlib
import sys

from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parent.parent
SOURCE = ROOT / "illustrators and logo"
APP = ROOT / "app" / "assets" / "illustrations"
EMAIL_ART = ROOT / "server" / "apps" / "accounts" / "email_art"

#: Article 13. The reference device is a 2 GB Android 10 phone.
BUDGET_BYTES = 150 * 1024

#: alpha below this is dust, not drawing.
DUST = 16

#: name → the pixel size the app ships, which is 3x the dp the widget draws at.
APP_SIZE = {
    "lock_friendly": 384,
    "star_big": 288,
    "backpack": 384,
    "astronaut": 384,
    "shield": 288,
    "rocket": 900,
    "starfield": 600,
    "key_friendly": 384,
    "mail_sent": 384,
}

#: name → the pixel size the reset email ships, which is 2x the size the
#: template draws at. Phone mail clients are 2x displays and a 1:1 image is
#: visibly soft on them.
EMAIL = {
    "key_friendly": 300,
    "shield": 80,
    "logo_mark": 112,
}

DEFAULT_APP_SIZE = 384


def squared(image: Image.Image) -> Image.Image:
    """Despeckled, trimmed to its content, and padded back to a square."""
    image = image.convert("RGBA")

    alpha = image.getchannel("A").point(lambda v: v if v >= DUST else 0)
    image.putalpha(alpha)

    box = alpha.getbbox()
    if box is not None:
        image = image.crop(box)

    side = max(image.size)
    canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    canvas.paste(
        image,
        ((side - image.width) // 2, (side - image.height) // 2),
    )
    return canvas


def resized(image: Image.Image, size: int) -> Image.Image:
    return image.resize((size, size), Image.LANCZOS)


def write_webp(image: Image.Image, path: pathlib.Path) -> int:
    """Quality 88, stepping down only if the file misses the budget."""
    for quality in (88, 80, 72, 65):
        image.save(path, "WEBP", quality=quality, method=6)
        written = path.stat().st_size
        if written <= BUDGET_BYTES:
            if quality != 88:
                print(f"    (quality {quality} to meet the budget)")
            return written
    return path.stat().st_size


def convert(name: str) -> None:
    source = SOURCE / f"{name}.png"
    if not source.is_file():
        print(f"!! {name}: no {source.name} in {SOURCE.name}/")
        return

    original = Image.open(source)
    print(f"{name}: {original.size[0]}x{original.size[1]}, "
          f"{source.stat().st_size // 1024} KB")

    base = squared(original)

    APP.mkdir(parents=True, exist_ok=True)
    app_path = APP / f"{name}.webp"
    written = write_webp(resized(base, APP_SIZE.get(name, DEFAULT_APP_SIZE)), app_path)
    over = " OVER BUDGET" if written > BUDGET_BYTES else ""
    print(f"  app   {app_path.name:24} "
          f"{APP_SIZE.get(name, DEFAULT_APP_SIZE)}px  {written / 1024:.1f} KB{over}")

    if name in EMAIL:
        EMAIL_ART.mkdir(parents=True, exist_ok=True)
        email_path = EMAIL_ART / f"{name}.png"
        resized(base, EMAIL[name]).save(email_path, "PNG", optimize=True)
        # No budget here: nothing in that folder is in the APK.
        print(f"  email {email_path.name:24} "
              f"{EMAIL[name]}px  {email_path.stat().st_size / 1024:.1f} KB")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("names", nargs="*", help="asset names, without .png")
    parser.add_argument("--all", action="store_true", help="every known asset")
    args = parser.parse_args()

    names = sorted(APP_SIZE) if args.all else args.names
    if not names:
        parser.print_help()
        return 1

    for name in names:
        convert(name)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
