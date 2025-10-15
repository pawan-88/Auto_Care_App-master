from datetime import date as date_type
from rest_framework import serializers
from apps.bookings.models import Booking  # ✅ Import fixed (main issue)
from apps.accounts.models import User, Address


class MobileSerializer(serializers.Serializer):
    mobile_number = serializers.CharField(max_length=15)

class VerifyOTPSerializer(serializers.Serializer):
    mobile_number = serializers.CharField(max_length=15)
    otp = serializers.CharField(max_length=6)

class UserProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['mobile_number', 'name', 'email', 'address', 'vehicle']

class UserProfileSerializer(serializers.ModelSerializer):
    """Serializer for user profile data (mobile, name, etc.)."""

    class Meta:
        model = User
        fields = ["id", "name", "mobile_number", "email"]
        read_only_fields = ["id", "mobile_number"]

class BookingSerializer(serializers.ModelSerializer):
    """Serializer for creating and validating user bookings."""

    user_name = serializers.CharField(source='user.name', read_only=True)
    user_mobile = serializers.CharField(source='user.mobile_number', read_only=True)

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
        ]
        read_only_fields = ["id", "status", "created_at", "user_name", "user_mobile"]

    # ---------------------- Validation Methods ----------------------

    def validate_date(self, value):
        """Ensure booking date is not in the past."""
        if value < date_type.today():
            raise serializers.ValidationError("Cannot book for past dates.")
        return value

    def validate_time_slot(self, value):
        """Ensure time slot is provided."""
        if not value or not value.strip():
            raise serializers.ValidationError("Time slot is required.")
        return value.strip()

    def validate(self, data):
        """Prevent duplicate bookings for the same date/time."""
        request = self.context.get('request')
        if not request or not hasattr(request, 'user'):
            return data

        user = request.user
        booking_date = data.get('date')
        time_slot = data.get('time_slot')

        # Only check for duplicates if both fields exist
        if booking_date and time_slot:
            existing = Booking.objects.filter(
                user=user,
                date=booking_date,
                time_slot=time_slot,
                status__in=['pending', 'confirmed']
            )

            # If updating (instance exists), exclude the current one
            if self.instance:
                existing = existing.exclude(id=self.instance.id)

            if existing.exists():
                raise serializers.ValidationError({
                    "detail": "You already have a booking for this date and time slot."
                })

        return data
    

    # -------------------
# Address Serializers
# -------------------
class AddressSerializer(serializers.ModelSerializer):
    full_address = serializers.CharField(source='get_full_address', read_only=True)
    
    class Meta:
        model = Address
        fields = [
            'id', 'address_type', 'address_line1', 'address_line2',
            'landmark', 'city', 'state', 'pincode',
            'latitude', 'longitude', 'is_default',
            'full_address', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at', 'full_address']
    
    def validate_pincode(self, value):
        """Validate pincode format"""
        # Remove any spaces or dashes
        clean_pincode = str(value).replace(' ', '').replace('-', '')
        
        if not clean_pincode.isdigit():
            raise serializers.ValidationError("Pincode must contain only digits")
        
        if len(clean_pincode) != 6:
            raise serializers.ValidationError(f"Pincode must be exactly 6 digits, got {len(clean_pincode)}")
        
        return clean_pincode
    
    def validate_address_line1(self, value):
        """Validate address line 1"""
        if not value or not value.strip():
            raise serializers.ValidationError("Address line 1 is required")
        
        if len(value.strip()) < 3:
            raise serializers.ValidationError("Address line 1 must be at least 3 characters")
        
        return value.strip()
    
    def validate_city(self, value):
        """Validate city"""
        if not value or not value.strip():
            raise serializers.ValidationError("City is required")
        
        if len(value.strip()) < 2:
            raise serializers.ValidationError("City name must be at least 2 characters")
        
        return value.strip()
    
    def validate_state(self, value):
        """Validate state"""
        if not value or not value.strip():
            raise serializers.ValidationError("State is required")
        
        if len(value.strip()) < 2:
            raise serializers.ValidationError("State name must be at least 2 characters")
        
        return value.strip()
    
def validate(self, data):
    """
    Allow manual addresses without latitude/longitude.
    If provided, ensure both latitude and longitude are present.
    """
    latitude = data.get('latitude')
    longitude = data.get('longitude')

    if latitude is not None and longitude is None:
        raise serializers.ValidationError({"longitude": "Longitude is required if latitude is provided."})
    if longitude is not None and latitude is None:
        raise serializers.ValidationError({"latitude": "Latitude is required if longitude is provided."})

    # ✅ If both are missing (manual entry), it’s fine
    return data

