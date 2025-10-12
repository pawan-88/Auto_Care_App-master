from rest_framework import generics, permissions, status
from rest_framework.response import Response
from apps.locations.models import Address, ServiceArea
from .serializers import AddressSerializer, ServiceAreaSerializer

class AddressListCreateView(generics.ListCreateAPIView):
    serializer_class = AddressSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Address.objects.filter(user=self.request.user).order_by("-is_default", "-created_at")

    def perform_create(self, serializer):
        # If new address is set as default, unset previous defaults
        is_default = serializer.validated_data.get('is_default', False)
        if is_default:
            Address.objects.filter(user=self.request.user, is_default=True).update(is_default=False)
        serializer.save(user=self.request.user)

class AddressRetrieveUpdateDeleteView(generics.RetrieveUpdateDestroyAPIView):
    serializer_class = AddressSerializer
    permission_classes = [permissions.IsAuthenticated]
    lookup_field = 'pk'

    def get_queryset(self):
        return Address.objects.filter(user=self.request.user)

    def perform_update(self, serializer):
        is_default = serializer.validated_data.get('is_default', False)
        if is_default:
            Address.objects.filter(user=self.request.user, is_default=True).update(is_default=False)
        serializer.save()

# Admin endpoints for service areas
class ServiceAreaListCreateView(generics.ListCreateAPIView):
    permission_classes = [permissions.IsAdminUser]
    serializer_class = ServiceAreaSerializer
    queryset = ServiceArea.objects.all()

class ServiceAreaDetailView(generics.RetrieveUpdateDestroyAPIView):
    permission_classes = [permissions.IsAdminUser]
    serializer_class = ServiceAreaSerializer
    queryset = ServiceArea.objects.all()
