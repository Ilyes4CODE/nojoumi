> ## ⚠ هذا الملف مُتجاوَز — انظر [design-v3.md](design-v3.md)
>
> أرسل العميل تصميمه المرجعي (`client_design/`) في 2026-08-21، واللوحة والتميمة تغيّرتا بناءً عليه:
> البنفسجي بدل الأزرق السماوي، وشخصية طفل ثلاثية الأبعاد بدل النجمة ذات الوجه. **v3 هو المرجع.**
> يبقى هذا الملف لأن أسبابه ما زالت صحيحة — وخاصةً قاعدة «الذهبي للنجوم وحدها».

# Design direction v2 — «روح الطفولة»

Written 2026-08-18, after the client reviewed the first Stitch pass.

> **Client feedback, verbatim:** «مليح بصح خصه شوي روح الطفولة — يعني تغيير الالوان بالوان زاهية و رسوم»

---

# ▶ ابدأ من هنا — ترتيب اللصق

**افتح Stitch، وأنشئ مشروعاً جديداً، والصق البرومبتات بهذا الترتيب. واحداً تلو الآخر، وانتظر ردّ Stitch بين كل
واحد والذي يليه.**

| # | البرومبت | أين هو | ماذا تحصل |
|---|---|---|---|
| **1** | **السياق** | ⬇ **في هذا الملف، أوّل صندوق تحت مباشرةً** | Stitch يردّ `ready` فقط. لا شاشات |
| **2** | لوحة التميمة | في هذا الملف | ورقة بستّ وضعيات لنُجَيْم |
| **3** | الرسوم الموضعية | في هذا الملف | خمس رسمات |
| **4** | شاشات الطفل | في هذا الملف | البيت · البطاقة · السؤال · بطاقة الحجب |
| **5+** | شاشات الوالد | [stitch-prompt.md](stitch-prompt.md) — «Screen 6 … Screen 9» | الإعداد · اللوحة · الإعدادات · السجلّ |

**وإن كنت تستعمل ChatGPT بدل Stitch** — أو معه — فبرومبتاته في [screen-prompts.md](screen-prompts.md). هو أقوى في شيئين: **رسم التميمة** فعلاً لا رسم أيقونات عامّة، و**توليد ملفّ HTML واحد** تفتحه على الهاتف نفسه وأقرأ منه قيماً حقيقية بدل أن أقيسها من صورة.

**البرومبت رقم 1 هو أوّل صندوق كود تجده بعد هذا الجدول. ابدأ منه.**

ثلاث ملاحظات قبل أن تبدأ:

- **لا تتخطَّ البرومبت 1.** هو الذي يضع اللوحة والأسلوب في ذاكرة الجلسة؛ بدونه كل شاشة تخرج بألوان مختلفة.
- **قسّم إلى مشروعين.** Stitch يرفض تصدير أكثر من 16 شاشة. مشروع «Lunio — child» يأخذ البرومبتات 1→4،
  ومشروع «Lunio — parent» يأخذ البرومبت 1 ثم شاشات 6→9. **الصق البرومبت 1 في كليهما.**
- **إن خرجت العربية مكسورة**، ولّد بالإنجليزية وخذ التخطيط فقط. لا تنسخ نصّاً عربياً من الموك‑أب إلى التطبيق —
  عندنا 156 مفتاحاً مكتوبة بعناية في `app_ar.arb`، والعميل يقرأ كل سطر.

---

## PROMPT 1 — السياق · الصق هذا أوّلاً

```
I am designing an Android app called "Lunio" (Lunio) for the Algerian market.

WHAT IT DOES
It turns screen time into a currency a child earns by studying. The child answers
memorization cards and review questions and earns stars. 1 star = 1 minute of play
time. Games the parent has marked stay locked until the child has stars to spend.
It is a motivation tool, not a punishment tool — this must be felt in every screen.

TWO AUDIENCES, ONE APP
- The CHILD's screens: ages roughly 7–12. Bright, warm, playful and illustrated.
  Large and legible at arm's length on a cheap phone in daylight. Big tap targets
  (56dp minimum). Very few elements per screen, one clear action. Never scolding,
  never red-alert. When something is locked it shows its price, not a rebuke.
- The PARENT's screens: ordinary, dense, calm on purpose. A parent reading a ledger
  of stars is doing administrative work and does not want a playground. Standard
  Material 3 list rows and cards.

LANGUAGE AND DIRECTION
Arabic first, right-to-left by default. Design every screen RTL: back arrows point
right, list chevrons point left, text aligns to the right, progress bars fill from
the right. English is a secondary locale.

DEVICE FLOOR
Android 10, 4.7–6 inch screen, 2 GB RAM. No runtime blur, no stacked shadows, no
elaborate motion. Depth comes from artwork, not from live effects.

PALETTE (use exactly these)
- Sky blue #3DA5F5 — primary actions: filled buttons, active states, progress fills
- Star gold #FFC22E — star icons and star counts ONLY, nowhere else, so that gold
  always means "this is about stars"
- Grass green #2FCB8A — remaining play time ONLY
- Coral #FF7A59 — celebration: streaks, finishing the day, the mascot cheering
- Grape #7B5CFF — review-question surfaces, so they read differently from cards
- Night indigo #2B3A67 — the balance card background and the logo. A night sky is
  where stars live, and a gold star on it reads instantly on a cheap screen
- Locked #B6BCCB — greyed game icons and the blocked card. Soft, never red
- Page background #FFF9F0 — a warm off-white, not pure white
- Body text #1E2436 on the warm background, or white on the indigo. Nothing else.

Gold is never used for body text: fine for a 44dp numeral or an icon, unreadable
as a sentence. Cards are white with a 20dp radius, buttons 14dp, one elevation
level only.

ILLUSTRATION STYLE
Modern, polished, slightly three-dimensional vector illustration. Soft shading and
real depth, a single warm light source from the top-left, gentle gradients baked
into the artwork, a soft ambient shadow under each object. Rounded geometric
shapes. NOT flat sticker art, and NOT photorealistic 3D rendering — the polish of
a modern mobile game's UI art, executed as vector shapes. No textures, no noise,
no harsh drop shadows, no photographs of people.

There is a mascot named Nujaym: a rounded five-pointed gold star with a simple
friendly face. It appears wherever a screen would otherwise be empty.

TYPOGRAPHY
System Arabic font, rounded and friendly on the child's screens. Numbers in the
play-time countdown use tabular figures so the digits do not jitter as they
change. Star counts are large and bold.

Reply with "ready" and wait for the next prompt.
```

---

## PROMPT 2 — لوحة التميمة

```
Design a mascot character sheet for a children's educational app.

THE CHARACTER
A friendly star named "Nujaym". A rounded five-pointed star, golden #FFC22E, with a
soft highlight at the top-left and a gentle ambient shadow underneath. Simple face:
two dot eyes, one curved smiling mouth, small soft blush marks on the cheeks.
Rounded and huggable — nothing sharp, no thin points.

THE STYLE
Modern, polished, slightly three-dimensional vector illustration — soft shading and
depth, a single warm light source from the top-left, gentle gradients. NOT flat
sticker art, and NOT photorealistic 3D rendering. The polish of a modern mobile
game's UI art, executed as vector shapes. No textures, no noise, no harsh drop
shadows, no outlines of varying weight.

SIX POSES on one sheet, evenly spaced on a warm off-white #FFF9F0 background:
1. Waving hello, cheerful
2. Holding a small schoolbook against its side
3. Thinking — one hand near the face, eyes looking up, calm and patient
4. Cheering with both arms up, small coral #FF7A59 confetti around it
5. ASLEEP — eyes closed, a small contented smile, tiny "z" marks floating up.
   Drawn in muted grey-gold instead of full gold. This one must look peaceful and
   inviting, like it is waiting to be woken up. It must NOT look sad, disappointed
   or disapproving.
6. Pointing to one side, encouraging

No text anywhere in the artwork.
```

---

## PROMPT 3 — الرسوم الموضعية

```
Design five spot illustrations for the same children's app, in exactly the same
style as the Nujaym mascot sheet: polished rounded vector, soft top-left light,
gentle baked-in gradients, no textures, no harsh shadows.

Palette: sky blue #3DA5F5, star gold #FFC22E, grass green #2FCB8A, coral #FF7A59,
grape #7B5CFF, on a warm off-white #FFF9F0.

1. An open schoolbook page seen at a slight angle, warmly lit, with a soft glow
   suggesting a photo is being taken of it.
2. A small stack of flashcards, slightly fanned, the top card blank.
3. A wall calendar with a small warm coral flame on the current day.
4. A padlock built from soft rounded shapes, entirely in muted grey #B6BCCB. It
   must read as "not yet" — gentle and neutral. No chains, no prohibition sign,
   nothing red, nothing that looks like a warning.
5. A night sky: deep indigo #2B3A67 with a scattering of small gold stars and a
   thin crescent moon. Very low contrast and calm, because a large number will sit
   on top of it and must stay readable.

Each illustration on its own square canvas, generous padding, no text anywhere.
```

---

## PROMPT 4 — شاشات الطفل

```
Now design the child's screens using the mascot and this palette.

Apply throughout:
- The balance card sits on the night indigo #2B3A67 with the faint star-field
  pattern behind it. The star count is large, bold and gold. The play-time
  countdown below it is grass green, or muted grey at 00:00.
- Everywhere the screen is empty or waiting, Nujaym appears in the matching pose
  rather than an icon.
- Buttons are sky blue #3DA5F5, fully rounded corners, generous height.
- Cards are white on the warm off-white background, 20dp radius, one soft shadow.

Design these screens:

A) THE HOME SCREEN, two versions:
   - with tasks waiting: the balance card at the top, then a tasks card with a
     thick progress bar filling from the RIGHT, a line saying how many tasks are
     left, and one large button "ابدأ مهام اليوم". Nujaym holding a book beside it.
   - with no lessons yet: the balance card, then Nujaym pointing, and the line
     "لا توجد مهام بعد" with no button at all.

B) A MEMORIZATION CARD, two states:
   - the question state: a slim progress bar at the top, the question in large
     centred Arabic in the middle, and three stacked full-width buttons at the
     bottom — filled "أعرفها", outlined "لم أعرفها", and a low-emphasis text
     button "أظهر الجواب". Nujaym thinking, small, at the side.
   - the answer state: the question stays, a divider, the answer below it, one
     short feedback line, and a single button "متابعة".

C) A REVIEW QUESTION: the question text, then 3–4 full-width outlined answer
   buttons on a grape-tinted surface so it reads differently from a card.

D) THE BLOCKED-GAME CARD: a floating card over another app, with the SLEEPING
   Nujaym, the headline "وقت اللعب انتهى", one supporting line, one filled button
   "اكسب نجوماً الآن", and a plain dismiss button. Gentle, never a warning.

Keep every one of these unchanged, they are requirements:
- no price, no currency, no purchase or subscription wording anywhere a child can
  see it
- the blocked card is an invitation, not a warning
- play time is always mm:ss, never rounded to whole minutes
- right-to-left layout: text right-aligned, progress bars filling from the right
```

---

## ثم: شاشات الوالد

في المشروع الثاني، الصق **PROMPT 1** أوّلاً، ثم انسخ من [stitch-prompt.md](stitch-prompt.md) البرومبتات
المعنونة **Screen 6** (معالج الإعداد) · **Screen 7** (لوحة الوالد) · **Screen 8** (الإعدادات) ·
**Screen 9** (سجلّ النجوم).

هذه تبقى هادئة وبسيطة عمداً. **التميمة تظهر في موضعين فقط على جانب الوالد:** تلوّح في خطوة الترحيب
(Screen 6)، وتشير في السجلّ الفارغ (Screen 9). ما عدا ذلك: صفوف Material 3 عادية.

**ولا تحتاج تعديل تلك البرومبتات.** تحقّقت منها: لا تحمل أي لون مثبَّت، فكلّها ترث اللوحة من PROMPT 1.

---
---

# المرجع — لماذا هذه القرارات

كل ما تحت هذا السطر شرح لا يُلصق في Stitch.

## ١. ما أخطأت فيه النسخة الأولى، وما أصابت

**الخطأ:** لوحة ألوان **منتَج** على تطبيق **أطفال**. نيلي غامق في كل مكان، لون تمييز واحد، مسافات محسوبة —
لغة أداة إنتاجية. مقبولة على ورقة مواصفات، باردة على هاتف يُسلَّم لطفل في التاسعة. العميل محقّ.

**الصواب، وهو غير قابل لإعادة التفاوض:** لونان في هذا التطبيق **معلومة لا زينة**.

- **الذهبي يعني نجوماً. النجوم وحدها.** لا زرّاً، لا عنواناً، لا إطاراً.
- **الأخضر يعني وقت اللعب المتبقّي. ذلك وحده.** لا رسالة نجاح، لا علامة صحّ.

لحظة يظهر الذهبي على زرّ، يصير على الطفل أن يقرأ كل عنوان ليعرف ما ينظر إليه، ويتوقّف الشيء الوحيد القابل
للالتقاط بلمحة عن كونه كذلك. فتِّح كل ما عداهما بقدر ما يشاء العميل؛ هذان ينضبطان.

**والنيلي بقي، منزَّلاً.** لم يعد التطبيق — صار **سماء الليل خلف الرصيد**، ولا شيء غير ذلك. نجمة ذهبية على
سماء داكنة هي أعلى تباين في التصميم كلّه، وبطاقة الرصيد هي السطح الوحيد الذي ينظر إليه الطفل من آخر الغرفة.

## ٢. اللوحة

| الدور | Hex | أين يجوز | أين لا يجوز |
|---|---|---|---|
| أزرق سماوي — الفعل | `#3DA5F5` | الأزرار، الحالات النشطة، تعبئة التقدّم | — |
| **ذهبي النجمة** | `#FFC22E` | أيقونات النجوم وأعدادها والمكافآت | أي شيء ليس نجمة |
| **أخضر اللعب** | `#2FCB8A` | وقت اللعب المتبقّي | حالات النجاح، علامات الصحّ |
| مرجاني — احتفال | `#FF7A59` | شعلة المواظبة، إتمام اليوم، هتاف التميمة | الأخطاء والتحذيرات |
| عنبي — ثانوي | `#7B5CFF` | أسطح أسئلة المراجعة | — |
| نيلي الليل — الهوية | `#2B3A67` | بطاقة الرصيد، الشعار، الثيم الداكن | خلفيات الصفحات في الوضع الفاتح |
| المقفل | `#B6BCCB` | الأيقونات الرمادية، بطاقة الحجب، التميمة النائمة | أي شيء عاجل |
| خلفية الصفحة | `#FFF9F0` | أرضية التطبيق | — |
| الحبر | `#1E2436` | كل نصّ الجسم | — |

**قواعد تباين غير قابلة للتفاوض، لأن المادة 13 تضع الأرضية عند شاشة رخيصة في ضوء النهار:**

- الذهبي **ليس نصّاً أبداً**. ممتاز عند 44 نقطة عريضاً؛ غير مقروء كجملة على أبيض.
- والأخضر كذلك، للسبب نفسه.
- كل نصّ جارٍ حبر `#1E2436` على `#FFF9F0`، أو أبيض على النيلي. لا ثالث.
- حالة الحجب رمادية، **لا حمراء أبداً**. المادة 1 تسمّي هذا أداة تحفيز؛ والجدار الأحمر نقيضها.

## ٣. «أكثر واقعية» — القراءة الصحيحة

طلب العميل رسوماً **أجمل وأكثر واقعية**. حرفياً يشير هذا إلى الواقعية الفوتوغرافية، وهي الإجابة الخاطئة هنا
لثلاثة أسباب. هذه هي القراءة التي نعمل بها، وتستحقّ أن تُعرض عليه بهذه الكلمات:

> **ليست فوتوغرافية. مُجسَّمة.** شخصيات مدوّرة بإضاءة ناعمة وعمق حقيقي — كما تبدو تطبيقات الأطفال الحديثة —
> بدل فنّ الملصقات المسطّح. غنيّة ومصقولة، لا حرفية.

**ولماذا لا فوتوغرافية:**

1. **أرضية المادة 13.** هاتف 2 جيغا بأندرويد 10. فنّ نقطي مفصّل بثلاث كثافات ذاكرة لا نملكها، والتطبيق يجب
   أن يصمد 30 دقيقة متواصلة بلا انهيار (المعيار 11.10).
2. **لا صورة لطفل حقيقي، أبداً.** التطبيق في Designed for Families والمادة 14 تمنع أي معرِّف للطفل. صورة طفل
   حقيقي على تطبيق رقابة أبوية تستدعي بالضبط التدقيق الذي نتجنّبه.
3. **الاتساق بعد سنة.** الفنّ المتّجهي المُجسَّم يستطيع أي رسّام مدّه لاحقاً. المُصيَّر ثلاثي الأبعاد لا، بدون
   ملفات المشهد الأصلية.

## ٤. التميمة

**الاسم المقترح: نُجَيْم** — تصغير «نجم». دافئ، واضح لطفل جزائري، ويحوّل عملة النجوم من عدّاد إلى **شخصية**.
**الاسم يحتاج توقيع العميل** — التسمية له لا لنا.

**الشكل:** نجمة خماسية مدوّرة، ذهبية `#FFC22E`، بإضاءة ناعمة من أعلى اليسار وظلّ خفيف أسفل اليمين. وجه بسيط:
عينان نقطتان، فم منحنٍ، خدّان ورديان. لا أذرع ولا أرجل في الوضعية الافتراضية — تظهر حيث تحتاجها الوضعية فقط.

**ستّ وضعيات ولا سابعة.** السابعة تُرسم بعد ستّة أسابيع بأسلوب مختلف قليلاً، فتبدو المجموعة مجمَّعة لا مصمَّمة.

| الوضعية | أين تظهر | ماذا يجب أن تقول |
|---|---|---|
| **تلوّح** | ترحيب الإعداد، أوّل تشغيل | «تفضّل» |
| **تحمل كتاباً** | البيت حين توجد مهام | «هناك ما يُنجَز» |
| **تفكّر** | أثناء بطاقة الحفظ | «خذ وقتك» — لا نفاد صبر |
| **تهتف** | إتمام الجلسة، المكافأة | «أنهيتَ اليوم كلّه» |
| **نائمة** | الرصيد صفر، بطاقة الحجب | انظر أدناه |
| **تشير** | الحالات الفارغة، سجلّ الوالد الفارغ | «هنا سيظهر» |

**والنائمة تؤدّي أصعب مهمّة في التطبيق.** هي ما يراه الطفل لحظة يُرفض له ما أراد. يجب أن تُقرأ *عُد وأيقظني*،
لا *أنت معاقَب*. رمادي‑ذهبي هادئ، عينان مغمضتان، حروف «z» صغيرة، ابتسامة خفيفة. **إن بدت حزينة أو عاتبة فهي
خطأ** — وهذه أهمّ ملاحظة مراجعة على مجموعة الرسوم كلّها.

## ٥. الرسوم الموضعية الخمس

كل واحدة تحلّ محلّ حالة فارغة عارية، وهي المواضع التي يبدو فيها التطبيق رخيصاً.

1. **صفحة كتاب مدرسي بإضاءة دافئة** — شاشة التقاط الدرس.
2. **رزمة بطاقات مروَّحة قليلاً** — بطاقة المهام حين تنتظر جلسة.
3. **تقويم حائط بشعلة صغيرة** — المواظبة، في نظرة الوالد العامة.
4. **قفل من أشكال مدوّرة ناعمة، رمادي** — حالة اللعبة المقفلة. لا سلاسل، لا علامة منع، لا أحمر.
5. **سماء ليل بنجوم وهلال** — نقش خلفية بطاقة الرصيد، خافت جداً لئلّا ينافس الرقم فوقه.

**ولا رسمة تحمل نصّاً.** النصّ المخبوز داخل الرسم لا يُترجَم، ونحن نشحن بلغتين تُراجَع العربية فيهما سطراً سطراً.

## ٦. ميزانية الأصول

ملموسة، لأن «خفّفها» ليست مواصفة والمادة 13 مواصفة.

| القيد | القيمة |
|---|---|
| مجموع أصول الرسوم | 11 (ستّ وضعيات + خمس موضعية) |
| الصيغة | SVG حيث تسمح الأشكال، وإلا WebP |
| لكل أصل نقطي | ≤ 120 كيلوبايت عند 3x، يُصغَّر وقت التشغيل |
| المضاف إلى APK | ≤ 1.5 ميغابايت |
| ضبابية أو ظلال طبقية وقت التشغيل | **لا شيء** — الإضاءة تُخبز داخل الأصل |
| حركة | لا شيء في v1. إن أراد العميل تحريك التميمة لاحقاً: ملفّ Lottie واحد لوضعية الهتاف فقط، وله قياسه الخاص على الجهاز |

## ٧. أين لا يذهب الفنّ

كل بند هنا التزام تعاقدي، والموك‑أب الذي يخالف واحداً منها خاطئ مهما بدا جميلاً. وهذه بالضبط البنود التي تكسرها
إعادة التصميم بهدوء.

| القاعدة | المصدر |
|---|---|
| لا سعر ولا زرّ شراء ولا رابط دفع في أي مكان يصله الطفل | المادة 7.2 |
| لا شيء عن الاشتراك على أي شاشة طفل | المادة 7.1 |
| أيقونات الألعاب المقفلة تبقى **ظاهرة ومسعَّرة**، لا تُخفى | D-7 |
| مربّع الإفصاح يبدأ فارغاً، في كل مرّة | سياسة Play |
| «أكمل بدونهما الآن» يبقى بوضوح الزرّ الأساسي | المادة 15.2 |
| حالة الحجب رمادية داعية، لا حمراء عاتبة | المادة 1 |
| لا صورة فوتوغرافية لطفل حقيقي، في أي مكان، أبداً | المادة 14، Designed for Families |
| لا نصّ مخبوز داخل أي رسمة | لغتان، كلتاهما مُراجَعة |

## ٨. ما أحتاجه منك بعد ذلك

لقطات PNG لكل شاشة تكفي، مع لوحة التميمة والرسوم الموضعية بصيغة SVG أو WebP. الشاشات مبنيّة ومغطّاة بـ99
اختباراً، فهذه **إعادة كسوة لا إعادة بناء**: الألوان وأنصاف الأقطار والمسافات ومواضع الأصول تنزل على ودجات
قائمة وناجحة أصلاً.

تصدير Figma اختياري والعقد لا يطلبه. إن أراده العميل كمُخرَج بحدّ ذاته، فـStitch يحدّ التصدير بـ16 شاشة —
والتقسيم الذي يبقى تحته موصوف في أعلى هذا الملف.
