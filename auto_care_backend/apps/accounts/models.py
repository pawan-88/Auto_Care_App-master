from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.db import models
from django.utils import timezone
from django.core.validators import MinValueValidator, MaxValueValidator


# -------------------
# Custom User Manager
# -------------------
class UserManager(BaseUserManager):
    def create_user(self, mobile_number, password=None, **extra_fields):
        if not mobile_number:
            raise ValueError('Mobile number is required')
        user = self.model(mobile_number=mobile_number, **extra_fields)
        if password:
            user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, mobile_number, password, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        return self.create_user(mobile_number, password, **extra_fields)

# -------------------
# Custom User Model
# -------------------
class User(AbstractBaseUser, PermissionsMixin):
    mobile_number = models.CharField(max_length=15, unique=True)
    name = models.CharField(max_length=150, blank=True)
    email = models.EmailField(blank=True, null=True)
    address = models.TextField(blank=True, null=True)
    vehicle = models.CharField(max_length=150, blank=True, null=True)

    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)

    USERNAME_FIELD = 'mobile_number'
    REQUIRED_FIELDS = []

    objects = UserManager()

    class Meta:
        indexes = [
            models.Index(fields=['mobile_number']),
        ]

    def __str__(self):
        return self.mobile_number

# -------------------
# OTP Model
# -------------------
class OTP(models.Model):
    mobile_number = models.CharField(max_length=15)
    otp = models.CharField(max_length=6)
    created_at = models.DateTimeField(default=timezone.now)
    is_verified = models.BooleanField(default=False)
    attempts = models.IntegerField(default=0)

    class Meta:
        indexes = [
            models.Index(fields=['mobile_number', 'created_at']),
            models.Index(fields=['mobile_number', 'is_verified']),
        ]

    def __str__(self):
        return f"{self.mobile_number} - {self.otp} ({'Verified' if self.is_verified else 'Pending'})"


# -------------------
# Address Model
# -------------------
class Address(models.Model):
    ADDRESS_TYPE_CHOICES = [
        ('home', 'Home'),
        ('work', 'Work'),
        ('other', 'Other'),
    ]
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='addresses')
    address_type = models.CharField(max_length=10, choices=ADDRESS_TYPE_CHOICES, default='home')
    address_line1 = models.CharField(max_length=255)
    address_line2 = models.CharField(max_length=255, blank=True, null=True)
    landmark = models.CharField(max_length=255, blank=True, null=True)
    city = models.CharField(max_length=100)
    state = models.CharField(max_length=100)
    pincode = models.CharField(max_length=10)
    
    # GPS Coordinates
    latitude = models.DecimalField(
        max_digits=10, 
        decimal_places=8,
        validators=[MinValueValidator(-90), MaxValueValidator(90)],
        null=True,
        blank=True
    )
    longitude = models.DecimalField(
        max_digits=11, 
        decimal_places=8,
        validators=[MinValueValidator(-180), MaxValueValidator(180)],
        null=True,
        blank=True
    )
    
    is_default = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-is_default', '-created_at']
        verbose_name_plural = 'Addresses'
        indexes = [
            models.Index(fields=['user', 'is_default']),
        ]
    
    def __str__(self):
        return f"{self.get_address_type_display()} - {self.user.mobile_number}"
    
    def save(self, *args, **kwargs):
        # If this is set as default, unset other defaults for this user
        if self.is_default:
            Address.objects.filter(user=self.user, is_default=True).update(is_default=False)
        super().save(*args, **kwargs)
    
    def get_full_address(self):
        """Return formatted full address"""
        parts = [
            self.address_line1,
            self.address_line2,
            self.landmark,
            self.city,
            self.state,
            self.pincode
        ]
        return ', '.join(filter(None, parts))