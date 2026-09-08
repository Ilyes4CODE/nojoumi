# Sample lesson images

**Nothing in this directory is committed.** `.gitignore` blocks it, and that is
deliberate: Article 14 forbids storing lesson images, and git history is
permanent — a page from a child's schoolbook in the repository history could
never be removed.

Two sets, and they must never be mixed.

## `dev/` — the developer's own photographs

Purpose: build and tune the pipeline. Any Arabic schoolbook page, any grade, any
subject. Fail freely, iterate, re-shoot.

- Name them `01.jpg`, `02.jpg`, …
- Include at least one **deliberately bad** image — crooked, dim, glare — to
  exercise the `readable: false` path, so the app says "أعد التصوير" instead of
  inventing a lesson.
- Record the grade and subject for each; the manifest is generated from that.

## `acceptance/` — the client's ten images (Art. 19)

Purpose: the **only** set Article 11.3 is measured on — "من أصل 10 صور دروس
واضحة **يوفّرها العميل**، تُنتج 8 صور على الأقل ملخّصاً سليماً لغوياً مع بطاقات
حفظ وأسئلة مراجعة مطابقة لمحتوى الدرس".

Rules that protect both parties:

1. They come **from the client, in writing**, ideally photographed from the
   child's actual schoolbooks.
2. Once received, the set is **locked**. It is the measurement set and cannot be
   swapped for harder images later.
3. The client confirms in writing that they are "واضحة" (clear), as Art. 11.3
   requires.
4. **They are never used to tune prompts.** Tuning on the measurement set turns
   8/10 into training on the exam, and the number stops meaning anything.

## Photographing well

The same guidance goes into the Arabic parent guide, because result quality is
tied to photo quality (Art. 18):

- press the page flat
- daylight from the side, **no flash** — flash burns a glare patch through the text
- camera parallel to the page, not angled
- the page fills the frame; no table edge, no fingers
- one page per photo
