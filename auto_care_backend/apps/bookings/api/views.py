from rest_framework import status, permissions
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.decorators import api_view, permission_classes
from django.db.models import Q
from ..models import Booking
from .serializers import BookingSerializer
from apps.locations.models import ServiceArea, Address
import logging
from datetime import datetime, date

logger = logging.getLogger(__name__)

class BookingListCreateView(APIView):
    """Enhanced booking list/create with location support"""
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, *args, **kwargs):
        """Get all bookings for logged-in user with location info"""
        bookings = Booking.objects.filter(user=request.user).order_by("-created_at")
        
        # Optional filtering by status
        status_filter = request.query_params.get('status')
        if status_filter:
            bookings = bookings.filter(status=status_filter)
        
        # Optional filtering by date range
        date_from = request.query_params.get('date_from')
        date_to = request.query_params.get('date_to')
        if date_from:
            try:
                date_from = datetime.strptime(date_from, '%Y-%m-%d').date()
                bookings = bookings.filter(date__gte=date_from)
            except ValueError:
                pass
        if date_to:
            try:
                date_to = datetime.strptime(date_to, '%Y-%m-%d').date()
                bookings = bookings.filter(date__lte=date_to)
            except ValueError:
                pass
        
        serializer = BookingSerializer(bookings, many=True)
        
        logger.info(f"Bookings listed for user {request.user.mobile_number}: {bookings.count()} bookings")
        
        return Response({
            'count': bookings.count(),
            'bookings': serializer.data
        })

    def post(self, request, *args, **kwargs):
        """Create new location-aware booking"""
        # Log incoming request data for debugging
        logger.info(f"Booking creation attempt by {request.user.mobile_number}: {request.data}")
        
        # Validate required location fields upfront
        required_location_fields = ['latitude', 'longitude', 'service_address']
        missing_fields = [field for field in required_location_fields if not request.data.get(field)]
        
        if missing_fields:
            return Response(
                {
                    'error': f'Missing required location fields: {", ".join(missing_fields)}',
                    'detail': 'Location information is required for all bookings.'
                },
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Create serializer with request context for user validation
        serializer = BookingSerializer(data=request.data, context={'request': request})
        
        if serializer.is_valid():
            try:
                booking = serializer.save()
                
                logger.info(
                    f"Location-aware booking created successfully: "
                    f"ID {booking.id} at {booking.service_address} "
                    f"({booking.latitude}, {booking.longitude}) "
                    f"for user {request.user.mobile_number}"
                )
                
                # Return enhanced response with location info
                response_data = serializer.data
                response_data['message'] = 'Booking created successfully'
                
                return Response(response_data, status=status.HTTP_201_CREATED)
                
            except Exception as e:
                logger.error(f"Booking creation failed for {request.user.mobile_number}: {str(e)}")
                return Response(
                    {
                        'error': 'Booking creation failed',
                        'detail': 'Please try again or contact support.'
                    },
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )
        else:
            logger.warning(f"Booking creation validation failed for {request.user.mobile_number}: {serializer.errors}")
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class BookingDetailView(APIView):
    """Enhanced booking detail view with location info"""
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self, pk, user):
        """Get booking with location data"""
        try:
            return Booking.objects.select_related('address', 'user').get(pk=pk, user=user)
        except Booking.DoesNotExist:
            return None

    def get(self, request, pk):
        """Get single booking details with location info"""
        booking = self.get_object(pk, request.user)
        if not booking:
            return Response(
                {"error": "Booking not found"},
                status=status.HTTP_404_NOT_FOUND
            )

        serializer = BookingSerializer(booking)
        return Response(serializer.data)

    def patch(self, request, pk):
        """Update booking with location validation"""
        booking = self.get_object(pk, request.user)
        if not booking:
            return Response(
                {"error": "Booking not found"},
                status=status.HTTP_404_NOT_FOUND
            )

        if booking.status in ['completed', 'cancelled']:
            return Response(
                {"error": f"Cannot update {booking.status} booking"},
                status=status.HTTP_400_BAD_REQUEST
            )

        serializer = BookingSerializer(
            booking,
            data=request.data,
            partial=True,
            context={'request': request}
        )

        if serializer.is_valid():
            updated_booking = serializer.save()
            logger.info(f"Booking {pk} updated by user {request.user.mobile_number}")
            return Response(serializer.data)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, pk):
        """Cancel booking"""
        booking = self.get_object(pk, request.user)
        if not booking:
            return Response(
                {"error": "Booking not found"},
                status=status.HTTP_404_NOT_FOUND
            )

        if booking.cancel():
            logger.info(f"Booking {pk} cancelled by user {request.user.mobile_number}")
            return Response(
                {"message": "Booking cancelled successfully"},
                status=status.HTTP_200_OK
            )
        else:
            return Response(
                {"error": "Cannot cancel this booking. It may be completed or in the past."},
                status=status.HTTP_400_BAD_REQUEST
            )

# 🆕 NEW LOCATION SERVICE ENDPOINTS FOR FRONTEND

@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def check_service_availability(request):
    """Check if location is within service area"""
    try:
        latitude = request.data.get('latitude')
        longitude = request.data.get('longitude')
        
        if latitude is None or longitude is None:
            return Response(
                {'error': 'latitude and longitude are required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        lat = float(latitude)
        lng = float(longitude)
        
        # Validate coordinate ranges
        if not (-90 <= lat <= 90) or not (-180 <= lng <= 180):
            return Response(
                {'error': 'Invalid GPS coordinates'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Check service area coverage
        active_areas = ServiceArea.objects.filter(active=True)
        
        if not active_areas.exists():
            return Response({
                'service_available': True,
                'message': 'Service available everywhere (no areas configured)'
            })
        
        # Check if location is within any active service area
        covered_areas = []
        for area in active_areas:
            if area.contains(lat, lng):
                covered_areas.append({
                    'name': area.name,
                    'distance_from_center': area.distance_from_center(lat, lng) if hasattr(area, 'distance_from_center') else 0
                })
        
        if covered_areas:
            return Response({
                'service_available': True,
                'covered_by': covered_areas,
                'message': 'Location is within our service area'
            })
        else:
            # Find nearest service area
            from apps.locations.models import haversine_distance
            nearest_areas = []
            for area in active_areas:
                distance = haversine_distance(
                    float(area.center_lat), float(area.center_lng),
                    lat, lng
                )
                nearest_areas.append({
                    'name': area.name,
                    'distance_km': round(distance, 1)
                })
            
            nearest_areas.sort(key=lambda x: x['distance_km'])
            
            return Response({
                'service_available': False,
                'nearest_areas': nearest_areas[:3],  # Show top 3 nearest
                'message': 'Location is outside our current service areas'
            })
            
    except (ValueError, TypeError):
        return Response(
            {'error': 'Invalid latitude or longitude format'},
            status=status.HTTP_400_BAD_REQUEST
        )
    except Exception as e:
        logger.error(f"Service area check failed: {str(e)}")
        return Response(
            {'error': 'Service availability check failed'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def reverse_geocode(request):
    """Simple reverse geocoding (placeholder for external service)"""
    try:
        latitude = request.data.get('latitude')
        longitude = request.data.get('longitude')
        
        if latitude is None or longitude is None:
            return Response(
                {'error': 'latitude and longitude are required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        lat = float(latitude)
        lng = float(longitude)
        
        # Placeholder response - integrate with Google Maps, MapBox, etc.
        return Response({
            'address': f"Location at {lat:.4f}, {lng:.4f}",
            'coordinates': f"{lat}, {lng}",
            'note': 'Integrate with geocoding service for detailed address'
        })
        
    except (ValueError, TypeError):
        return Response(
            {'error': 'Invalid coordinates'},
            status=status.HTTP_400_BAD_REQUEST
        )

@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def available_time_slots(request):
    """Get available time slots for a specific date"""
    date_str = request.query_params.get('date')
    
    if not date_str:
        return Response(
            {'error': 'date parameter is required (YYYY-MM-DD format)'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    try:
        booking_date = datetime.strptime(date_str, '%Y-%m-%d').date()
    except ValueError:
        return Response(
            {'error': 'Invalid date format. Use YYYY-MM-DD'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Default time slots
    all_slots = [
        "05:00 AM", "06:00 AM", "07:00 AM", "08:00 AM", "09:00 AM", "10:00 AM",
        "11:00 AM", "12:00 PM", "01:00 PM", "02:00 PM", "03:00 PM", "04:00 PM",
        "05:00 PM", "06:00 PM", "07:00 PM", "08:00 PM"
    ]
    
    # Get booked slots for the date
    booked_slots = Booking.objects.filter(
        date=booking_date,
        status__in=['pending', 'confirmed']
    ).values_list('time_slot', flat=True).distinct()
    
    available_slots = [slot for slot in all_slots if slot not in booked_slots]
    
    return Response({
        'date': date_str,
        'available_slots': available_slots,
        'booked_slots': list(booked_slots),
        'total_available': len(available_slots)
    })

@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def booking_statistics(request):
    """Get user's booking statistics with location insights"""
    user_bookings = Booking.objects.filter(user=request.user)
    
    stats = {
        'total_bookings': user_bookings.count(),
        'pending_bookings': user_bookings.filter(status='pending').count(),
        'completed_bookings': user_bookings.filter(status='completed').count(),
        'cancelled_bookings': user_bookings.filter(status='cancelled').count(),
        'unique_locations': user_bookings.values('latitude', 'longitude').distinct().count(),
        'most_used_addresses': []
    }
    
    # Get most frequently used addresses
    if user_bookings.exists():
        from django.db.models import Count
        address_usage = user_bookings.filter(
            address__isnull=False
        ).values(
            'address__id', 'address__label'
        ).annotate(
            usage_count=Count('id')
        ).order_by('-usage_count')[:5]
        
        stats['most_used_addresses'] = [
            {
                'address_id': item['address__id'],
                'label': item['address__label'],
                'usage_count': item['usage_count']
            }
            for item in address_usage
        ]
    
    return Response(stats)