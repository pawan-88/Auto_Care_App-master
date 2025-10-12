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
    user = models.ForeignKey(USER_MODEL, on_delete=models.CASCADE, related_name="addresses")
    label = models.CharField(max_length=100, default="Home")  # Home/Work/Other
    address_line = models.TextField()
    latitude = models.DecimalField(max_digits=9, decimal_places=6)
    longitude = models.DecimalField(max_digits=9, decimal_places=6)
    is_default = models.BooleanField(default=False)
    created_at = models.DateTimeField(default=timezone.now)

    class Meta:
        ordering = ("-is_default", "-created_at")

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
