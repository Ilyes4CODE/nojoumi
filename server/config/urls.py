"""Root URL configuration.

No admin route yet, and no media route ever — there is no MEDIA_ROOT to serve
(Art. 14).
"""

from django.urls import include, path
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView

urlpatterns = [
    # Article 7.2's independent page. The Android app never links here — see
    # apps/web/views.py for why that separation is what keeps the app shippable.
    path("pay/", include("apps.web.urls")),
    # Unauthenticated liveness, checked by the app before sign-in so that
    # "cannot reach the server" and "wrong credentials" are never confused.
    path("api/", include("apps.common.urls")),
    path("api/accounts/", include("apps.accounts.urls")),
    path("api/lessons/", include("apps.lessons.urls")),
    path("api/subscriptions/", include("apps.subscriptions.urls")),
    path("api/payments/", include("apps.payments.urls")),
    # Art. 3 names Swagger via drf-spectacular; Art. 19 makes API docs a
    # deliverable.
    path("api/schema/", SpectacularAPIView.as_view(), name="schema"),
    path(
        "api/docs/",
        SpectacularSwaggerView.as_view(url_name="schema"),
        name="swagger-ui",
    ),
]
