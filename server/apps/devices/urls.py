from django.urls import path

from .views import HeartbeatView

app_name = "devices"

urlpatterns = [
    path("heartbeat/", HeartbeatView.as_view(), name="heartbeat"),
]
