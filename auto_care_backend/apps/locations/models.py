from django.db import models
from django.conf import settings
from django.utils import timezone
import math

USER_MODEL = settings.AUTH_USER_MODEL

class ServiceArea(models.Model):
    """
    Define a service area (center coordinates + radius in km).
    Admin can create one or more service areas. When creating address we
    will validate whether it falls inside any active ServiceArea.
    """
    name = models.CharField(max_length=120)
    center_lat = models.DecimalField(max_digits=9, decimal_places=6)
    center_lng = models.DecimalField(max_digits=9, decimal_places=6)
    radius_km = models.DecimalField(max_digits=5, decimal_places=2, default=30.0)  # default 30 km
    active = models.BooleanField(default=True)

    def __str__(self):
        return f"{self.name} ({self.radius_km} km)"

    def contains(self, lat: float, lng: float) -> bool:
        """Return True if (lat,lng) in this service area"""
        return haversine_distance(float(self.center_lat), float(self.center_lng), float(lat), float(lng)) <= float(self.radius_km)


class Address(models.Model):
    """
    User-saved address
    """

    ADDRESS_TYPE_CHOICES = [
        ('home', 'Home'),
        ('work', 'Work'),
        ('other', 'Other'),
    ]

    user = models.ForeignKey(USER_MODEL, on_delete=models.CASCADE, related_name="user_addresses")  # Changed related_name
    address_type = models.CharField(max_length=20, choices=ADDRESS_TYPE_CHOICES, default='home')
    address_line1 = models.CharField(max_length=255)  # House/Flat/Building No.
    address_line2 = models.CharField(max_length=255, blank=True)  # Street/Area
    landmark = models.CharField(max_length=255, blank=True)  # Landmark
    city = models.CharField(max_length=100)
    state = models.CharField(max_length=100)
    pincode = models.CharField(max_length=10)

    # For backwards compatibility
    address_line = models.TextField(blank=True)  # Auto-generated full address
    
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True, default=0.0)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True, default=0.0)
    is_default = models.BooleanField(default=False)
    created_at = models.DateTimeField(default=timezone.now)

    class Meta:
        ordering = ("-is_default", "-created_at")
        verbose_name_plural = "Addresses"

    def save(self, *args, **kwargs):
        # Auto-generate full address line
        if not self.address_line:
            address_parts = [
                self.address_line1,
                self.address_line2,
                self.landmark,
                self.city,
                self.state,
                self.pincode
            ]
            self.address_line = ', '.join(filter(None, address_parts))
        
        # If this is set as default, unset other defaults for this user
        if self.is_default:
            Address.objects.filter(user=self.user, is_default=True).update(is_default=False)
            
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.label} - {self.address_line[:40]}"


# Utility: haversine distance in km
def haversine_distance(lat1, lon1, lat2, lon2):
    # convert to radians
    rlat1, rlon1, rlat2, rlon2 = map(math.radians, [lat1, lon1, lat2, lon2])
    dlat = rlat2 - rlat1
    dlon = rlon2 - rlon1
    a = math.sin(dlat/2)**2 + math.cos(rlat1) * math.cos(rlat2) * math.sin(dlon/2)**2
    c = 2 * math.asin(math.sqrt(a))
    R = 6371.0  # Earth radius in km
    return R * c
