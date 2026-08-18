from __future__ import annotations

from drf_spectacular.utils import extend_schema
from rest_framework import status
from rest_framework.generics import CreateAPIView
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle
from rest_framework.views import APIView

from .serializers import ParentSerializer, RegisterSerializer


class RegisterView(CreateAPIView):
    """Create a parent account. Open, but throttled."""

    serializer_class = RegisterSerializer
    permission_classes = [AllowAny]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "register"

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        return Response(ParentSerializer(user).data, status=status.HTTP_201_CREATED)


class MeView(APIView):
    """The authenticated parent's own record."""

    permission_classes = [IsAuthenticated]

    @extend_schema(
        responses=ParentSerializer,
        summary="The authenticated parent",
        description="Contains no child data whatsoever (Art. 14).",
    )
    def get(self, request):
        return Response(ParentSerializer(request.user).data)
