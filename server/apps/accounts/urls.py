from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView

from .reset_views import (
    PasswordResetConfirmView,
    PasswordResetRequestView,
    PasswordResetVerifyView,
)
from .views import MeView, RegisterView, SignInView

app_name = "accounts"

urlpatterns = [
    path("register/", RegisterView.as_view(), name="register"),
    # Art. 3: JWT. simplejwt supplies the pair and the refresh.
    # Our own subclass, not simplejwt's view: sign-in also claims the device for
    # this account (one account per phone, 2026-08-28).
    path("token/", SignInView.as_view(), name="token"),
    path("token/refresh/", TokenRefreshView.as_view(), name="token-refresh"),
    path("me/", MeView.as_view(), name="me"),
    # A six-digit code by email rather than a link, because the app has no deep
    # links and a link would push the parent into a browser. See reset_codes.py.
    path(
        "password/reset/",
        PasswordResetRequestView.as_view(),
        name="password-reset",
    ),
    path(
        "password/reset/verify/",
        PasswordResetVerifyView.as_view(),
        name="password-reset-verify",
    ),
    path(
        "password/reset/confirm/",
        PasswordResetConfirmView.as_view(),
        name="password-reset-confirm",
    ),
]
