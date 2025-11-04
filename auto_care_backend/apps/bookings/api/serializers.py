from rest_framework import serializers
from ..models import Booking
from apps.locations.models import Address, ServiceArea
from datetime import date as date_type
import logging

logger = logging.getLogger(__name__)

class BookingSerializer(serializers.ModelSerializer):
    """Serializer for both customer and provider booking data."""

    user_name = serializers.CharField(source='user.name', read_only=True)
    user_mobile = serializers.CharField(source='user.mobile_number', read_only=True)
    provider_name = serializers.CharField(source='provider.full_name', read_only=True)
    provider_id = serializers.CharField(source='provider.employee_id', read_only=True)
    service_address = serializers.CharField(source='address.address_line1', read_only=True, default=None)

    class Meta:
        model = Booking
        fields = [
            "id",
            "vehicle_type",
            "date",
            "time_slot",
            "status",
            "created_at",
            "notes",
            "user_name",
            "user_mobile",
            "provider_name",
            "provider_id",
            "service_address",
        ]
        read_only_fields = [
            "id", "status", "created_at", "user_name", "user_mobile",
            "provider_name", "provider_id", "service_address"
        ]


    def get_location_summary(self, obj):
        """Return location summary for frontend display"""
        return obj.get_location_summary()

    def get_address_label(self, obj):
        """Return address label if linked"""
        if obj.address:
            return getattr(obj.address, 'address_type', 'Address')
        return None

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

    def validate(self, data):
        """Cross-field validation for location data"""
        latitude = data.get('latitude')
        longitude = data.get('longitude')
        service_address = data.get('service_address', '').strip()
        address = data.get('address')
        
        # Validate coordinates if provided
        if latitude is not None and longitude is not None:
            try:
                lat = float(latitude)
                lng = float(longitude)
                
                if not (-90 <= lat <= 90):
                    raise serializers.ValidationError("Latitude must be between -90 and 90.")
                if not (-180 <= lng <= 180):
                    raise serializers.ValidationError("Longitude must be between -180 and 180.")
                    
            except (TypeError, ValueError):
                raise serializers.ValidationError("Invalid GPS coordinates.")

        # Service area validation (warning only)
        if latitude and longitude:
            try:
                active_areas = ServiceArea.objects.filter(active=True)
                if active_areas.exists():
                    is_covered = any(
                        area.contains(float(latitude), float(longitude)) 
                        for area in active_areas
                    )
                    
                    if not is_covered:
                        logger.warning(f"Booking requested outside service area: {latitude}, {longitude}")
                        # Don't block, just log warning
                        
            except Exception as e:
                logger.error(f"Service area validation error: {e}")

        # Either service address or saved address is recommended but not required
        if not service_address and not address:
            logger.warning("Booking created without address information")

        # Validate duplicate bookings
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
            
            if self.instance:
                existing = existing.exclude(pk=self.instance.pk)
            
            if existing.exists():
                raise serializers.ValidationError(
                    "You already have a booking for this date and time slot."
                )
        
        return data

    def create(self, validated_data):
        """Create booking with location data"""
        user = self.context['request'].user
        
        # Remove user from validated_data if present
        validated_data.pop('user', None)
        
        booking = Booking.objects.create(user=user, **validated_data)
        
        logger.info(
            f"Booking created: ID {booking.id} "
            f"for user {user.mobile_number}"
        )
        
        return booking

    def update(self, instance, validated_data):
        """Update booking with location validation"""
        if instance.status in ['completed']:
            location_fields = {'latitude', 'longitude', 'service_address', 'address'}
            if any(field in validated_data for field in location_fields):
                raise serializers.ValidationError(
                    "Cannot change location for completed bookings."
                )
        
        booking = super().update(instance, validated_data)
        
        logger.info(
            f"Booking {booking.id} updated for user {booking.user.mobile_number}"
        )
        
        return booking
