# apps/locations/api/serializers.py
from rest_framework import serializers
from apps.locations.models import Address, ServiceArea

class AddressSerializer(serializers.ModelSerializer):
    latitude = serializers.DecimalField(max_digits=9, decimal_places=6, required=False, allow_null=True)
    longitude = serializers.DecimalField(max_digits=9, decimal_places=6, required=False, allow_null=True)

    class Meta:
        model = Address
        fields = ['id', 'address_type', 'address_line1', 'address_line2',
                  'landmark', 'city', 'state', 'pincode',
                  'latitude', 'longitude', 'is_default', 'created_at']  # ✅ removed updated_at
        read_only_fields = ['id', 'created_at']


    def validate(self, data):
        """
        - If lat/lng provided, ensure both present and check service area membership.
        - If neither provided, that's fine (address created manually).
        """
        lat = data.get('latitude')
        lng = data.get('longitude')

        # Ensure both or neither
        if (lat is None) ^ (lng is None):
            raise serializers.ValidationError("Both latitude and longitude must be provided together, or neither.")

        # If lat/lng provided, check if inside any active ServiceArea (if ServiceArea exists)
        if lat is not None and lng is not None:
            try:
                active_areas = ServiceArea.objects.filter(active=True)
                if active_areas.exists():
                    # convert Decimal to float for contains() if needed
                    inside_any = any(area.contains(float(lat), float(lng)) for area in active_areas)
                    if not inside_any:
                        raise serializers.ValidationError({"detail": "Address is outside service area."})
            except Exception as exc:
                # Be explicit about unexpected exceptions but don't hide them during development
                raise serializers.ValidationError({"detail": f"Service area check failed: {exc}"})

        return data


class ServiceAreaSerializer(serializers.ModelSerializer):
    """
    Basic serializer for ServiceArea model so other modules can import it.
    """
    class Meta:
        model = ServiceArea
        fields = ['id', 'name', 'center_lat', 'center_lng', 'radius_km', 'active']
        read_only_fields = ['id']
