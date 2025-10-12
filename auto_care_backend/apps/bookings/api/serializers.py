from rest_framework import serializers
from ..models import Booking
from apps.locations.models import Address, ServiceArea
from datetime import date as date_type
import logging

logger = logging.getLogger(__name__)

class BookingSerializer(serializers.ModelSerializer):
    """Enhanced serializer with location support for frontend integration"""
    
    # Read-only fields for response
    user_name = serializers.CharField(source='user.name', read_only=True)
    user_mobile = serializers.CharField(source='user.mobile_number', read_only=True)
    
    # Location summary for response
    location_summary = serializers.SerializerMethodField(read_only=True)
    
    # Address details if booking uses saved address
    address_label = serializers.CharField(source='address.label', read_only=True)

    class Meta:
        model = Booking
        fields = [
            # Original fields
            "id", "vehicle_type", "date", "time_slot", "status", "created_at", "notes",
            "user_name", "user_mobile",
            
            # 🆕 NEW LOCATION FIELDS
            "latitude", "longitude", "service_address", "address",
            "location_summary", "address_label"
        ]
        read_only_fields = ["id", "status", "created_at", "user_name", "user_mobile", 
                           "location_summary", "address_label"]

    def get_location_summary(self, obj):
        """Return location summary for frontend display"""
        return obj.get_location_summary()

    def validate_date(self, value):
        """Validate booking date is not in the past"""
        if value < date_type.today():
            raise serializers.ValidationError("Cannot book service for past dates.")
        return value

    def validate_address(self, value):
        """Validate address belongs to the requesting user"""
        if value:
            request = self.context.get('request')
            if request and request.user:
                if value.user != request.user:
                    raise serializers.ValidationError("Invalid address selection.")
        return value

    def validate_location_coordinates(self, latitude, longitude):
        """Validate GPS coordinates are valid"""
        try:
            lat = float(latitude)
            lng = float(longitude)
        except (TypeError, ValueError):
            raise serializers.ValidationError("Invalid GPS coordinates.")
        
        # Basic coordinate range validation
        if not (-90 <= lat <= 90):
            raise serializers.ValidationError("Latitude must be between -90 and 90.")
        if not (-180 <= lng <= 180):
            raise serializers.ValidationError("Longitude must be between -180 and 180.")
            
        return lat, lng

    def validate_service_area_coverage(self, latitude, longitude):
        """Validate location is within active service areas"""
        active_areas = ServiceArea.objects.filter(active=True)
        
        # If no service areas defined, allow all locations
        if not active_areas.exists():
            logger.warning("No active service areas defined - allowing all locations")
            return True
        
        # Check if location is within any active service area
        is_covered = any(
            area.contains(latitude, longitude) 
            for area in active_areas
        )
        
        if not is_covered:
            # Get nearest service area for better error message
            distances = []
            for area in active_areas:
                from apps.locations.models import haversine_distance
                distance = haversine_distance(
                    float(area.center_lat), float(area.center_lng),
                    latitude, longitude
                )
                distances.append((area.name, distance))
            
            if distances:
                nearest_area, distance = min(distances, key=lambda x: x[1])
                raise serializers.ValidationError(
                    f"Location is outside our service area. "
                    f"Nearest service area is {nearest_area} ({distance:.1f} km away)."
                )
            else:
                raise serializers.ValidationError("Location is outside our service area.")
        
        return True

    def validate(self, data):
        """Cross-field validation for location data"""
        latitude = data.get('latitude')
        longitude = data.get('longitude')
        service_address = data.get('service_address', '').strip()
        address = data.get('address')
        
        # Ensure location coordinates are provided
        if latitude is None or longitude is None:
            raise serializers.ValidationError({
                "location": "GPS coordinates (latitude and longitude) are required."
            })
        
        # Validate coordinates
        try:
            lat, lng = self.validate_location_coordinates(latitude, longitude)
        except serializers.ValidationError as e:
            raise serializers.ValidationError({"location": str(e)})
        
        # Ensure service address is provided
        if not service_address:
            raise serializers.ValidationError({
                "service_address": "Service address is required."
            })
        
        # Validate service area coverage
        try:
            self.validate_service_area_coverage(lat, lng)
        except serializers.ValidationError as e:
            raise serializers.ValidationError({"location": str(e)})
        
        # If address is provided, validate coordinates match
        if address:
            addr_lat = float(address.latitude)
            addr_lng = float(address.longitude)
            
            # Allow small GPS variance (about 100 meters)
            lat_diff = abs(lat - addr_lat)
            lng_diff = abs(lng - addr_lng)
            
            if lat_diff > 0.001 or lng_diff > 0.001:
                logger.warning(
                    f"GPS coordinates don't match saved address for user {self.context.get('request').user.id}"
                )
                # Don't block - user might be at a slightly different location
        
        # Check for duplicate bookings (existing validation)
        user = self.context['request'].user
        booking_date = data.get('date')
        time_slot = data.get('time_slot')
        
        if booking_date and time_slot:
            existing = Booking.objects.filter(
                user=user,
                date=booking_date,
                time_slot=time_slot,
                status__in=['pending', 'confirmed']
            )
            
            # Exclude current instance if updating
            if self.instance:
                existing = existing.exclude(pk=self.instance.pk)
            
            if existing.exists():
                raise serializers.ValidationError({
                    "booking": "You already have a booking for this date and time slot."
                })
        
        return data

    def create(self, validated_data):
        """Create booking with location data"""
        user = self.context['request'].user
        booking = Booking.objects.create(user=user, **validated_data)
        
        logger.info(
            f"Location-aware booking created: ID {booking.id} "
            f"at {booking.latitude}, {booking.longitude} "
            f"for user {user.mobile_number}"
        )
        
        return booking

    def update(self, instance, validated_data):
        """Update booking with location validation"""
        # Don't allow location changes for confirmed/completed bookings
        if instance.status in ['completed']:
            location_fields = {'latitude', 'longitude', 'service_address', 'address'}
            if any(field in validated_data for field in location_fields):
                raise serializers.ValidationError({
                    "booking": "Cannot change location for completed bookings."
                })
        
        booking = super().update(instance, validated_data)
        
        logger.info(
            f"Booking {booking.id} updated with location data "
            f"for user {booking.user.mobile_number}"
        )
        
        return booking