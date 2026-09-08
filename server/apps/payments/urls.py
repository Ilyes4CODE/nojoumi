from django.urls import path

from .views import ChargilyWebhookView, CreateCheckoutView

app_name = "payments"

urlpatterns = [
    # Art. 7.2 — called by the independent payment page, never by the app.
    path("checkout/", CreateCheckoutView.as_view(), name="create-checkout"),
    # Art. 7.3 — the gateway posts here. Signature-authenticated, not JWT.
    # Needs a publicly reachable HTTPS URL, which is open question Q19: Art. 19
    # only commits the client to a VPS before Phase 7, while this is Phase 6.
    path("webhook/chargily/", ChargilyWebhookView.as_view(), name="chargily-webhook"),
]
