from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from apps.accounts.models import User, OTP
from datetime import timedelta
from rest_framework.permissions import AllowAny, IsAuthenticated
from django.utils import timezone
from rest_framework_simplejwt.tokens import RefreshToken
from apps.accounts.api.serializers import UserProfileSerializer
from apps.accounts.utils import generate_otp, normalize_mobile_number, validate_mobile_number
import logging
from apps.locations.models import Address
from apps.locations.api.serializers import AddressSerializer, ServiceAreaSerializer
# from apps.accounts.models import Address
# from serializers import AddressSerializer

logger = logging.getLogger(__name__)

# -------------------
# Send OTP API
# -------------------
class SendOTPView(APIView):
    permission_classes = [AllowAny]
    OTP_EXPIRY_MINUTES = 5
    OTP_COOLDOWN_SECONDS = 60  # Minimum time before requesting a new OTP
    
    def post(self, request):
        logger.info(f"OTP request received from IP: {request.META.get('REMOTE_ADDR')}")
        
        mobile_number_raw = request.data.get("mobile_number", "").strip()
        
        # Normalize mobile number
        mobile_number = normalize_mobile_number(mobile_number_raw)
        
        # Validate mobile number
        is_valid, error_message = validate_mobile_number(mobile_number)
        if not is_valid:
            logger.warning(f"Invalid mobile number format: {mobile_number_raw}")
            return Response(
                {"error": error_message},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Rate limiting - check last OTP request
        last_otp = OTP.objects.filter(mobile_number=mobile_number).order_by('-created_at').first()
        if last_otp:
            elapsed_seconds = (timezone.now() - last_otp.created_at).total_seconds()
            if elapsed_seconds < self.OTP_COOLDOWN_SECONDS:
                wait_time = int(self.OTP_COOLDOWN_SECONDS - elapsed_seconds)
                logger.warning(f"Rate limit hit for {mobile_number}. Wait time: {wait_time}s")
                return Response(
                    {"error": f"Please wait {wait_time} seconds before requesting a new OTP."},
                    status=status.HTTP_429_TOO_MANY_REQUESTS
                )
        
        # Delete old unverified OTPs for this number
        OTP.objects.filter(mobile_number=mobile_number, is_verified=False).delete()
        
        # Create or get user
        user, created = User.objects.get_or_create(mobile_number=mobile_number)
        if created:
            logger.info(f"New user created: {user.mobile_number}")
        
        # Generate secure OTP
        otp_code = generate_otp()
        otp_obj = OTP.objects.create(mobile_number=mobile_number, otp=otp_code)
        
        # TODO: Integrate real SMS sending here (Twilio/MSG91)
        logger.info(f"OTP generated for {mobile_number}: {otp_code}")  # Remove in production
        print(f"🔐 OTP for {mobile_number} is {otp_code}")  # For development only
        
        return Response({
            "message": "OTP sent successfully",
            "mobile_number": mobile_number  # Send back normalized number
        })


# -------------------
# Verify OTP API
# -------------------
class VerifyOTPView(APIView):
    permission_classes = [AllowAny]
    MAX_OTP_ATTEMPTS = 3

    def post(self, request):
        mobile_number_raw = request.data.get("mobile_number", "").strip()
        otp_input = request.data.get("otp", "").strip()
        
        # Normalize mobile number
        mobile_number = normalize_mobile_number(mobile_number_raw)
        
        # Validate mobile number
        is_valid, error_message = validate_mobile_number(mobile_number)
        if not is_valid:
            logger.warning(f"Verify OTP: Invalid mobile format: {mobile_number_raw}")
            return Response(
                {"error": error_message},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Validate OTP format
        if not otp_input or not otp_input.isdigit() or len(otp_input) != 6:
            logger.warning(f"Invalid OTP format from {mobile_number}")
            return Response(
                {"error": "Invalid OTP format. Must be a 6-digit number."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Fetch latest unverified OTP
        otp_obj = OTP.objects.filter(
            mobile_number=mobile_number, 
            is_verified=False
        ).order_by('-created_at').first()
        
        if not otp_obj:
            logger.warning(f"No valid OTP found for {mobile_number}")
            return Response(
                {"error": "Invalid or expired OTP. Please request a new one."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Check expiry (5 minutes)
        if timezone.now() - otp_obj.created_at > timedelta(minutes=5):
            otp_obj.delete()
            logger.info(f"Expired OTP deleted for {mobile_number}")
            return Response(
                {"error": "OTP expired. Please request a new one."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Check max attempts (brute force protection)
        if otp_obj.attempts >= self.MAX_OTP_ATTEMPTS:
            otp_obj.delete()
            logger.warning(f"Max OTP attempts exceeded for {mobile_number}")
            return Response(
                {"error": "Too many failed attempts. Please request a new OTP."},
                status=status.HTTP_429_TOO_MANY_REQUESTS
            )
        
        # Verify OTP
        if otp_obj.otp != otp_input:
            otp_obj.attempts += 1
            otp_obj.save()
            remaining = self.MAX_OTP_ATTEMPTS - otp_obj.attempts
            logger.warning(f"Invalid OTP attempt for {mobile_number}. Remaining: {remaining}")
            return Response(
                {"error": f"Invalid OTP. {remaining} attempt(s) remaining."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # OTP is valid - mark as verified
        otp_obj.is_verified = True
        otp_obj.save()
        
        # Get or create user
        user, created = User.objects.get_or_create(mobile_number=mobile_number)
        
        # Delete verified OTP
        otp_obj.delete()
        
        # Generate JWT tokens
        refresh = RefreshToken.for_user(user)
        
        logger.info(f"Successful login for {mobile_number} (New user: {created})")
        
        return Response({
            "refresh": str(refresh),
            "access": str(refresh.access_token),
            "is_new_user": created,
            "user": {
                "mobile_number": user.mobile_number,
                "name": user.name,
                "email": user.email
            }
        })


# -------------------
# User Profile API
# -------------------
class UserProfileView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        serializer = UserProfileSerializer(request.user)
        logger.info(f"Profile fetched for {request.user.mobile_number}")
        return Response(serializer.data)

    def put(self, request):
        serializer = UserProfileSerializer(request.user, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            logger.info(f"Profile updated for {request.user.mobile_number}")
            return Response(serializer.data)
        logger.warning(f"Profile update failed for {request.user.mobile_number}: {serializer.errors}")
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    def patch(self, request):
        """Allow partial updates via PATCH"""
        return self.put(request)
    

    # -------------------
# Address List & Create API
# -------------------
class AddressListCreateView(APIView):
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        """Get all addresses for logged-in user"""
        addresses = Address.objects.filter(user=request.user)
        serializer = AddressSerializer(addresses, many=True)
        logger.info(f"Addresses listed for user {request.user.mobile_number}: {addresses.count()} addresses")
        
        # CRITICAL: Always return a list, even if empty
        return Response(serializer.data if serializer.data else [], status=status.HTTP_200_OK)
    
    def post(self, request):
        """Create new address"""
        logger.info(f"Address creation request from {request.user.mobile_number}: {request.data}")
        
        serializer = AddressSerializer(data=request.data)
        if serializer.is_valid():
            address = serializer.save(user=request.user)
            logger.info(f"Address created: {address.id} for user {request.user.mobile_number}")
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        
        logger.warning(f"Address creation failed for {request.user.mobile_number}: {serializer.errors}")
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# -------------------
# Address Detail, Update, Delete API
# -------------------
class AddressDetailView(APIView):
    permission_classes = [IsAuthenticated]
    
    def get_object(self, pk, user):
        try:
            return Address.objects.get(pk=pk, user=user)
        except Address.DoesNotExist:
            return None
    
    def get(self, request, pk):
        """Get single address"""
        address = self.get_object(pk, request.user)
        if not address:
            return Response(
                {"error": "Address not found"},
                status=status.HTTP_404_NOT_FOUND
            )
        serializer = AddressSerializer(address)
        return Response(serializer.data)
    
    def put(self, request, pk):
        """Update address (full update)"""
        address = self.get_object(pk, request.user)
        if not address:
            return Response(
                {"error": "Address not found"},
                status=status.HTTP_404_NOT_FOUND
            )
        
        serializer = AddressSerializer(address, data=request.data)
        if serializer.is_valid():
            serializer.save()
            logger.info(f"Address {pk} updated by user {request.user.mobile_number}")
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    def patch(self, request, pk):
        """Update address (partial update)"""
        address = self.get_object(pk, request.user)
        if not address:
            return Response(
                {"error": "Address not found"},
                status=status.HTTP_404_NOT_FOUND
            )
        
        serializer = AddressSerializer(address, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            logger.info(f"Address {pk} partially updated by user {request.user.mobile_number}")
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    def delete(self, request, pk):
        """Delete address"""
        address = self.get_object(pk, request.user)
        if not address:
            return Response(
                {"error": "Address not found"},
                status=status.HTTP_404_NOT_FOUND
            )
        
        address_id = address.id
        address.delete()
        logger.info(f"Address {address_id} deleted by user {request.user.mobile_number}")
        return Response(
            {"message": "Address deleted successfully"},
            status=status.HTTP_200_OK
        )


# -------------------
# Set Default Address API
# -------------------
class SetDefaultAddressView(APIView):
    permission_classes = [IsAuthenticated]
    
    def post(self, request, pk):
        """Set an address as default"""
        try:
            address = Address.objects.get(pk=pk, user=request.user)
        except Address.DoesNotExist:
            return Response(
                {"error": "Address not found"},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Unset all other defaults
        Address.objects.filter(user=request.user).update(is_default=False)
        
        # Set this as default
        address.is_default = True
        address.save()
        
        logger.info(f"Address {pk} set as default by user {request.user.mobile_number}")
        
        serializer = AddressSerializer(address)
        return Response(serializer.data)