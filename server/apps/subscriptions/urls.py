from django.urls import path

from .views import ActivateView, StartTrialView, StatusView

app_name = "subscriptions"

urlpatterns = [
    # Art. 7.6 — the signed snapshot the app revalidates every 24 h.
    path("status/", StatusView.as_view(), name="status"),
    # Art. 7.1 — once per device.
    path("trial/", StartTrialView.as_view(), name="trial"),
    # Art. 7.3 step 5 — the code from the external payment page.
    path("activate/", ActivateView.as_view(), name="activate"),
]
