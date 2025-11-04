from django.db import transaction
from django.utils import timezone
from datetime import timedelta
import logging
import math

from apps.service_providers.models import ServiceProvider, ServiceAssignment
from apps.bookings.models import Booking

logger = logging.getLogger(__name__)


def haversine_distance(lat1, lon1, lat2, lon2):
    """
    Calculate distance between two points using Haversine formula
    Returns distance in kilometers
    """
    R = 6371  # Earth's radius in kilometers
    
    lat1_rad = math.radians(float(lat1))
    lon1_rad = math.radians(float(lon1))
    lat2_rad = math.radians(float(lat2))
    lon2_rad = math.radians(float(lon2))
    
    dlat = lat2_rad - lat1_rad
    dlon = lon2_rad - lon1_rad
    
    a = math.sin(dlat/2)**2 + math.cos(lat1_rad) * math.cos(lat2_rad) * math.sin(dlon/2)**2
    c = 2 * math.asin(math.sqrt(a))
    
    return R * c


def calculate_eta(distance_km):
    """
    Calculate estimated arrival time based on distance
    Assumes average speed of 30 km/h in city traffic
    """
    average_speed = 30  # km/h
    time_hours = distance_km / average_speed
    time_minutes = int(time_hours * 60)
    
    # Add buffer time (5-10 minutes for preparation)
    buffer_minutes = 10
    total_minutes = time_minutes + buffer_minutes
    
    return timezone.now() + timedelta(minutes=total_minutes)


def find_nearest_available_provider(booking, max_distance_km=10):
    """
    Find nearest available provider for a booking
    
    Args:
        booking: Booking instance
        max_distance_km: Maximum distance to search (default 10km)
    
    Returns:
        tuple: (ServiceProvider instance, distance in km) or None
    """
    print("\n" + "="*70)
    print("🔍 FINDING NEAREST PROVIDER")
    print("="*70)
    
    # Check if booking has coordinates
    if not booking.latitude or not booking.longitude:
        logger.error(f"❌ Booking {booking.id} has no GPS coordinates")
        print(f"❌ Booking {booking.id} MISSING GPS")
        print(f"   Latitude: {booking.latitude}")
        print(f"   Longitude: {booking.longitude}")
        print(f"\n💡 Customer app must send GPS coordinates!")
        print("="*70 + "\n")
        return None
    
    print(f"📋 Booking Details:")
    print(f"   ID: {booking.id}")
    print(f"   Customer: {booking.user.name} ({booking.user.mobile_number})")
    print(f"   Location: {booking.latitude}, {booking.longitude}")
    print(f"   Vehicle: {booking.vehicle_type}")
    
    # Get all available, verified providers
    all_providers = ServiceProvider.objects.all()
    print(f"\n👥 Total Providers in System: {all_providers.count()}")
    
    available_providers = ServiceProvider.objects.filter(
        is_available=True,
        verification_status='verified',
        current_latitude__isnull=False,
        current_longitude__isnull=False
    )
    
    print(f"✅ Available & Verified Providers: {available_providers.count()}")
    
    if not available_providers.exists():
        logger.warning("❌ No available providers found")
        print("\n❌ NO AVAILABLE PROVIDERS")
        print("\nProvider Status Check:")
        for p in all_providers[:5]:  # Show first 5
            print(f"   {p.employee_id}: available={p.is_available}, verified={p.verification_status}, has_location={p.current_latitude is not None}")
        print("="*70 + "\n")
        return None
    
    # Log each provider's details
    print(f"\n📍 Provider Locations:")
    for provider in available_providers:
        print(f"   {provider.employee_id} ({provider.full_name})")
        print(f"      Location: {provider.current_latitude}, {provider.current_longitude}")
        print(f"      Last Update: {provider.last_location_update}")
        print(f"      Status: Available={provider.is_available}, Verified={provider.verification_status}")
    
    # Calculate distance for each provider
    provider_distances = []
    print(f"\n📏 Calculating Distances:")
    
    for provider in available_providers:
        try:
            if not provider.current_latitude or not provider.current_longitude:
                logger.warning(f"   ⚠️ Provider {provider.employee_id} has NULL location")
                print(f"   ⚠️ {provider.employee_id}: NO LOCATION DATA")
                continue
                
            distance = haversine_distance(
                booking.latitude,
                booking.longitude,
                provider.current_latitude,
                provider.current_longitude
            )
            
            print(f"   {provider.employee_id}: {distance:.2f} km", end="")
            
            if distance <= max_distance_km:
                provider_distances.append({
                    'provider': provider,
                    'distance': distance,
                    'rating': float(provider.rating)
                })
                print(f" ✅ WITHIN RANGE")
            else:
                print(f" ❌ TOO FAR (max: {max_distance_km}km)")
                
        except Exception as e:
            logger.error(f"   ❌ Error calculating distance for provider {provider.id}: {e}")
            print(f"   ❌ {provider.employee_id}: ERROR - {str(e)}")
            continue
    
    if not provider_distances:
        logger.error(f"❌ No providers found within {max_distance_km}km")
        print(f"\n❌ NO PROVIDERS WITHIN {max_distance_km}KM RADIUS")
        print(f"   Searched: {available_providers.count()} providers")
        print(f"   Found within range: 0")
        print("\n💡 Try increasing max_distance_km or wait for providers to come online")
        print("="*70 + "\n")
        return None
    
    # Sort by distance first, then by rating
    provider_distances.sort(key=lambda x: (x['distance'], -x['rating']))
    
    best_match = provider_distances[0]
    
    print(f"\n🎯 BEST MATCH FOUND:")
    print(f"   Provider: {best_match['provider'].full_name} ({best_match['provider'].employee_id})")
    print(f"   Phone: {best_match['provider'].phone_number}")
    print(f"   Distance: {best_match['distance']:.2f} km")
    print(f"   Rating: {best_match['rating']}")
    print(f"   Location: {best_match['provider'].current_latitude}, {best_match['provider'].current_longitude}")
    print("="*70 + "\n")
    
    logger.info(
        f"Found provider {best_match['provider'].employee_id} "
        f"at {best_match['distance']:.2f}km with rating {best_match['rating']}"
    )
    
    return best_match['provider'], best_match['distance']


# -----------------------------------------
# Utility: Calculate distance using Haversine formula
# -----------------------------------------
def calculate_distance(lat1, lon1, lat2, lon2):
    """Calculate distance in kilometers between two coordinates"""
    R = 6371  # Earth radius in km
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    d_phi = math.radians(lat2 - lat1)
    d_lambda = math.radians(lon2 - lon1)

    a = (
        math.sin(d_phi / 2) ** 2
        + math.cos(phi1) * math.cos(phi2) * math.sin(d_lambda / 2) ** 2
    )
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c


# -----------------------------------------
# Main Assignment Logic
# -----------------------------------------
def assign_provider_to_booking(booking: Booking):
    """
    Automatically assigns a nearby available provider to the given booking.
    """
    print("\n🚀 Starting auto-assignment process...")
    print(f"📦 Booking ID: {booking.id} | Customer: {booking.user.name}")

    try:
        # Step 1: Find all available providers
        available_providers = ServiceProvider.objects.filter(is_available=True)

        if not available_providers.exists():
            print("❌ No available providers found.")
            return None

        nearest_provider = None
        min_distance = float("inf")

        # Step 2: Find nearest provider
        for provider in available_providers:
            if not provider.current_latitude or not provider.current_longitude:
                continue

            distance = calculate_distance(
                booking.latitude,
                booking.longitude,
                provider.current_latitude,
                provider.current_longitude,
            )

            print(
                f"📍 Provider {provider.employee_id} ({provider.full_name}) "
                f"Distance: {distance:.2f} km"
            )

            if distance < min_distance:
                min_distance = distance
                nearest_provider = provider

        if not nearest_provider:
            print("❌ No provider has valid GPS location.")
            return None

        # Step 3: Create assignment
        assignment = ServiceAssignment.objects.create(
            booking=booking,
            service_provider=nearest_provider,
            status="assigned",
            assigned_at=timezone.now(),
        )

        # Step 4: Calculate ETA
        eta = datetime.now() + timedelta(minutes=random.randint(3, 10))

        # ✅ Final success print
        print(f"\n✅ Customer booking created with GPS: {booking.latitude}, {booking.longitude}")
        print(f"✅ Provider {nearest_provider.employee_id} has location: {nearest_provider.current_latitude}, {nearest_provider.current_longitude}")
        print(f"✅ Calculating distance: {min_distance:.2f} km")
        print("=" * 60)
        print("🎯 AUTO-ASSIGNMENT SUCCESSFUL")
        print(f"📋 Booking ID: {booking.id}")
        print(f"👤 Customer: {booking.user.name}")
        print(f"👨‍🔧 Assigned to: {nearest_provider.full_name} ({nearest_provider.employee_id})")
        print(f"📏 Distance: {min_distance:.2f} km")
        print(f"⏰ ETA: {eta.strftime('%I:%M %p')}")
        print("=" * 60 + "\n")

        return assignment

    except Exception as e:
        print(f"❌ Auto-assignment failed: {str(e)}")
        return None

def reassign_rejected_booking(assignment):
    """
    Reassign booking to next available provider after rejection
    
    Args:
        assignment: ServiceAssignment instance (rejected)
    
    Returns:
        New ServiceAssignment or None
    """
    try:
        booking = assignment.booking
        rejected_provider = assignment.service_provider
        
        logger.info(
            f"Reassigning booking {booking.id} after rejection by "
            f"{rejected_provider.employee_id}"
        )
        
        print("\n" + "="*70)
        print("🔄 REASSIGNING REJECTED BOOKING")
        print("="*70)
        print(f"📋 Booking ID: {booking.id}")
        print(f"❌ Rejected by: {rejected_provider.employee_id}")
        
        # Find next available provider (excluding the one who rejected)
        available_providers = ServiceProvider.objects.filter(
            is_available=True,
            verification_status='verified',
            current_latitude__isnull=False,
            current_longitude__isnull=False
        ).exclude(id=rejected_provider.id)
        
        print(f"🔍 Alternative providers available: {available_providers.count()}")
        
        if not available_providers.exists():
            logger.error(f"No other providers available for booking {booking.id}")
            print("❌ NO ALTERNATIVE PROVIDERS AVAILABLE")
            print("="*70 + "\n")
            booking.status = 'pending'
            booking.save(update_fields=['status'])
            return None
        
        # Find nearest from remaining providers
        result = find_nearest_available_provider(booking)
        
        if not result:
            logger.error(f"Could not find alternative provider for booking {booking.id}")
            print("❌ NO SUITABLE ALTERNATIVE FOUND")
            print("="*70 + "\n")
            return None
        
        provider, distance = result
        eta = calculate_eta(distance)
        
        # Create new assignment
        new_assignment = ServiceAssignment.objects.create(
            booking=booking,
            service_provider=provider,
            status='assigned',
            estimated_arrival_time=eta
        )
        
        booking.status = 'confirmed'
        booking.save(update_fields=['status'])
        
        logger.info(
            f"✅ Reassignment successful: Booking {booking.id} → "
            f"Provider {provider.employee_id}"
        )
        
        print(f"\n✅ REASSIGNED TO: {provider.full_name} ({provider.employee_id})")
        print(f"   Distance: {distance:.2f} km")
        print(f"   ETA: {eta.strftime('%I:%M %p')}")
        print("="*70 + "\n")
        
        return new_assignment
        
    except Exception as e:
        logger.error(f"Error reassigning booking: {e}")
        print(f"❌ REASSIGNMENT ERROR: {str(e)}")
        return None