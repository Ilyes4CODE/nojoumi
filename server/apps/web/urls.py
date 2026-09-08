"""The payment page (Art. 7.2). Deliberately not under /api/ — this is a page a
parent visits in a browser, not an endpoint the app calls."""

from django.urls import path

from . import views

app_name = "web"

urlpatterns = [
    path("", views.plans, name="plans"),
    path("checkout/", views.checkout, name="checkout"),
    path("done/", views.done, name="done"),
    path("done/status/", views.code_status, name="code-status"),
    path("failed/", views.failed, name="failed"),
]
