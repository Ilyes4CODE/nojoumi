# Design direction v4 — تصميم العميل الثاني

كُتب 2026-08-21، بعد الأربع صور في [`client_design/`](../client_design/) (1.jpeg → 4.jpeg).
يُلغي [design-v3.md](design-v3.md) و[design-v2.md](design-v2.md).

---

## ١. الحكم أوّلاً

**هذا التصميم Lunio فعلاً، لا تطبيقاً آخر.** الفرق عن الدفعة الأولى هائل: المصمّم فهم المنتج.

الدليل ليس الانطباع بل ستّ شاشات لا توجد إلا في عقدنا:

- **شبكة التطبيقات بأسعارها بالنجوم** — «الكاميرا · تحتاج ٢ نجوم»، «ألعاب ذكاء · تحتاج ١٠ نجوم»، أيقونات رمادية
  بشارة ذهبية وسعر تحتها، وبجانبها أيقونات ملوّنة مفتوحة. **هذا D-7 حرفياً**، وهو ما غاب تماماً عن التصميم الأول.
- **الشريط العلوي** `Lunio · ⏱ 15:00 · ⭐ 120` — وقت اللعب بـ`mm:ss` والرصيد بالنجوم معاً.
- **بطاقة الحجب** — «وقت اللعب انتهى / أنجز مهامك لتكسب نجوماً جديدة / اكسب نجوماً الآن / لاحقاً». نصّها يطابق
  `app_ar.arb` تقريباً كلمةً بكلمة، وقفلها **بنفسجي بوجه مبتسم لا أحمر** — أي أن المصمّم فهم المادة 1.
- **شاشة الإفصاح** بمربّع «قرأت الإفصاح وأوافق كولي أمر»، وتحت الزرّ الأساسي **«أكمل بدونها الآن»** بوضوح مماثل.
  هذه المادة 15.2 مرسومة.
- **لوحة تحكم الأهل** بمنح وخصم وسبب اختياري وإيقاف مؤقت.
- **بوّابة الأهالي** برمز سرّي و«نسيت الرمز السري؟».

**التوصية: نعتمده أساساً للتطبيق.** ونصلح فيه ما يلي.

---

## ٢. 🔴 المانع — كل مدايات الإعدادات مخالفة للملحق

شاشة «الإعدادات» في 1.jpeg و2.jpeg تطبع تحت كل قيمة مداها المسموح. **السبعة كلّها مخالفة للملحق «آلية النجوم
ووقت اللعب»، والمادة 19 تجعله جزءاً لا يتجزّأ من العقد.**

| الإعداد | ما في التصميم | ما في الملحق | الفارق |
|---|---|---|---|
| قيمة النجمة بالدقائق | **من 1 إلى 60** | **0.5 – 3** | 20 ضعفاً |
| السقف اليومي للنجوم | **من 10 إلى 200** | **20 – 150** | الطرفان |
| أدنى وقت للبطاقة (ثوان) | **من 5 إلى 30** | **1 – 5** | 6 أضعاف |
| حجم الجلسة اليومية | **من 5 إلى 50** | **5 – 30** | السقف |
| أسئلة المراجعة يومياً | **من 1 إلى 10** | **0 – 15** (D-15) | الطرفان |
| رصيد الترحيب | **من 0 إلى 100** | **0 – 30** | السقف |
| انتهاء صلاحية الرصيد | **شهري \| أسبوعي** | **يومي \| أسبوعي** | ⬅ خيار غير موجود |

**والقيم المعروضة نفسها خارج المدى الصحيح:** قيمة النجمة `5` دقائق (السقف 3)، وأدنى وقت للبطاقة `15` ثانية
(السقف 5).

### لماذا هذا مانع لا ملاحظة

**١. المدى «شهري» لا وجود له في العقد.** المادة 6.7 تنصّ على أن الرصيد غير المستعمل ينتهي **في نهاية اليوم**،
والملحق يجعل ذلك الافتراضي ويضيف **الأسبوعي** خياراً. «شهري» يعني أن طفلاً يكدّس ثلاثين يوماً من وقت اللعب —
وهو نقيض المادة 6.7 نصّاً وروحاً.

**٢. الكود يرفض هذه القيم اليوم، ولا يقرّبها.** `StarRules` يتحقّق عند الإنشاء ويرمي استثناءً:

```
'star value must be 0.5–3 minutes (appendix §5), got 5.0 min'
'minimum time on card must be 1–5 s (appendix §5), got 15000ms'
```

هذا الرفض **مقصود** (D-1): القيمة المقصوصة صامتةً خرقٌ للعقد لا يلاحظه أحد، والمرميّة تظهر في اختبار. أي أن
هذه الشاشة **لا يمكن تنفيذها كما رُسمت** — وأحد عشر اختباراً في `parent_dashboard_test.dart` يثبّت المدايات
المطبوعة على الشاشة مقابل ما يفرضه المحرّك.

**٣. أثر المدى الواحد أكبر ممّا يبدو.** قيمة النجمة 60 دقيقة تعني أن النجمة الواحدة ساعة لعب. مع سقف 200 نجمة
يصير اليوم **200 ساعة** — أي أن الإعدادات تسمح بتعطيل الحجب كلّه من حيث لا يدري الوالد.

### ما يجب أن يحدث

المدايات في الملحق **موقّعة**، وهي غير قابلة للتفاوض في الكود. أمّا التصميم فيُصحَّح رقماً برقم. أرسل هذا
للعميل قبل أن نبني الشاشة:

> «شاشة الإعدادات ممتازة في تخطيطها، لكن المدايات المكتوبة تحت كل قيمة تختلف عن ملحق العقد «آلية النجوم ووقت
> اللعب» (المادة 19). المدايات الصحيحة: قيمة النجمة 0.5–3 دقائق، السقف اليومي 20–150 نجمة، أدنى وقت للبطاقة
> 1–5 ثوان، حجم الجلسة 5–30، أسئلة المراجعة 0–15، رصيد الترحيب 0–30. وخيار «شهري» لانتهاء الصلاحية غير موجود
> في العقد — البديلان هما «يومي» و«أسبوعي» (المادة 6.7). سأعتمد أرقام الملحق في التنفيذ.»

---

## ٣. 🟠 سبع ملاحظات أصغر

| # | ما في التصميم | لماذا يُغيَّر | البديل |
|---|---|---|---|
| ١ | **شعار LUNIO** على ثماني شاشات، و«أهلاً بك في Lunio» على شاشة الصاروخ | التطبيق اسمه Lunio | شعار Lunio في كل مكان |
| ٢ | **«أهلاً بك يا أحمد»** + صورة رمزية للطفل | **المادة 14** تمنع اسم الطفل وصورته | «مرحباً» بلا اسم، والشخصية مرشد لا ملفّ شخصي |
| ٣ | **«المتجر»** في شريط التنقّل السفلي | كلمة «متجر» تُقرأ سطحَ شراء عند مراجع Play (المادة 7.2) — والمَعرِض نفسه سليم | «الألعاب» أو «افتح لعبة» |
| ٤ | **«لدي حساب بالفعل»** على شاشة البدء | الطفل لا يملك حساباً في Lunio (المادة 14، AD-6) | تُحذف |
| ٥ | **المفتاحان تحت الإفصاح يبدوان فعّالين والمربّع فارغ** (3.jpeg) | Play تراجع هذا التفاعل: الموافقة **تسبق** الإذن | المفتاحان **رماديان معطّلان** حتى يُؤشَّر المربّع |
| ٦ | **«تأكيد الإجابة»** بعد اختيار الإجابة | نقرة زائدة على طفل؛ عندنا الاختيار **هو** الإجابة | تُحذف — إلا في الاختبار الأسبوعي حيث التأنّي مقصود |
| ٧ | **«الجلسة الحالية: 5 أيام»** في لوحة الوالد | هذه **المواظبة** لا الجلسة | «المواظبة: 5 أيام» |

### ثلاث سلاسل نصّية مغلوطة

- **«3 مهام متبقية»** على شريط تقدّم **معالج الإعداد** — نصّ المهام تسرّب إلى الإعداد. الصحيح «الخطوة 1 من 4».
- **«6 / 60 من نصف اليوم»** في لوحة الوالد — الصحيح «من السقف اليومي». و«نصف اليوم» لا معنى له في العقد.
- **«لماذا لم تمنح نجمة؟»** عنوانٌ فوق **شاشة الإعدادات** في 2.jpeg، وفوق بطاقة فارغة في 3.jpeg. العنوان صحيح
  والمحتوى تحته ليس محتواه: هذا لسان السجلّ الذي يسرد أسباب المادة 6.

### حساب لا يستقيم

لوحة الأهل: «النجوم المكتسبة 45 · النجوم المتبقية 15 · إجمالي الرصيد 60». ثلاثة أرقام لا تتّسق مع نموذجنا،
لأن `45 + 15 = 60` تخلط **ما كُسب** بـ**ما تبقّى**. الصحيح عندنا:

```
كسبها الطفل   45   (تخضع للسقف اليومي)
منحتَها أنت    15   (فوق النظام — لا تخضع للسقف)
─────────────────
الرصيد        60
```

وشريط السقف يقيس **45 / 60** أي المكتسب وحده. منحة الوالد يجب ألّا تبدو وكأنها استهلكت يوم الطفل (المادة 6.4
مقابل الملحق §4).

---

## ٤. 🟡 نوع مهمّة جديد — قرار يخصّ العميل

في 1.jpeg شاشة سؤال بحقل نصّ حرّ: **«ما معنى كلمة "تجزّ"؟ / اكتب إجابتك هنا…»**

هذا **ليس في نموذجنا**. المادة 2 والمادة 4.3 تعرّفان نوعين: بطاقات حفظ (تقرير ذاتي) وأسئلة مراجعة (اختيار من
متعدّد). الإجابة الحرّة تفتح سؤالاً حقيقياً: **من يصحّحها؟**

- **مطابقة نصّية حرفية** ← تفشل على أوّل اختلاف في التشكيل أو الهمزة أو المسافة. طفل يكتب «الجَزّ» بدل «الجز»
  يخسر نجمة يستحقّها، والمادة 6.1 تمنح النجمة على **الإجابة الصحيحة من المحاولة الأولى**.
- **تصحيح بالذكاء الاصطناعي** ← نداء شبكة لكل إجابة. يعني أن الجلسة اليومية تتوقّف بلا إنترنت، ويعني كلفة API
  على العميل (المادة 17 تضعها على حسابه)، ويعني أن انتهاء الاشتراك يوقف **التصحيح** — بينما المادة 7.1 تنصّ
  على أن النجوم تبقى تعمل بعد الانتهاء.

**توصيتي: نؤجّله.** الاختيار من متعدّد يغطّي المادة 2 كاملةً، ويعمل بلا إنترنت، ويُصحَّح بيقين. إن أراد العميل
الإجابة الحرّة فهي **طلب تغيير** يُسعَّر منفصلاً (المادة 17)، ويحتاج قراراً مكتوباً في مسألة التصحيح.

---

## ٥. اللوحة — من التصميم نفسه

| الدور | Hex | أين |
|---|---|---|
| بنفسجي أساسي | `#5B4CDB` | الأزرار، أشرطة التقدّم، الحالة النشطة |
| بنفسجي داكن | `#16264A` | زرّ «منح نجوم» في لوحة الوالد |
| بنفسجي باهت | `#EDEBFB` | البلاطات، خلفيات الأيقونات المستديرة |
| **ذهبي النجمة** | `#FFC857` | **النجوم وحدها** |
| **أخضر وقت اللعب** | `#22C55E` | **وقت اللعب وحده** |
| كهرماني باهت | `#FCE7B8` | بلاطات مفتوحة (سباق السيارات، موسيقى) |
| نعناعي باهت | `#D6F5E3` | بلاطة «حساب ذكي» |
| رمادي المقفل | `#B6BCCB` | الأيقونات المقفلة |
| الخلفية | `#F7F6FC` | أرضية التطبيق |
| الحبر | `#1E2436` | كل نصّ الجسم |

**القاعدة الوظيفية تبقى:** الذهبي للنجوم وحدها، والأخضر لوقت اللعب وحده. التصميم يحترمها — الذهبي يظهر على
`⭐ 120` وعلى شارات الأسعار فقط، والأخضر على `15:00`. هذا صحيح، ويجب ألّا ينزلق عند التنفيذ.

---

## ٦. الرسوم — نعم، مجموعة جديدة، وأصغر

مجموعة v3 (طفل ثلاثي الأبعاد بستّ وضعيات + ستّ أيقونات) **تُلغى**. أسلوب هذا التصميم مختلف: **رسوم بنفسجية
ناعمة، أشياء لا شخصيات**، وأيقونات صغيرة داخل مربّعات مستديرة تُغطّيها أيقونات Material المعتادة بلا فنّ مخصّص.

النتيجة: **سبعة أصول بدل اثني عشر**، وميزانية أخفّ على جهاز المادة 13.

| # | الأصل | أين | الملاحظة |
|---|---|---|---|
| 1 | **قفل بنفسجي بوجه مبتسم** | بطاقة الحجب · الأيقونات المقفلة | **أهمّ أصل في التطبيق** — انظر أدناه |
| 2 | **نجمة ذهبية كبيرة** | نهاية الجلسة · المكافآت · خطوات الإعداد | بلا وجه — عملة لا شخصية |
| 3 | **حقيبة مدرسية بنفسجية** بكتب وأقلام | خطوة المستوى الدراسي | كما في 2.jpeg |
| 4 | **صاروخ بشخصية رائد فضاء** | شاشة الترحيب | كما في 2.jpeg |
| 5 | **رائد فضاء صغير دائري** | تحية الشاشة الرئيسية | **مرشد لا صورة ملفّ شخصي** (المادة 14) |
| 6 | **درع بنفسجي بعلامة صحّ** | الإفصاح · بوّابة الأهالي | كما في 2.jpeg و3.jpeg |
| 7 | **نقش سماء بنجوم** | خلفية بطاقة الحجب | تباين منخفض جداً |

**كل ما عداها أيقونات Material ملوّنة** داخل مربّعات `#EDEBFB` مستديرة — بالضبط كما في لوحة الوالد في 4.jpeg.
لا تولّد لها فنّاً: نجمة، هدية، ساعة، تقويم، كتاب، كأس — كلّها موجودة في Material وتوفّر نصف الميزانية.

**وأيقونات التطبيقات في الشبكة تأتي من الجهاز نفسه** عبر `PackageManager` — لا نرسمها ولا نملكها.

### القفل — لماذا هو الأهمّ

هو ما يراه الطفل **لحظة يُرفض له ما أراد**، وهو نفسه الذي يتكرّر على كل أيقونة مقفلة. المصمّم أصابه: بنفسجي،
بوجه مبتسم، لا أحمر ولا علامة تحذير. **إن خرج عابساً أو حادّاً صار التطبيق كلّه عقاباً** — والمادة 1 تسمّيه
تحفيزاً، والملحق §3 يقول «النظام لا يعاقب الطفل على الخطأ، بل يكتفي بعدم مكافأته».

### أين تضعها

المجلّدان موجودان ومسجّلان في `pubspec.yaml`، ولا يحتاجان تعديلاً:

```
app/assets/illustrations/     ← الأصول 1 → 7
app/assets/icons/             ← فارغ الآن (أيقونات Material تكفي)
```

بالأسماء في `lib/core/illustrations.dart` — سأحدّثه ليطابق المجموعة الجديدة قبل أن تولّد شيئاً، حتى لا تسمّي
ملفّاً مرّتين. والكتالوج يسقط إلى مربّع هادئ لأي ملفّ غير موجود، فالتطبيق يعمل الآن وقبل وصول أي رسمة.

**الميزانية (المادة 13):** WebP بخلفية شفّافة · ≤150 كيلوبايت للأصل عند 3x · **≤1 ميغابايت إجمالاً** — أخفّ من
v3 لأن الأصول أقلّ وأبسط.

---

## ٧. برومبتات الرسوم السبعة

**ولّد رقم 1 أوّلاً وأقرّه، ثم أرفقه مع كل ما بعده** — هو الذي يثبّت الأسلوب.

### 1 · القفل الودود

```
Create a single 3D icon illustration on a plain background.

SUBJECT
A friendly padlock character. A rounded, plump padlock body in soft violet
(#8B7BE8) with a slightly lighter lavender shackle arch on top. It has a simple
cute face on the body: two small dark oval eyes and one gentle closed smile. Soft
and huggable, with generously rounded corners - no sharp edges anywhere.

STYLE
Polished stylized 3D render in the manner of a modern children's app. Soft studio
lighting with a warm key light from the upper left, a gentle ambient shadow
beneath, smooth matte surfaces with a subtle sheen. No texture, no noise, no harsh
drop shadow.

TONE - this matters more than anything else
It must read as gentle, patient and inviting: "not yet", never "forbidden". It is
shown to a child at the exact moment they are refused something they wanted, and
it must make them want to come back. It must absolutely NOT look stern, angry,
sad, disapproving or alarming. No chains, no red, no prohibition sign, no warning
symbol.

COMPOSITION
Square image, centred, generous padding, transparent background if supported,
otherwise plain flat #F7F6FC.

No text, no letters, no numbers, no watermark.
```

### 2 · النجمة الذهبية

```
Use the attached image as the style reference - polished stylized 3D, soft
upper-left studio light, gentle ambient shadow, smooth matte surfaces, rounded
forms, no texture.

SUBJECT
A five-pointed star in warm gold (#FFC857), with soft rounded points and a plump
three-dimensional volume, and one bright specular highlight on its upper left.
No face, no eyes, no expression - this is a currency symbol, not a character.

Optionally two much smaller pale gold stars floating beside it for balance.

COMPOSITION
Square image, centred, generous padding, transparent background if supported,
otherwise plain flat #F7F6FC.

No text, no letters, no numbers, no watermark.
```

### 3 · الحقيبة المدرسية

```
Use the attached image as the style reference - polished stylized 3D, soft
upper-left studio light, gentle ambient shadow, smooth matte surfaces, rounded
forms, no texture.

SUBJECT
A school scene, arranged as a small still life:
- a plump violet (#8B7BE8) backpack standing upright, with rounded straps and a
  front pocket
- a short stack of two or three closed books leaning beside it, in muted amber and
  soft teal
- a small cup of coloured pencils on the other side
Everything soft-edged and toy-like.

COMPOSITION
Square image, the group centred, generous padding, transparent background if
supported, otherwise plain flat #F7F6FC. No floor line, no scenery.

No text, no letters, no numbers, no logo, no watermark - the backpack must carry
no writing of any kind.
```

### 4 · الصاروخ

```
Use the attached image as the style reference - polished stylized 3D, soft
upper-left studio light, gentle ambient shadow, smooth matte surfaces, rounded
forms, no texture.

SUBJECT
A cheerful cartoon rocket flying upward at a slight diagonal. The rocket body is
violet (#5B4CDB) with a lighter lavender nose cone and rounded fins. Through a
round porthole window a small friendly astronaut character waves - a stylized
cartoon animal or child in a white space suit, generic and appealing, not
resembling any specific real person.

Around the rocket: a few soft gold stars, one small planet with a ring, and gentle
rounded cloud puffs, all on a deep indigo night-sky ground.

COMPOSITION
A rounded rectangular illustration, roughly 4:3, filling the frame edge to edge.

No text, no letters, no numbers, no logo, no watermark anywhere.
```

### 5 · رائد الفضاء الصغير

```
Use the attached image as the style reference - polished stylized 3D, soft
upper-left studio light, smooth matte surfaces, rounded forms, no texture.

SUBJECT
A friendly young astronaut character shown from the chest up, waving with one
hand, smiling warmly and looking at the viewer. A white space suit with soft
violet (#5B4CDB) trim and a clear rounded helmet. Warm olive skin and dark hair
visible through the helmet, so the character reads as North African.

Generic and appealing - it must not resemble any specific real child.

COMPOSITION
Square image, the character centred inside a soft circular vignette of pale violet
(#EDEBFB), generous padding, transparent outside the circle if supported.

No text, no letters, no numbers, no watermark.
```

### 6 · الدرع

```
Use the attached image as the style reference - polished stylized 3D, soft
upper-left studio light, gentle ambient shadow, smooth matte surfaces, rounded
forms, no texture.

SUBJECT
A rounded shield in soft violet (#8B7BE8) with a lighter lavender border and a
single clean white check mark centred on its face. Calm and reassuring rather
than military - the corners are soft, the proportions are plump, and there is no
crest, no emblem and no metallic detail.

A few small pale violet leaves or sparkles may sit at its base for warmth.

COMPOSITION
Square image, centred, generous padding, transparent background if supported,
otherwise plain flat #F7F6FC.

No text, no letters, no numbers, no watermark.
```

### 7 · نقش سماء النجوم

```
Create a seamless background pattern image.

SUBJECT
A calm night sky pattern: small soft stars of varying size scattered across the
frame, in gold (#FFC857), pale violet (#8B7BE8) and soft blue, on a plain
transparent background. A few tiny dots between them for texture.

The stars must be sparse and very low in contrast. A large white card and a
headline will sit on top of this, so nothing in the pattern may compete for
attention or make text harder to read.

COMPOSITION
Square, evenly distributed with no obvious focal point, edges designed to tile
without a visible seam. Transparent background.

No text, no letters, no numbers, no watermark.
```

---

## ٨. خريطة الشاشات — من التصميم إلى ما هو مبنيّ

الأخضر مبنيّ ومختبَر؛ يحتاج كسوة فقط.

| شاشة التصميم | الحالة عندنا | العمل |
|---|---|---|
| البدء | مبنيّة | حذف «لدي حساب بالفعل» |
| الترحيب (الصاروخ) | مبنيّة | إضافة الرسمة |
| المستوى الدراسي (الحقيبة) | مبنيّة | إضافة الرسمة |
| رمز الأهل + تأكيده | مبنيّة | كسوة |
| الصلاحيات والإفصاح | مبنيّة | **تعطيل المفتاحين حتى التأشير** |
| بيت الطفل | مبنيّة | كسوة · حذف الاسم والصورة |
| شبكة التطبيقات بالأسعار | **غير مبنيّة** | تحتاج `PackageManager` — بعد سبايك Kotlin |
| بطاقة الحجب | **غير مبنيّة** | تحتاج الطبقة العائمة — بعد السبايك |
| بطاقة الحفظ | مبنيّة | كسوة |
| سؤال اختيار من متعدّد | مبنيّة | حذف «تأكيد الإجابة» |
| سؤال بإجابة حرّة | **خارج النطاق** | §4 — طلب تغيير |
| بوّابة الأهالي | مبنيّة | كسوة |
| لوحة تحكم الأهل | مبنيّة | تصحيح الحساب والتسميات |
| الإعدادات | مبنيّة | **تصحيح المدايات السبع** |
| لماذا لم تمنح نجمة | مبنيّة | ربط العنوان بمحتواه |
| التقارير (شريط سفلي) | غير موجودة | السجلّ يغطّيها — أو طلب تغيير |

**ستّ شاشات جاهزة تنتظر الكسوة فقط، واثنتان تنتظران الطبقة الأصلية.**

---

## ٩. خلاصة

**اعتمده.** هذا التصميم يفهم المنتج، وشبكة الأيقونات المقفلة بأسعارها وحدها تساوي كل ما سبق.

**ولا تبنِ شاشة الإعدادات حتى يردّ العميل على المدايات.** السبع كلّها مخالفة للملحق الموقّع، وواحد منها
(«شهري») يخالف المادة 6.7 نصّاً. الكود يرفض هذه القيم اليوم — لا لأنني اخترت ذلك، بل لأن D-1 قرّر أن القيمة
المقصوصة صامتةً خرقٌ لا يلاحظه أحد. سأنفّذ أرقام الملحق، وأُعلمه بذلك كتابةً.
