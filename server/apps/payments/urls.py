from django.urls import path

from .views import ChargilyWebhookView

app_name = "payments"

urlpatterns = [
    # Art. 7.3 — the gateway posts here. Signature-authenticated, not JWT.
    # Needs a publicly reachable HTTPS URL, which is open question Q19: Art. 19
    # only commits the client to a VPS before Phase 7, while this is Phase 6.
    path("webhook/chargily/", ChargilyWebhookView.as_view(), name="chargily-webhook"),
]
