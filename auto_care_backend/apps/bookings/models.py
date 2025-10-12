from django.db import models
from django.conf import settings
from datetime import date as date_type

class Booking(models.Model):
    VEHICLE_CHOICES = [
        ("car", "Car"),
        ("bike", "Bike"),
    ]

    STATUS_CHOICES = [
        ("pending", "Pending"),
        ("confirmed", "Confirmed"),
        ("completed", "Completed"),
        ("cancelled", "Cancelled"),
    ]

    # Existing fields
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    vehicle_type = models.CharField(max_length=10, choices=VEHICLE_CHOICES)
    date = models.DateField()
    time_slot = models.CharField(max_length=50)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default="pending")
    created_at = models.DateTimeField(auto_now_add=True)
    notes = models.TextField(blank=True, null=True)
    
    # 🆕 NEW LOCATION FIELDS FOR FRONTEND INTEGRATION
    # GPS coordinates for service location
    latitude = models.DecimalField(
        max_digits=9, 
        decimal_places=6,  # ✅ Max 6 decimal places
        null=True, 
        blank=True
    )
    longitude = models.DecimalField(
        max_digits=9, 
        decimal_places=6,  # ✅ Max 6 decimal places
        null=True, 
        blank=True
    )
    
    # Human-readable address
    service_address = models.TextField(
        help_text="Full address text for service location"
    )
    
    # Optional reference to saved address
    address = models.ForeignKey(
        'locations.Address',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        help_text="Reference to user's saved address (if used)"
    )

    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user', 'date']),
            models.Index(fields=['status', 'created_at']),
            models.Index(fields=['latitude', 'longitude']),  # 🆕 Location index
        ]

    def __str__(self):
        return f"{self.user} - {self.vehicle_type} on {self.date} at {self.time_slot}"

    def can_cancel(self):
        """Check if booking can be cancelled"""
        from django.utils import timezone
        from datetime import timedelta
        
        if self.status in ['completed', 'cancelled']:
            return False
        
        # Can't cancel if service is today or in the past
        today = timezone.now().date()
        if self.date <= today:
            return False
            
        return True

    def cancel(self):
        """Cancel the booking if possible"""
        if self.can_cancel():
            self.status = 'cancelled'
            self.save()
            return True
        return False
    
    # 🆕 NEW LOCATION-RELATED METHODS
    def is_in_service_area(self):
        """Check if booking location is within any active service area"""
        from apps.locations.models import ServiceArea
        
        active_areas = ServiceArea.objects.filter(active=True)
        return any(
            area.contains(float(self.latitude), float(self.longitude)) 
            for area in active_areas
        )
    
    def distance_from_center(self):
        """Get distance from nearest service area center"""
        from apps.locations.models import ServiceArea, haversine_distance
        
        active_areas = ServiceArea.objects.filter(active=True)
        if not active_areas.exists():
            return None
            
        distances = []
        for area in active_areas:
            distance = haversine_distance(
                float(area.center_lat), float(area.center_lng),
                float(self.latitude), float(self.longitude)
            )
            distances.append(distance)
            
        return min(distances) if distances else None
    
    def get_location_summary(self):
        """Get a summary of the booking location"""
        summary = {
            'coordinates': f"{self.latitude}, {self.longitude}",
            'address': self.service_address,
            'in_service_area': self.is_in_service_area(),
        }
        
        if self.address:
            summary['saved_address'] = {
                'id': self.address.id,
                'label': self.address.label
            }
            
        return summary

    def save(self, *args, **kwargs):
        """Override save to add location validation"""
        # Validate service area coverage (optional - can be disabled)
        if not self.is_in_service_area():
            # Log warning but don't block save
            import logging
            logger = logging.getLogger(__name__)
            logger.warning(
                f"Booking {self.id} created outside service area: "
                f"{self.latitude}, {self.longitude}"
            )
        
        super().save(*args, **kwargs)