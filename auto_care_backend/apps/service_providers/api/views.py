from rest_framework import status, permissions
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.decorators import api_view, permission_classes
from django.shortcuts import get_object_or_404
from django.db import transaction
from django.utils import timezone
from django.conf import settings

from ..models import ServiceProvider, ServiceAssignment
from .serializers import (
    ServiceProviderSerializer,
    ServiceProviderRegistrationSerializer,
    ServiceAssignmentSerializer,
    AssignmentActionSerializer,
    LocationUpdateSerializer
)
from apps.accounts.models import User
from apps.bookings.models import Booking
from apps.bookings.services.assignment_service import reassign_rejected_booking

import logging
import random
import json

logger = logging.getLogger(__name__)


def send_customer_notification(user, title: str, message: str, payload: dict | None = None):
    """
    Lightweight notification helper.
    Currently prints to console (suitable for dev). Replace with FCM or other push provider.
    """
    try:
        print("\n" + "="*60)
        print("🔔 CUSTOMER NOTIFICATION (placeholder)")
        print(f"To: {user.mobile_number} / {user.email or 'no-email'}")
        print(f"Title: {title}")
        print(f"Message: {message}")
        if payload:
            print("Payload:", json.dumps(payload))
        print("="*60 + "\n")

        # Example: if you have FCM server key and pyfcm installed, you can send here.
        # from pyfcm import FCMNotification
        # push_service = FCMNotification(api_key=settings.FCM_SERVER_KEY)
        # if user.profile.push_token:
        #     result = push_service.notify_single_device(registration_id=user.profile.push_token, message_title=title, message_body=message, data_message=payload)
        #     logger.info("FCM result: %s", result)

    except Exception as e:
        logger.exception("Failed to send customer notification: %s", e)


# -------------------
# Provider Registration
# -------------------
class ProviderRegistrationView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        """Register a new service provider"""
        serializer = ServiceProviderRegistrationSerializer(data=request.data)

        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        try:
            with transaction.atomic():
                # Create user account
                user = User.objects.create(
                    mobile_number=serializer.validated_data['mobile_number'],
                    name=serializer.validated_data['full_name'],
                    email=serializer.validated_data.get('email', ''),
                    user_type='provider',
                    is_verified=False  # Important: Set to False initially
                )

                # Generate employee ID
                employee_id = f"SP{user.id:06d}"

                # Create provider profile
                provider = ServiceProvider.objects.create(
                    user=user,
                    employee_id=employee_id,
                    full_name=serializer.validated_data['full_name'],
                    phone_number=serializer.validated_data['mobile_number'],
                    email=serializer.validated_data.get('email', ''),
                    specialization=serializer.validated_data['specialization'],
                    experience_years=serializer.validated_data['experience_years'],
                )

                # Generate and send OTP
                from apps.accounts.models import OTP

                otp_code = str(random.randint(100000, 999999))

                # Delete any existing OTPs for this number
                OTP.objects.filter(mobile_number=user.mobile_number).delete()

                # Create new OTP
                OTP.objects.create(
                    mobile_number=user.mobile_number,
                    otp_code=otp_code
                )

                # ✅ Print OTP clearly in console
                print("\n" + "="*60)
                print(f"🔐 REGISTRATION OTP FOR: {user.mobile_number}")
                print(f"📱 OTP CODE: {otp_code}")
                print(f"👤 Provider: {provider.full_name} ({employee_id})")
                print("="*60 + "\n")

                logger.info(f"New provider registered: {employee_id} - {provider.full_name}")

                return Response({
                    'message': 'Provider registered successfully. OTP sent to your mobile. (DEV only)',
                    'mobile_number': user.mobile_number,
                    'employee_id': employee_id,
                    'otp': otp_code  # ⚠️ Remove in production
                }, status=status.HTTP_201_CREATED)

        except Exception as e:
            logger.exception("Provider registration failed: %s", e)
            return Response({
                'error': f'Registration failed: {str(e)}'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# -------------------
# Provider Login (Send OTP)
# -------------------
class ProviderLoginView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        """Send OTP to provider's mobile number"""
        mobile_number = request.data.get('mobile_number')

        if not mobile_number:
            return Response({
                'error': 'Mobile number is required'
            }, status=status.HTTP_400_BAD_REQUEST)

        try:
            # Check if provider exists
            user = User.objects.get(mobile_number=mobile_number, user_type='provider')
            provider = ServiceProvider.objects.get(user=user)

            # Generate OTP
            from apps.accounts.models import OTP

            otp_code = str(random.randint(100000, 999999))

            # Delete existing OTPs for this number
            OTP.objects.filter(mobile_number=mobile_number).delete()

            # Create new OTP
            OTP.objects.create(
                mobile_number=mobile_number,
                otp_code=otp_code
            )

            # ✅ Print OTP clearly in console
            print("\n" + "="*60)
            print(f"🔐 LOGIN OTP FOR: {mobile_number}")
            print(f"📱 OTP CODE: {otp_code}")
            print(f"👤 Provider: {provider.full_name} ({provider.employee_id})")
            print("="*60 + "\n")

            logger.info(f"Login OTP generated for provider {mobile_number}")

            return Response({
                'message': 'OTP sent successfully',
                'mobile_number': mobile_number,
                'otp': otp_code  # ⚠️ Remove in production
            }, status=status.HTTP_200_OK)

        except User.DoesNotExist:
            return Response({
                'error': 'Provider not found. Please register first.'
            }, status=status.HTTP_404_NOT_FOUND)
        except ServiceProvider.DoesNotExist:
            return Response({
                'error': 'Provider profile not found'
            }, status=status.HTTP_404_NOT_FOUND)


# -------------------
# Provider OTP Verification
# -------------------
class ProviderVerifyOTPView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        """Verify OTP and return JWT tokens"""
        mobile_number = request.data.get('mobile_number', '').strip()
        otp_code = request.data.get('otp', '').strip()

        # ✅ Debug logging
        print("\n" + "="*60)
        print(f"🔍 OTP VERIFICATION ATTEMPT")
        print(f"📱 Mobile: {mobile_number}")
        print(f"🔑 OTP Received: {otp_code}")
        print("="*60 + "\n")

        if not mobile_number or not otp_code:
            return Response({
                'error': 'Mobile number and OTP are required'
            }, status=status.HTTP_400_BAD_REQUEST)

        try:
            from apps.accounts.models import OTP

            # Try to get OTP object
            try:
                otp = OTP.objects.get(mobile_number=mobile_number, otp_code=otp_code)
                print(f"✅ OTP Found in Database")
                print(f"   Created: {otp.created_at}")
                print(f"   Expires: {otp.expires_at}")
                print(f"   Is Verified: {otp.is_verified}")
            except OTP.DoesNotExist:
                print(f"❌ OTP Not Found!")
                all_otps = OTP.objects.filter(mobile_number=mobile_number)
                for o in all_otps:
                    print(f"   - OTP in DB: {o.otp_code} (Verified: {o.is_verified})")
                raise

            # Check OTP validity
            if not otp.is_valid():
                print(f"❌ OTP is invalid or expired")
                return Response({
                    'error': 'OTP has expired. Please request a new one.'
                }, status=status.HTTP_400_BAD_REQUEST)

            print(f"✅ OTP is valid!")

            # Retrieve user and provider
            user = User.objects.get(mobile_number=mobile_number, user_type='provider')
            provider = ServiceProvider.objects.get(user=user)

            print(f"✅ User found: {user.name}")
            print(f"✅ Provider found: {provider.employee_id}")

            # Mark user as verified
            if not user.is_verified:
                user.is_verified = True
                user.save(update_fields=['is_verified'])
                print(f"✅ User marked as verified")

            # Mark OTP as verified
            otp.is_verified = True
            otp.save(update_fields=['is_verified'])
            print(f"✅ OTP marked as used")

            # Generate JWT tokens
            from rest_framework_simplejwt.tokens import RefreshToken
            refresh = RefreshToken.for_user(user)

            print(f"✅ JWT tokens generated")
            print("="*60 + "\n")

            logger.info(f"Provider {provider.employee_id} logged in successfully")

            return Response({
                'message': 'Login successful',
                'access_token': str(refresh.access_token),
                'refresh_token': str(refresh),
                'user': {
                    'id': user.id,
                    'mobile_number': user.mobile_number,
                    'name': user.name,
                    'email': user.email,
                    'user_type': user.user_type,
                    'is_verified': user.is_verified
                },
                'provider': {
                    'id': provider.id,
                    'employee_id': provider.employee_id,
                    'full_name': provider.full_name,
                    'specialization': provider.specialization,
                    'rating': float(provider.rating),
                    'is_available': provider.is_available,
                    'verification_status': provider.verification_status,
                    'total_jobs_completed': provider.total_jobs_completed
                }
            }, status=status.HTTP_200_OK)

        except OTP.DoesNotExist:
            logger.warning(f"Invalid OTP attempt for {mobile_number} with otp {otp_code}")
            return Response({
                'error': 'Invalid OTP. Please check and try again.'
            }, status=status.HTTP_400_BAD_REQUEST)
        except User.DoesNotExist:
            print(f"❌ User not found for mobile: {mobile_number}")
            return Response({
                'error': 'User not found'
            }, status=status.HTTP_404_NOT_FOUND)
        except ServiceProvider.DoesNotExist:
            print(f"❌ Provider profile not found")
            return Response({
                'error': 'Provider profile not found'
            }, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            print(f"❌ Exception: {str(e)}")
            logger.exception("OTP verification failed: %s", e)
            return Response({
                'error': f'Verification failed: {str(e)}'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# -------------------
# Provider Profile Management
# -------------------
class ProviderProfileView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        """Get provider profile"""
        try:
            provider = request.user.provider_profile
            serializer = ServiceProviderSerializer(provider)
            logger.info(f"Profile fetched for provider {provider.employee_id}")
            return Response(serializer.data)
        except ServiceProvider.DoesNotExist:
            return Response({
                'error': 'Provider profile not found'
            }, status=status.HTTP_404_NOT_FOUND)

    def put(self, request):
        """Update provider profile"""
        try:
            provider = request.user.provider_profile
            serializer = ServiceProviderSerializer(provider, data=request.data, partial=True)

            if serializer.is_valid():
                serializer.save()
                logger.info(f"Profile updated for provider {provider.employee_id}")
                return Response(serializer.data)

            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        except ServiceProvider.DoesNotExist:
            return Response({
                'error': 'Provider profile not found'
            }, status=status.HTTP_404_NOT_FOUND)


# -------------------
# Available Jobs List
# -------------------
class AvailableJobsView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        """Get available jobs for provider (assigned status)"""
        try:
            provider = request.user.provider_profile

            assignments = ServiceAssignment.objects.filter(
                service_provider=provider,
                status='assigned'
            ).select_related('booking', 'booking__user').order_by('-assigned_at')

            serializer = ServiceAssignmentSerializer(assignments, many=True)
            logger.info(f"Available jobs listed for provider {provider.employee_id}: {assignments.count()} jobs")

            return Response(serializer.data)
        except ServiceProvider.DoesNotExist:
            return Response({
                'error': 'Provider profile not found'
            }, status=status.HTTP_404_NOT_FOUND)


# -------------------
# Accept/Reject Assignment
# -------------------
class AssignmentActionView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, assignment_id):
        """Accept or reject an assignment"""
        try:
            provider = request.user.provider_profile
            assignment = get_object_or_404(
                ServiceAssignment,
                id=assignment_id,
                service_provider=provider,
                status='assigned'  # Can only act on 'assigned' status
            )

            serializer = AssignmentActionSerializer(data=request.data)
            if not serializer.is_valid():
                return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

            action = serializer.validated_data['action']

            if action == 'accept':
                assignment.accept()
                # Mark associated booking as confirmed (if not already)
                try:
                    booking = assignment.booking
                    booking.status = 'confirmed'
                    booking.save(update_fields=['status'])
                except Exception:
                    logger.exception("Failed to update booking status on accept")

                logger.info(f"Assignment {assignment_id} accepted by provider {provider.employee_id}")

                # Notify customer (placeholder)
                try:
                    send_customer_notification(
                        assignment.booking.user,
                        "Your booking has been accepted",
                        f"Provider {provider.full_name} accepted your booking #{assignment.booking.id}"
                    )
                except Exception:
                    logger.exception("Failed to notify customer on accept")

                # Return updated assignment data
                serialized = ServiceAssignmentSerializer(assignment)
                return Response({
                    'message': 'Assignment accepted successfully',
                    'assignment': serialized.data
                }, status=status.HTTP_200_OK)

            else:  # reject
                reason = serializer.validated_data.get('reason', 'No reason provided')
                assignment.reject(reason)
                logger.info(
                    f"Assignment {assignment_id} rejected by provider {provider.employee_id}: {reason}"
                )

                # Notify customer (placeholder)
                try:
                    send_customer_notification(
                        assignment.booking.user,
                        "Provider rejected your booking",
                        f"Provider {provider.full_name} rejected your booking #{assignment.booking.id}. We will try to reassign."
                    )
                except Exception:
                    logger.exception("Failed to notify customer on reject")

                # Attempt reassignment
                new_assignment = reassign_rejected_booking(assignment)

                if new_assignment:
                    message = 'Assignment rejected and reassigned to another provider'
                    new_serialized = ServiceAssignmentSerializer(new_assignment)
                    return Response({
                        'message': message,
                        'new_assignment': new_serialized.data
                    }, status=status.HTTP_200_OK)
                else:
                    message = 'Assignment rejected. No other providers available.'
                    return Response({
                        'message': message
                    }, status=status.HTTP_200_OK)

        except ServiceProvider.DoesNotExist:
            return Response({
                'error': 'Provider profile not found'
            }, status=status.HTTP_404_NOT_FOUND)


# -------------------
# Start Service (mark en route)
# -------------------
@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def mark_en_route(request, assignment_id):
    """Mark that provider is on the way"""
    try:
        provider = request.user.provider_profile
        assignment = get_object_or_404(
            ServiceAssignment,
            id=assignment_id,
            service_provider=provider,
            status='accepted'
        )

        assignment.status = 'en_route'
        assignment.save(update_fields=['status'])

        logger.info(f"Provider {provider.employee_id} is en route for assignment {assignment_id}")

        # Notify customer
        try:
            send_customer_notification(
                assignment.booking.user,
                "Provider is on the way",
                f"{provider.full_name} is en route to your location for booking #{assignment.booking.id}"
            )
        except Exception:
            logger.exception("Failed to notify customer on en_route")

        return Response({
            'message': 'Marked as en route',
            'assignment_id': assignment.id,
            'status': assignment.status
        })
    except ServiceProvider.DoesNotExist:
        return Response({'error': 'Provider profile not found'}, status=status.HTTP_404_NOT_FOUND)


# -------------------
# Complete Service
# -------------------
@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def complete_service(request, assignment_id):
    """Mark service as completed"""
    try:
        provider = request.user.provider_profile
        assignment = get_object_or_404(
            ServiceAssignment,
            id=assignment_id,
            service_provider=provider,
            status='in_progress'
        )

        assignment.complete_service()
        logger.info(f"Service completed for assignment {assignment_id} by provider {provider.employee_id}")

        # Notify customer
        try:
            send_customer_notification(
                assignment.booking.user,
                "Service completed",
                f"Your booking #{assignment.booking.id} has been completed by {provider.full_name}. Thank you!"
            )
        except Exception:
            logger.exception("Failed to notify customer on complete")

        return Response({
            'message': 'Service completed successfully',
            'assignment_id': assignment.id,
            'completed_at': assignment.completed_at
        })
    except ServiceProvider.DoesNotExist:
        return Response({'error': 'Provider profile not found'}, status=status.HTTP_404_NOT_FOUND)


# -------------------
# Update Location
# -------------------
@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def update_location(request):
    """Update provider's current location"""
    try:
        provider = request.user.provider_profile

        latitude = request.data.get('latitude')
        longitude = request.data.get('longitude')

        print(f"\n📍 Location Update Request")
        print(f"   Provider: {provider.employee_id}")
        print(f"   Raw Data: {request.data}")
        print(f"   Latitude: {latitude} (type: {type(latitude).__name__})")
        print(f"   Longitude: {longitude} (type: {type(longitude).__name__})")

        if latitude is None or longitude is None:
            logger.error(f"Missing coordinates in request: {request.data}")
            return Response({
                'error': 'latitude and longitude are required',
                'received': request.data
            }, status=status.HTTP_400_BAD_REQUEST)

        try:
            lat = float(latitude)
            lng = float(longitude)

            print(f"   Converted - Lat: {lat}, Lng: {lng}")

            if not (-90 <= lat <= 90):
                return Response({
                    'error': f'Latitude must be between -90 and 90, got {lat}'
                }, status=status.HTTP_400_BAD_REQUEST)

            if not (-180 <= lng <= 180):
                return Response({
                    'error': f'Longitude must be between -180 and 180, got {lng}'
                }, status=status.HTTP_400_BAD_REQUEST)

        except (ValueError, TypeError) as e:
            logger.error(f"Invalid coordinate format: {e}")
            return Response({
                'error': f'Invalid latitude or longitude format: {str(e)}',
                'latitude_received': str(latitude),
                'longitude_received': str(longitude)
            }, status=status.HTTP_400_BAD_REQUEST)

        try:
            provider.update_location(lat, lng)

            print(f"   ✅ Location updated successfully")
            print(f"   Stored - Lat: {provider.current_latitude}, Lng: {provider.current_longitude}")
            print(f"   Last Update: {provider.last_location_update}\n")

            logger.info(
                f"Provider {provider.employee_id} location updated: "
                f"{lat}, {lng}"
            )

            return Response({
                'message': 'Location updated successfully',
                'latitude': str(provider.current_latitude),
                'longitude': str(provider.current_longitude),
                'updated_at': provider.last_location_update.isoformat() if provider.last_location_update else None
            }, status=status.HTTP_200_OK)

        except Exception as e:
            logger.exception("Database update failed: %s", e)
            return Response({
                'error': f'Failed to save location: {str(e)}'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    except ServiceProvider.DoesNotExist:
        logger.error(f"Provider profile not found for user {request.user.id}")
        return Response({
            'error': 'Provider profile not found'
        }, status=status.HTTP_404_NOT_FOUND)

    except Exception as e:
        logger.exception("Unexpected error in update_location: %s", e)
        return Response({
            'error': f'Server error: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# -------------------
# Provider Availability Toggle
# -------------------
@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def toggle_availability(request):
    """Toggle provider availability status"""
    try:
        provider = request.user.provider_profile
        provider.is_available = not provider.is_available
        provider.save(update_fields=['is_available'])

        logger.info(f"Provider {provider.employee_id} availability changed to {provider.is_available}")

        return Response({
            'message': 'Availability updated',
            'is_available': provider.is_available
        })
    except ServiceProvider.DoesNotExist:
        return Response({'error': 'Provider profile not found'}, status=status.HTTP_404_NOT_FOUND)


# -------------------
# Get New Assignments (Pending)
# -------------------
class PendingAssignmentsView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        """
        Get all pending assignments for this provider
        (status = 'assigned' only)
        """
        try:
            provider = request.user.provider_profile

            pending_assignments = (
                ServiceAssignment.objects
                .filter(service_provider=provider, status='assigned')
                .select_related('booking', 'booking__user')
                .order_by('-assigned_at')
            )

            serializer = ServiceAssignmentSerializer(pending_assignments, many=True)

            logger.info(
                f"[PendingAssignmentsView] Provider {provider.employee_id} "
                f"→ {pending_assignments.count()} pending assignments fetched."
            )

            return Response({
                'success': True,
                'count': pending_assignments.count(),
                'assignments': serializer.data
            }, status=status.HTTP_200_OK)

        except ServiceProvider.DoesNotExist:
            logger.error(f"[PendingAssignmentsView] Provider profile not found for user {request.user.id}")
            return Response({
                'success': False,
                'error': 'Provider profile not found'
            }, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            logger.exception(f"[PendingAssignmentsView] Unexpected error: {str(e)}")
            return Response({
                'success': False,
                'error': 'Something went wrong while fetching pending assignments.'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# -------------------
# Get Active Assignments (Accepted / en_route / in_progress)
# -------------------
class ActiveAssignmentView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        """
        Get provider's active + recent assignments
        Includes: accepted, en_route, in_progress, completed
        """
        try:
            provider = request.user.provider_profile

            active_assignments = (
                ServiceAssignment.objects
                .filter(
                    service_provider=provider,
                    status__in=['accepted', 'en_route', 'in_progress', 'completed']
                )
                .select_related('booking', 'booking__user')
                .order_by('-assigned_at')
            )

            serializer = ServiceAssignmentSerializer(active_assignments, many=True)

            logger.info(
                f"[ActiveAssignmentView] Provider {provider.employee_id} "
                f"→ {active_assignments.count()} active assignments fetched."
            )

            return Response({
                'success': True,
                'count': active_assignments.count(),
                'assignments': serializer.data
            }, status=status.HTTP_200_OK)

        except ServiceProvider.DoesNotExist:
            logger.error(f"[ActiveAssignmentView] Provider profile not found for user {request.user.id}")
            return Response({
                'success': False,
                'error': 'Provider profile not found'
            }, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            logger.exception(f"[ActiveAssignmentView] Unexpected error: {str(e)}")
            return Response({
                'success': False,
                'error': 'Something went wrong while fetching active assignments.'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

# -------------------
# Get History (completed/rejected/cancelled)
# -------------------
class CompletedAssignmentView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        """Get provider assignment history (completed/rejected/cancelled)"""
        try:
            provider = request.user.provider_profile

            history_assignments = ServiceAssignment.objects.filter(
                service_provider=provider,
                status__in=['completed', 'rejected', 'cancelled']
            ).select_related('booking', 'booking__user').order_by('-assigned_at')

            serializer = ServiceAssignmentSerializer(history_assignments, many=True)
            return Response({
                'count': history_assignments.count(),
                'assignments': serializer.data
            })
        except ServiceProvider.DoesNotExist:
            return Response({
                'error': 'Provider profile not found'
            }, status=status.HTTP_404_NOT_FOUND)
