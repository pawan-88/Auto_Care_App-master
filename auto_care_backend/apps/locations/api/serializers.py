from rest_framework import serializers
from apps.locations.models import Address, ServiceArea
from django.conf import settings

class AddressSerializer(serializers.ModelSerializer):
    class Meta:
        model = Address
        fields = ['id', 'label', 'address_line', 'latitude', 'longitude', 'is_default', 'created_at']
        read_only_fields = ['id', 'created_at']

    def validate(self, data):
        # Ensure latitude/longitude are present
        lat = data.get('latitude') or self.instance and self.instance.latitude
        lng = data.get('longitude') or self.instance and self.instance.longitude
        if lat is None or lng is None:
            raise serializers.ValidationError({"detail": "latitude and longitude are required."})
        # Optionally: verify inside at least one active service area
        from apps.locations.models import ServiceArea
        active_areas = ServiceArea.objects.filter(active=True)
        if active_areas.exists():
            inside_any = any(area.contains(float(lat), float(lng)) for area in active_areas)
            if not inside_any:
                raise serializers.ValidationError({"detail": "Address is outside service area."})
        return data

class ServiceAreaSerializer(serializers.ModelSerializer):
    class Meta:
        model = ServiceArea
        fields = ['id', 'name', 'center_lat', 'center_lng', 'radius_km', 'active']
        read_only_fields = ['id']
