"""The payment page of Article 7.2 — the one place a price is ever shown.

**This page exists so the Android app never has to.** Article 7.2:

    «التطبيق لا يعرض أي سعر ولا زرّ شراء ولا رابط دفع. الشراء يتمّ في صفحة ويب
    مستقلّة خارج التطبيق.»

and the contract says plainly why: it is what keeps Lunio clear of Google Play's
billing policy, which requires digital purchases inside an app to go through
Play Billing. A third-party gateway reached from inside the app is a documented
cause of removal. So the separation is not decoration — it is the thing that lets
the app ship at all.

**The app does not link here, and must never be made to.** A button, a URL, a QR
code, a "subscribe" hint — any of them turns this page into an in-app payment
link and puts the app back inside the policy. The parent reaches this page the
way they reach any other web page: the client publishes the address. What crosses
back into the app is a **short activation code the parent types once** (Art. 7.3
step 5), and nothing else.

**No card data touches this server** (Art. 7.7). Every field a parent fills in
lives on Chargily's hosted checkout. What is stored here is a transaction id, an
amount, a status and timestamps.
"""

from __future__ import annotations

import logging

from django.conf import settings
from django.http import Http404
from django.shortcuts import render
from django.views.decorators.http import require_GET, require_POST

from apps.payments import chargily
from apps.payments.models import Transaction, TransactionStatus
from apps.subscriptions.plans import PLAN_DAYS, PLAN_PRICE_DZD, PlanCode

log = logging.getLogger("lunio.web")


def _plans() -> list[dict]:
    """The two paid plans, priced from `plans.py` and never from a form.

    Article 7.1 fixes both prices. They are read from the same constant the
    checkout endpoint stamps a transaction with, so the page cannot show one
    number while the gateway charges another.
    """
    return [
        {
            "code": PlanCode.MONTHLY,
            "name": "الاشتراك الشهري",
            "price": PLAN_PRICE_DZD[PlanCode.MONTHLY],
            "days": PLAN_DAYS[PlanCode.MONTHLY],
            "note": "جدّد متى شئت. لا خصم تلقائي.",
            "illustration": "web/img/calendar_month.webp",
            "highlight": False,
        },
        {
            "code": PlanCode.ANNUAL,
            "name": "الاشتراك السنوي",
            "price": PLAN_PRICE_DZD[PlanCode.ANNUAL],
            "days": PLAN_DAYS[PlanCode.ANNUAL],
            "note": "سنة كاملة بسعر عشرة أشهر.",
            "illustration": "web/img/gift_year.webp",
            "highlight": True,
        },
    ]


@require_GET
def plans(request):
    """The page a parent lands on."""
    return render(
        request,
        "web/plans.html",
        {
            "plans": _plans(),
            "configured": bool(settings.CHARGILY_SECRET_KEY),
            "live": settings.CHARGILY_LIVE_MODE,
        },
    )


@require_POST
def checkout(request):
    """Create the checkout and hand the parent to Chargily's hosted page.

    The amount is **never** read from the request. Article 7.1 fixes both prices,
    and a number that arrives over the wire is a number somebody can edit — so it
    comes from `PLAN_PRICE_DZD`, keyed on a plan code validated against the
    enum.
    """
    plan = request.POST.get("plan", "")
    if plan not in (PlanCode.MONTHLY, PlanCode.ANNUAL):
        raise Http404("unknown plan")

    amount = PLAN_PRICE_DZD[plan]

    try:
        created = chargily.create_checkout(
            amount_dzd=amount,
            plan=plan,
            success_url=request.build_absolute_uri(f"/pay/done/?plan={plan}"),
            failure_url=request.build_absolute_uri("/pay/failed/"),
            webhook_endpoint=settings.CHARGILY_WEBHOOK_URL,
            description=f"Lunio {plan}",
        )
    except (chargily.ChargilyError, chargily.ChargilyNotConfigured) as exc:
        log.error("web checkout failed: %s", exc)
        return render(request, "web/failed.html", {"reason": "gateway"}, status=502)

    Transaction.objects.update_or_create(
        gateway_payment_id=str(created.get("id") or "") or None,
        defaults={
            "gateway": "chargily",
            "gateway_checkout_id": str(created.get("id", "")),
            "amount_dzd": amount,
            "status": TransactionStatus.PENDING,
            "plan": plan,
        },
    )

    from django.shortcuts import redirect

    return redirect(created["checkout_url"])


@require_GET
def done(request):
    """Where Chargily sends the parent back, and where the code appears.

    The webhook and this redirect are a **race**, and the page is written around
    that rather than pretending otherwise: the parent's browser often arrives
    before Chargily's server-to-server call has landed. So the page renders in a
    waiting state and polls [code_status] until the code exists.

    The redirect is never treated as proof of payment. Only the signed webhook
    moves a transaction to paid (Art. 7.3), because a query string is something
    anybody can type.
    """
    return render(
        request,
        "web/done.html",
        {"checkout_id": request.GET.get("checkout_id", "")},
    )


@require_GET
def code_status(request):
    """JSON for the waiting page: has the signed webhook issued a code yet?"""
    from django.http import JsonResponse

    checkout_id = request.GET.get("checkout_id", "").strip()
    if not checkout_id:
        return JsonResponse({"state": "unknown"})

    row = Transaction.objects.filter(gateway_checkout_id=checkout_id).first()
    if row is None:
        return JsonResponse({"state": "unknown"})
    if row.status != TransactionStatus.PAID:
        return JsonResponse({"state": row.status})

    code = row.activation_codes.first()
    if code is None:
        return JsonResponse({"state": "paid"})
    return JsonResponse({"state": "ready", "code": code.code})


@require_GET
def failed(request):
    return render(request, "web/failed.html", {"reason": "cancelled"})
