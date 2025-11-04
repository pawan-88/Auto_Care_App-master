from django.db import models
from django.conf import settings
from django.core.validators import MinValueValidator, MaxValueValidator
from django.utils import timezone

# -------------------
# Service Provider Model
# -------------------
class ServiceProvider(models.Model):
    SPECIALIZATION_CHOICES = [
        ('general', 'General Mechanic'),
        ('car_specialist', 'Car Specialist'),
        ('bike_specialist', 'Bike Specialist'),
        ('electrician', 'Auto Electrician'),
        ('painter', 'Auto Painter'),
    ]
    
    VERIFICATION_STATUS_CHOICES = [
        ('pending', 'Pending Verification'),
        ('verified', 'Verified'),
        ('rejected', 'Rejected'),
        ('suspended', 'Suspended'),
    ]
    
    # Link to User model
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='provider_profile'
    )
    
    # Professional Information
    employee_id = models.CharField(max_length=20, unique=True, help_text="Unique employee ID")
    full_name = models.CharField(max_length=255)
    phone_number = models.CharField(max_length=15)
    email = models.EmailField(blank=True, null=True)
    
    # Specialization
    specialization = models.CharField(
        max_length=30,
        choices=SPECIALIZATION_CHOICES,
        default='general'
    )
    experience_years = models.PositiveIntegerField(default=0)
    
    # Location & Availability
    service_areas = models.ManyToManyField(
        'locations.ServiceArea',
        related_name='providers',
        help_text="Service areas this provider covers"
    )
    current_latitude = models.DecimalField(
        max_digits=9,
        decimal_places=6,
        null=True,
        blank=True,
        help_text="Current GPS latitude"
    )
    current_longitude = models.DecimalField(
        max_digits=9,
        decimal_places=6,
        null=True,
        blank=True,
        help_text="Current GPS longitude"
    )
    is_available = models.BooleanField(default=True, help_text="Currently available for jobs")
    
    # Verification & Status
    verification_status = models.CharField(
        max_length=20,
        choices=VERIFICATION_STATUS_CHOICES,
        default='pending'
    )
    verification_documents = models.JSONField(
        default=dict,
        help_text="Stored document URLs and metadata"
    )
    background_check_completed = models.BooleanField(default=False)
    
    # Performance Metrics
    rating = models.DecimalField(
        max_digits=3,
        decimal_places=2,
        default=0.0,
        validators=[MinValueValidator(0.0), MaxValueValidator(5.0)]
    )
    total_jobs_completed = models.PositiveIntegerField(default=0)
    total_earnings = models.DecimalField(max_digits=10, decimal_places=2, default=0.0)
    
    # Timestamps
    joined_date = models.DateField(auto_now_add=True)
    last_location_update = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        indexes = [
            models.Index(fields=['verification_status']),
            models.Index(fields=['is_available']),
            models.Index(fields=['current_latitude', 'current_longitude']),
        ]
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.full_name} ({self.employee_id}) - {self.get_specialization_display()}"
    
    def update_location(self, latitude, longitude):
        """Update provider's current location"""
        self.current_latitude = latitude
        self.current_longitude = longitude
        self.last_location_update = timezone.now()
        self.save(update_fields=['current_latitude', 'current_longitude', 'last_location_update'])


# -------------------
# Service Assignment Model
# -------------------
class ServiceAssignment(models.Model):
    ASSIGNMENT_STATUS_CHOICES = [
        ('pending', 'Pending Assignment'),
        ('assigned', 'Assigned to Provider'),
        ('accepted', 'Accepted by Provider'),
        ('rejected', 'Rejected by Provider'),
        ('en_route', 'Provider En Route'),
        ('in_progress', 'Service In Progress'),
        ('completed', 'Service Completed'),
        ('cancelled', 'Cancelled'),
    ]
    
    # Relationships
    booking = models.OneToOneField(
        'bookings.Booking',
        on_delete=models.CASCADE,
        related_name='assignment'
    )
    service_provider = models.ForeignKey(
        ServiceProvider,
        on_delete=models.SET_NULL,
        null=True,
        related_name='assignments'
    )
    
    # Assignment Details
    status = models.CharField(
        max_length=20,
        choices=ASSIGNMENT_STATUS_CHOICES,
        default='pending'
    )
    assigned_at = models.DateTimeField(auto_now_add=True)
    accepted_at = models.DateTimeField(null=True, blank=True)
    rejected_at = models.DateTimeField(null=True, blank=True)
    started_at = models.DateTimeField(null=True, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    cancelled_at = models.DateTimeField(null=True, blank=True)
    
    # Time Estimates
    estimated_arrival_time = models.DateTimeField(null=True, blank=True)
    actual_arrival_time = models.DateTimeField(null=True, blank=True)
    estimated_completion_time = models.DateTimeField(null=True, blank=True)
    
    # Notes
    provider_notes = models.TextField(blank=True, help_text="Provider's notes about the job")
    rejection_reason = models.TextField(blank=True, help_text="Reason for rejection")

    class Meta:
        indexes = [
            models.Index(fields=['status']),
            models.Index(fields=['booking']),
            models.Index(fields=['service_provider', 'status']),
        ]
        ordering = ['-assigned_at']

    def __str__(self):
        return f"Assignment #{self.id} - Booking #{self.booking.id} → {self.service_provider}"
    
    def accept(self):
        """Provider accepts the job"""
        self.status = 'accepted'
        self.accepted_at = timezone.now()
        self.save()
    
    def reject(self, reason=""):
        """Provider rejects the job"""
        self.status = 'rejected'
        self.rejected_at = timezone.now()
        self.rejection_reason = reason
        self.save()
    
    def start_service(self):
        """Mark service as started"""
        self.status = 'in_progress'
        self.started_at = timezone.now()
        self.save()
    
    def complete_service(self):
        """Mark service as completed"""
        self.status = 'completed'
        self.completed_at = timezone.now()
        self.booking.status = 'completed'
        self.booking.save()
        
        # Update provider stats
        self.service_provider.total_jobs_completed += 1
        self.service_provider.save(update_fields=['total_jobs_completed'])
        self.save()
