from django.db.models import Q
from .models import ServiceProvider, ServiceAssignment
from apps.bookings.models import Booking
import logging
from math import radians, cos, sin, asin, sqrt

logger = logging.getLogger(__name__)


def haversine_distance(lat1, lon1, lat2, lon2):
    """Calculate distance between two GPS coordinates in kilometers"""
    # Convert decimal degrees to radians
    lon1, lat1, lon2, lat2 = map(radians, [lon1, lat1, lon2, lat2])
    
    # Haversine formula
    dlon = lon2 - lon1
    dlat = lat2 - lat1
    a = sin(dlat/2)**2 + cos(lat1) * cos(lat2) * sin(dlon/2)**2
    c = 2 * asin(sqrt(a))
    
    # Radius of earth in kilometers
    r = 6371
    
    return c * r


def find_best_provider(booking):
    """
    Smart provider assignment algorithm
    Factors: distance, availability, rating, workload
    """
    if not booking.latitude or not booking.longitude:
        logger.warning(f"Booking {booking.id} has no location data")
        return None
    
    # Get available providers
    available_providers = ServiceProvider.objects.filter(
        is_available=True,
        verification_status='verified',
        current_latitude__isnull=False,
        current_longitude__isnull=False
    )
    
    if not available_providers.exists():
        logger.warning("No available providers found")
        return None
    
    best_provider = None
    best_score = -1
    
    for provider in available_providers:
        # Calculate distance
        distance = haversine_distance(
            float(provider.current_latitude),
            float(provider.current_longitude),
            float(booking.latitude),
            float(booking.longitude)
        )
        
        # Skip if too far (> 50km)
        if distance > 50:
            continue
        
        # Calculate score (lower is better)
        distance_score = 1 / (distance + 1)  # Closer = higher score
        rating_score = provider.rating / 5.0  # Rating out of 5
        
        # Current workload (active assignments)
        active_assignments = ServiceAssignment.objects.filter(
            service_provider=provider,
            status__in=['assigned', 'accepted', 'in_progress']
        ).count()
        workload_score = 1 / (active_assignments + 1)
        
        # Weighted score
        total_score = (
            distance_score * 0.5 +  # 50% weight on distance
            rating_score * 0.3 +     # 30% weight on rating
            workload_score * 0.2     # 20% weight on workload
        )
        
        if total_score > best_score:
            best_score = total_score
            best_provider = provider
    
    if best_provider:
        logger.info(f"Best provider for booking {booking.id}: {best_provider.employee_id} (score: {best_score:.2f})")
    else:
        logger.warning(f"No suitable provider found for booking {booking.id}")
    
    return best_provider


def auto_assign_provider(booking):
    """Automatically assign a provider to a booking"""
    try:
        best_provider = find_best_provider(booking)
        
        if not best_provider:
            return None
        
        # Create assignment
        assignment = ServiceAssignment.objects.create(
            booking=booking,
            service_provider=best_provider,
            status='assigned'
        )
        
        logger.info(f"Auto-assigned booking {booking.id} to provider {best_provider.employee_id}")
        return assignment
        
    except Exception as e:
        logger.error(f"Auto-assignment failed for booking {booking.id}: {e}")
        return None
