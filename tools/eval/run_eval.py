"""The Article 11.3 measurement harness.

    "من أصل 10 صور دروس واضحة يوفّرها العميل، تُنتج 8 صور على الأقل ملخّصاً سليماً
     لغوياً مع بطاقات حفظ وأسئلة مراجعة مطابقة لمحتوى الدرس."

Runs a folder of images through the real configured processor and writes a report.

**What this tool can and cannot decide.** It checks *structure* objectively: did a
result come back, are there the requested number of cards, does every question
have valid choices, is the text actually Arabic. It cannot check "سليماً لغوياً"
or "مطابقة لمحتوى الدرس" — soundness and faithfulness need a human who reads
Arabic and can see the page. So the report ends with a grading table the developer
fills in, and the 8-of-10 verdict is that column, not this script's.

Usage:
    python tools/eval/run_eval.py --set dev  --grade "السنة الرابعة ابتدائي"
    python tools/eval/run_eval.py --set acceptance --manifest

Images and reports are gitignored: lesson content is child data (Art. 14).
"""

from __future__ import annotations

import argparse
import functools
import json
import os
import pathlib
import sys
import time
import unicodedata

# Progress on a long run must be visible as it happens. Python block-buffers
# stdout when it is redirected to a file, which hid every per-image line of a
# 20-minute run until the process exited.
print = functools.partial(print, flush=True)  # noqa: A001

ROOT = pathlib.Path(__file__).resolve().parents[2]
SERVER = ROOT / "server"
SAMPLES = ROOT / "tools" / "eval" / "samples"
RUNS = ROOT / "tools" / "eval" / "runs"

IMAGE_SUFFIXES = {".jpg", ".jpeg", ".png", ".webp", ".heic"}
CONTENT_TYPES = {
    ".jpg": "image/jpeg",
    ".jpeg": "image/jpeg",
    ".png": "image/png",
    ".webp": "image/webp",
    ".heic": "image/heic",
}


def load_env(path: pathlib.Path) -> None:
    """Put server/.env into the environment. No dependency on python-dotenv."""
    if not path.exists():
        return
    for line in path.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if "=" not in stripped or stripped.startswith("#"):
            continue
        key, value = stripped.split("=", 1)
        os.environ.setdefault(key.strip(), value.strip())


def bootstrap_django() -> None:
    sys.path.insert(0, str(SERVER))
    load_env(SERVER / ".env")
    os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings.dev")
    import django

    django.setup()


def script_ratios(text: str) -> tuple[float, float]:
    """Share of letters that are Arabic script, and share that are Latin.

    Both are needed, not just the Arabic share. The Algerian primary curriculum
    includes **French**, and the client's own sample set contains French language
    pages (`mère`/`porte`, `finir`/`l'imparfait`). On those, a summary written in
    Arabic that quotes French vocabulary is exactly right — and an
    Arabic-share-only check flagged that correct output as a defect. The tool was
    wrong, not the model.
    """
    letters = [c for c in text if unicodedata.category(c).startswith("L")]
    if not letters:
        return 0.0, 0.0
    arabic = sum(1 for c in letters if "؀" <= c <= "ۿ")
    latin = sum(1 for c in letters if c.isascii() and c.isalpha())
    return arabic / len(letters), latin / len(letters)


def structural_check(result, *, card_count: int, question_count: int) -> dict:
    """Objective checks only. Nothing here judges language quality."""
    problems: list[str] = []

    summary = result.summary.strip()
    if len(summary) < 80:
        problems.append(f"summary is very short ({len(summary)} chars)")

    ratio, latin = script_ratios(summary)
    notes: list[str] = []
    if ratio < 0.30:
        # Genuinely wrong: the app is Arabic-first, so a summary that is barely
        # Arabic has failed whatever the source page was.
        problems.append(f"summary is only {ratio:.0%} Arabic letters")
    elif latin > 0.15:
        # Almost certainly a French page. Not a defect — but the reader should
        # know why the ratio is lower, so it is a note rather than a problem.
        notes.append(
            f"{latin:.0%} Latin letters — likely a French lesson, check by eye"
        )

    if len(result.cards) < card_count:
        problems.append(f"asked for {card_count} cards, got {len(result.cards)}")
    for i, card in enumerate(result.cards, 1):
        if not card.front.strip() or not card.back.strip():
            problems.append(f"card {i} has an empty side")
        if len(card.front) > 200:
            problems.append(f"card {i} front is {len(card.front)} chars — not a card")

    if len(result.questions) < question_count:
        problems.append(
            f"asked for {question_count} questions, got {len(result.questions)}"
        )
    for i, q in enumerate(result.questions, 1):
        if len(q.choices) != 4:
            problems.append(f"question {i} has {len(q.choices)} choices, expected 4")
        if len(set(q.choices)) != len(q.choices):
            problems.append(f"question {i} has duplicate choices")
        if not q.prompt.strip():
            problems.append(f"question {i} has an empty prompt")

    return {
        "structurally_ok": not problems,
        "problems": problems,
        "notes": notes,
        "arabic_ratio": round(ratio, 3),
        "latin_ratio": round(latin, 3),
        "summary_chars": len(summary),
        "cards": len(result.cards),
        "questions": len(result.questions),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Article 11.3 eval harness")
    parser.add_argument("--set", default="dev", choices=["dev", "acceptance"])
    parser.add_argument("--grade", default="السنة الرابعة ابتدائي")
    parser.add_argument("--subject", default="")
    parser.add_argument("--cards", type=int, default=12)
    parser.add_argument("--questions", type=int, default=5)
    parser.add_argument("--provider", default=None, help="groq | claude")
    parser.add_argument(
        "--manifest",
        action="store_true",
        help="read per-image grade/subject from manifest.json in the sample folder",
    )
    parser.add_argument(
        "--retries",
        type=int,
        default=4,
        help="retries per image on a rate limit or provider hiccup",
    )
    parser.add_argument(
        "--pace",
        type=float,
        default=25.0,
        help=(
            "seconds to wait between images. Groq's free tier allows ~8000 tokens "
            "per minute and one page costs ~1800 prompt tokens plus completion, so "
            "the default paces a ten-image run instead of tripping 429s."
        ),
    )
    args = parser.parse_args()

    bootstrap_django()
    from apps.ai.processors import LessonProcessingError
    from apps.ai.providers import get_processor

    folder = SAMPLES / args.set
    images = sorted(p for p in folder.iterdir() if p.suffix.lower() in IMAGE_SUFFIXES)
    if not images:
        print(f"no images in {folder}")
        print("drop a few photographs of Arabic schoolbook pages there and re-run.")
        return 1

    manifest: dict[str, dict] = {}
    manifest_path = folder / "manifest.json"
    if args.manifest and manifest_path.exists():
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))

    processor = get_processor(args.provider)
    stamp = time.strftime("%Y%m%d-%H%M%S")
    out_dir = RUNS / f"{stamp}-{args.set}-{processor.name}"
    out_dir.mkdir(parents=True, exist_ok=True)

    print(f"provider : {processor.name}")
    print(f"model    : {getattr(processor, 'model', '-')}")
    print(f"set      : {args.set} ({len(images)} images)")
    print(f"report   : {out_dir}")
    print()

    def process_with_retry(**kwargs):
        """Retry a retryable failure, honouring the provider's own reset hint.

        A rate limit is not a result. Reporting "1 of 10 succeeded" when nine were
        merely throttled would understate the provider and, on the acceptance run,
        would misreport Article 11.3.
        """
        last: Exception | None = None
        for attempt in range(1, args.retries + 1):
            try:
                return processor.process(**kwargs)
            except LessonProcessingError as exc:
                last = exc
                if not exc.retryable or attempt == args.retries:
                    raise
                wait = exc.retry_after_seconds or (10 * attempt)
                wait = min(wait + 2, 90)
                print(
                    f"       throttled, waiting {wait:.0f}s "
                    f"(attempt {attempt}/{args.retries})"
                )
                time.sleep(wait)
        raise last  # unreachable, kept for the type checker

    rows: list[dict] = []
    for index, path in enumerate(images):
        if index and args.pace:
            time.sleep(args.pace)
        meta = manifest.get(path.name, {})
        grade = meta.get("grade", args.grade)
        subject = meta.get("subject", args.subject) or None
        image_bytes = path.read_bytes()

        started = time.monotonic()
        record: dict = {
            "image": path.name,
            "bytes": len(image_bytes),
            "grade": grade,
            "subject": subject,
        }
        try:
            result = process_with_retry(
                image_bytes=image_bytes,
                content_type=CONTENT_TYPES.get(path.suffix.lower(), "image/jpeg"),
                grade=grade,
                subject=subject,
                card_count=args.cards,
                question_count=args.questions,
            )
        except LessonProcessingError as exc:
            record.update(
                error=str(exc),
                retryable=getattr(exc, "retryable", False),
                structurally_ok=False,
                elapsed_ms=int((time.monotonic() - started) * 1000),
            )
            rows.append(record)
            print(f"  {path.name:14} ❌ {exc}")
            continue
        finally:
            del image_bytes  # Art. 14: no lingering reference we control

        record["elapsed_ms"] = int((time.monotonic() - started) * 1000)
        record["latency_ms"] = result.latency_ms
        record["usage"] = result.usage
        record.update(
            structural_check(
                result, card_count=args.cards, question_count=args.questions
            )
        )
        record["result"] = {
            "summary": result.summary,
            "cards": [{"front": c.front, "back": c.back} for c in result.cards],
            "questions": [
                {
                    "prompt": q.prompt,
                    "choices": list(q.choices),
                    "correct_index": q.correct_index,
                }
                for q in result.questions
            ],
        }
        rows.append(record)

        mark = "✅" if record["structurally_ok"] else "⚠️"
        print(
            f"  {path.name:14} {mark} {record['cards']} cards, "
            f"{record['questions']} questions, "
            f"{record['arabic_ratio']:.0%} Arabic, {record['elapsed_ms']} ms"
        )
        for problem in record["problems"]:
            print(f"       - {problem}")
        for note in record.get("notes", []):
            print(f"       · {note}")

    (out_dir / "raw.json").write_text(
        json.dumps(rows, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    write_report(out_dir / "report.md", rows, args, processor)
    write_html(out_dir / "cards.html", rows, args, processor)
    # A stable path, so the newest run is always one click away.
    latest = RUNS / "latest.html"
    latest.write_text(
        (out_dir / "cards.html").read_text(encoding="utf-8"), encoding="utf-8"
    )

    ok = sum(1 for r in rows if r.get("structurally_ok"))
    print()
    print(f"structurally sound: {ok}/{len(rows)}")
    print()
    print("⚠️  This is NOT the Article 11.3 result.")
    print("    11.3 requires a summary that is 'سليم لغوياً' and cards/questions")
    print("    'مطابقة لمحتوى الدرس' — soundness and faithfulness need your eyes.")
    print()
    print(f"    READ THE CARDS:  {RUNS / 'latest.html'}")
    print(f"    grading table:   {out_dir / 'report.md'}")
    return 0


def _esc(text: str) -> str:
    return (
        str(text)
        .replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
    )


def write_html(path: pathlib.Path, rows: list[dict], args, processor) -> None:
    """A readable RTL page for judging the output by eye.

    Deliberately a **local file**, never published anywhere: it contains lesson
    content, which is child data under Article 14. Open it in a browser; do not
    upload it, and do not send it to the client with a child's pages in it.
    """
    total = len(rows)
    ok = sum(1 for r in rows if r.get("structurally_ok"))

    parts = [
        '<!doctype html><html dir="rtl" lang="ar"><head><meta charset="utf-8">',
        '<meta name="viewport" content="width=device-width,initial-scale=1">',
        "<title>نجومي — نتائج معالجة الدروس</title><style>",
        """
        :root{--bg:#f6f7f9;--card:#fff;--ink:#12181f;--muted:#5b6875;
              --line:#e3e7ec;--ok:#0f7b4f;--bad:#b4232b;--accent:#1f4e79;}
        @media (prefers-color-scheme:dark){
          :root{--bg:#11151a;--card:#191f26;--ink:#e9edf2;--muted:#9aa7b4;
                --line:#28313b;--ok:#4ec98d;--bad:#f2777f;--accent:#7fb2e5;}
        }
        *{box-sizing:border-box}
        body{margin:0;padding:24px;background:var(--bg);color:var(--ink);
             font-family:"Segoe UI","Noto Naskh Arabic",Tahoma,sans-serif;
             line-height:1.75;font-size:16px}
        .wrap{max-width:1000px;margin:0 auto}
        h1{font-size:24px;margin:0 0 4px}
        .meta{color:var(--muted);font-size:14px;margin-bottom:20px}
        .warn{background:#fff4e5;border:1px solid #f0c893;color:#6b4300;
              padding:12px 16px;border-radius:10px;margin:16px 0;font-size:14px}
        @media (prefers-color-scheme:dark){
          .warn{background:#2b2113;border-color:#5c4526;color:#f0cf9e}}
        .lesson{background:var(--card);border:1px solid var(--line);
                border-radius:14px;padding:20px;margin:18px 0}
        .lesson h2{font-size:18px;margin:0 0 2px;color:var(--accent)}
        .sub{color:var(--muted);font-size:13px;margin-bottom:14px}
        .sum{background:rgba(127,178,229,.10);border-inline-start:4px solid
             var(--accent);padding:12px 16px;border-radius:8px;margin:12px 0}
        h3{font-size:15px;margin:20px 0 8px;color:var(--muted);
           text-transform:none;letter-spacing:.2px}
        table{width:100%;border-collapse:collapse;font-size:15px}
        th,td{border:1px solid var(--line);padding:9px 12px;text-align:start;
              vertical-align:top}
        th{background:rgba(127,178,229,.10);font-weight:600;width:auto}
        td.n{width:44px;color:var(--muted);text-align:center}
        ol.q{padding-inline-start:22px;margin:0}
        ol.q>li{margin-bottom:14px}
        ul.ch{list-style:none;padding:0;margin:6px 0 0}
        ul.ch li{padding:5px 12px;border:1px solid var(--line);border-radius:8px;
                 margin-bottom:5px}
        ul.ch li.right{border-color:var(--ok);color:var(--ok);font-weight:600}
        .pill{display:inline-block;padding:2px 10px;border-radius:999px;
              font-size:12px;border:1px solid var(--line);color:var(--muted);
              margin-inline-start:6px}
        .pill.ok{color:var(--ok);border-color:var(--ok)}
        .pill.bad{color:var(--bad);border-color:var(--bad)}
        .fail{color:var(--bad)}
        """,
        "</style></head><body><div class='wrap'>",
        "<h1>نجومي — نتائج معالجة الدروس</h1>",
        f"<div class='meta'>المزوّد <b>{_esc(processor.name)}</b> · "
        f"الموديل <b>{_esc(getattr(processor, 'model', '-'))}</b> · "
        f"المجموعة <b>{_esc(args.set)}</b> · "
        f"المطلوب {args.cards} بطاقة و{args.questions} أسئلة · "
        f"{time.strftime('%Y-%m-%d %H:%M')}</div>",
        "<div class='warn'><b>سليمة بنيوياً: "
        f"{ok} من {total}.</b> وهذا <b>ليس</b> نتيجة المعيار 11.3 — المعيار يطلب "
        "ملخّصاً «سليماً لغوياً» وبطاقات وأسئلة «مطابقة لمحتوى الدرس»، "
        "وهذان حكمان لا تصدرهما آلة. اقرأ كل درس وقارنه بالصفحة.<br>"
        "هذا الملف يحتوي محتوى دروس، أي بيانات طفل (المادة 14): "
        "افتحه محلياً ولا تنشره.</div>",
    ]

    for r in rows:
        parts.append("<div class='lesson'>")
        parts.append(f"<h2>{_esc(r['image'])}</h2>")

        if "error" in r:
            parts.append(
                f"<div class='sub fail'>فشل: {_esc(r['error'])}</div></div>"
            )
            continue

        pill = "ok" if r["structurally_ok"] else "bad"
        label = "بنية سليمة" if r["structurally_ok"] else "ملاحظات بنيوية"
        subject = f" · {_esc(r['subject'])}" if r.get("subject") else ""
        parts.append(
            f"<div class='sub'>{_esc(r['grade'])}{subject}"
            f"<span class='pill {pill}'>{label}</span>"
            f"<span class='pill'>{r['cards']} بطاقة</span>"
            f"<span class='pill'>{r['questions']} أسئلة</span>"
            f"<span class='pill'>عربي {r['arabic_ratio']:.0%}</span>"
            f"<span class='pill'>{r['elapsed_ms']} ms</span></div>"
        )
        if r["problems"]:
            parts.append(
                "<div class='sub fail'>" + " · ".join(_esc(p) for p in r["problems"])
                + "</div>"
            )
        if r.get("notes"):
            parts.append(
                "<div class='sub'>" + " · ".join(_esc(n) for n in r["notes"]) + "</div>"
            )

        res = r["result"]
        parts.append("<h3>الملخّص</h3>")
        parts.append(f"<div class='sum'>{_esc(res['summary'])}</div>")

        parts.append("<h3>بطاقات الحفظ</h3>")
        parts.append("<table><tr><th class='n'>#</th><th>الوجه (السؤال)</th>"
                     "<th>الظهر (الجواب)</th></tr>")
        for i, c in enumerate(res["cards"], 1):
            parts.append(
                f"<tr><td class='n'>{i}</td><td>{_esc(c['front'])}</td>"
                f"<td>{_esc(c['back'])}</td></tr>"
            )
        parts.append("</table>")

        if res["questions"]:
            parts.append("<h3>أسئلة المراجعة</h3><ol class='q'>")
            for q in res["questions"]:
                parts.append(f"<li>{_esc(q['prompt'])}<ul class='ch'>")
                for j, choice in enumerate(q["choices"]):
                    cls = " class='right'" if j == q["correct_index"] else ""
                    mark = " ✔" if j == q["correct_index"] else ""
                    parts.append(f"<li{cls}>{_esc(choice)}{mark}</li>")
                parts.append("</ul></li>")
            parts.append("</ol>")

        parts.append("</div>")

    parts.append("</div></body></html>")
    path.write_text("\n".join(parts), encoding="utf-8")


def write_report(path: pathlib.Path, rows: list[dict], args, processor) -> None:
    lines: list[str] = [
        "# Lesson processing report",
        "",
        f"- Set: `{args.set}`",
        f"- Provider: `{processor.name}`  Model: `{getattr(processor, 'model', '-')}`",
        f"- Requested: {args.cards} cards, {args.questions} questions",
        f"- Generated: {time.strftime('%Y-%m-%d %H:%M')}",
        "",
        "**This file contains lesson text, which is child data (Art. 14). It is",
        "gitignored and must not be committed or sent anywhere.**",
        "",
        "## Structural summary",
        "",
        "| Image | OK | Cards | Questions | Arabic | ms | Problems |",
        "|---|---|---|---|---|---|---|",
    ]
    for r in rows:
        if "error" in r:
            lines.append(
                f"| {r['image']} | ❌ | — | — | — | {r.get('elapsed_ms','')} | "
                f"{r['error']} |"
            )
            continue
        lines.append(
            f"| {r['image']} | {'✅' if r['structurally_ok'] else '⚠️'} | "
            f"{r['cards']} | {r['questions']} | {r['arabic_ratio']:.0%} | "
            f"{r['elapsed_ms']} | {'; '.join(r['problems']) or '—'} |"
        )

    lines += [
        "",
        "## Article 11.3 grading — filled in by the developer, not by the tool",
        "",
        "For each image, read the summary and the questions against the page and",
        "mark it. The acceptance criterion is **at least 8 of 10 accepted**.",
        "",
        "| Image | Summary sound? | Cards match the lesson? | Questions match? | Accept |",
        "|---|---|---|---|---|",
    ]
    for r in rows:
        lines.append(f"| {r['image']} | ☐ | ☐ | ☐ | ☐ |")

    lines += ["", "## Output, per image", ""]
    for r in rows:
        lines += [f"### {r['image']}", ""]
        if "error" in r:
            lines += [f"**Failed:** {r['error']}", ""]
            continue
        res = r["result"]
        lines += [
            f"*{r['grade']}" + (f" · {r['subject']}" if r["subject"] else "") + "*",
            "",
            "**الملخّص**",
            "",
            res["summary"],
            "",
            "**بطاقات الحفظ**",
            "",
            "| # | الوجه | الظهر |",
            "|---|---|---|",
        ]
        for i, c in enumerate(res["cards"], 1):
            front = c["front"].replace("|", "\\|")
            back = c["back"].replace("|", "\\|")
            lines.append(f"| {i} | {front} | {back} |")
        lines += ["", "**أسئلة المراجعة**", ""]
        for i, q in enumerate(res["questions"], 1):
            lines.append(f"{i}. {q['prompt']}")
            for j, choice in enumerate(q["choices"]):
                marker = " ✅" if j == q["correct_index"] else ""
                lines.append(f"   - {choice}{marker}")
            lines.append("")

    path.write_text("\n".join(lines), encoding="utf-8")


if __name__ == "__main__":
    raise SystemExit(main())
