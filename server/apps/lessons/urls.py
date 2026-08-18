from django.urls import path

from .views import ProcessLessonView

app_name = "lessons"

urlpatterns = [
    path("process/", ProcessLessonView.as_view(), name="process"),
]
