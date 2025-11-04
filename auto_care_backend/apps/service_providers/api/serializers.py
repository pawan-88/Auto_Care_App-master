from rest_framework import serializers
from ..models import ServiceProvider, ServiceAssignment
from apps.bookings.models import Booking
from apps.accounts.models import User
from apps.locations.api.serializers import ServiceAreaSerializer

# -------------------------------
# Service Provider Serializer
# -------------------------------
class ServiceProviderSerializer(serializers.ModelSerializer):
    """Serializer for Service Provider profile"""
    user_mobile = serializers.CharField(source='user.mobile_number', read_only=True)
    service_area_names = serializers.SerializerMethodField(read_only=True)
    
    class Meta:
        model = ServiceProvider
        fields = [
            'id', 'employee_id', 'full_name', 'phone_number', 'email',
            'user_mobile', 'specialization', 'experience_years',
            'service_areas', 'service_area_names',
            'current_latitude', 'current_longitude', 'is_available',
            'verification_status', 'background_check_completed',
            'rating', 'total_jobs_completed', 'total_earnings',
            'joined_date', 'last_location_update'
        ]
        read_only_fields = [
            'id', 'employee_id', 'user_mobile', 'verification_status',
            'background_check_completed', 'rating', 'total_jobs_completed',
            'total_earnings', 'joined_date', 'last_location_update'
        ]
    
    def get_service_area_names(self, obj):
        return [area.name for area in obj.service_areas.all()]

# -------------------------------
# Provider Registration Serializer
# -------------------------------
class ServiceProviderRegistrationSerializer(serializers.Serializer):
    """Serializer for provider registration"""
    mobile_number = serializers.CharField(max_length=15)
    full_name = serializers.CharField(max_length=255)
    email = serializers.EmailField(required=False, allow_blank=True)
    specialization = serializers.ChoiceField(choices=ServiceProvider.SPECIALIZATION_CHOICES)
    experience_years = serializers.IntegerField(min_value=0)
    
    def validate_mobile_number(self, value):
        if User.objects.filter(mobile_number=value).exists():
            raise serializers.ValidationError("This mobile number is already registered.")
        return value

# -------------------------------
# Booking Serializer (nested)
# -------------------------------
class BookingSerializer(serializers.ModelSerializer):
    """Serializer for Booking details, including customer info"""
    user = serializers.SerializerMethodField(read_only=True)

    class Meta:
        model = Booking
        fields = ['id', 'vehicle_type', 'date', 'time_slot', 'service_address',
                  'latitude', 'longitude', 'notes', 'user']

    def get_user(self, obj):
        if obj.user:
            return {
                'id': obj.user.id,
                'name': obj.user.name,
                'mobile_number': obj.user.mobile_number,
                'email': obj.user.email
            }
        return None

# -------------------------------
# Service Assignment Serializer
# -------------------------------
class ServiceAssignmentSerializer(serializers.ModelSerializer):
    """Serializer for Service Assignments with full booking and customer info"""
    booking = BookingSerializer(read_only=True)
    provider_name = serializers.CharField(source='service_provider.full_name', read_only=True)
    customer_name = serializers.CharField(source='booking.user.name', read_only=True)
    customer_mobile = serializers.CharField(source='booking.user.mobile_number', read_only=True)
    
    class Meta:
        model = ServiceAssignment
        fields = [
            'id', 'booking', 'service_provider', 'provider_name',
            'customer_name', 'customer_mobile', 'status',
            'assigned_at', 'accepted_at', 'started_at', 'completed_at',
            'estimated_arrival_time', 'actual_arrival_time',
            'estimated_completion_time', 'provider_notes', 'rejection_reason'
        ]
        read_only_fields = [
            'id', 'assigned_at', 'accepted_at', 'started_at', 'completed_at'
        ]

# -------------------------------
# Assignment Action Serializer
# -------------------------------
class AssignmentActionSerializer(serializers.Serializer):
    """Serializer for accepting/rejecting assignments"""
    action = serializers.ChoiceField(choices=['accept', 'reject'])
    reason = serializers.CharField(required=False, allow_blank=True, help_text="Required for rejection")
    
    def validate(self, data):
        if data['action'] == 'reject' and not data.get('reason'):
            raise serializers.ValidationError({
                'reason': 'Reason is required when rejecting an assignment.'
            })
        return data

# -------------------------------
# Location Update Serializer
# -------------------------------
class LocationUpdateSerializer(serializers.Serializer):
    """Serializer for updating provider location"""
    latitude = serializers.DecimalField(max_digits=9, decimal_places=6)
    longitude = serializers.DecimalField(max_digits=9, decimal_places=6)
    
    def validate(self, data):
        lat = float(data['latitude'])
        lng = float(data['longitude'])
        if not (-90 <= lat <= 90):
            raise serializers.ValidationError("Latitude must be between -90 and 90")
        if not (-180 <= lng <= 180):
            raise serializers.ValidationError("Longitude must be between -180 and 180")
        return data
