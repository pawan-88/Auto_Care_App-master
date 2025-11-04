from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from .models import User, OTP


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    list_display = ['mobile_number', 'name', 'email', 'is_staff', 'is_active']
    list_filter = ['is_staff', 'is_active']
    search_fields = ['mobile_number', 'name', 'email']
    ordering = ['-id']
    
    fieldsets = (
        (None, {'fields': ('mobile_number', 'password')}),
        ('Personal Info', {'fields': ('name', 'email', 'address', 'vehicle')}),
        ('Permissions', {'fields': ('is_active', 'is_staff', 'is_superuser', 'groups', 'user_permissions')}),
    )
    
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('mobile_number', 'password1', 'password2', 'is_staff', 'is_active')}
        ),
    )
    
    filter_horizontal = ('groups', 'user_permissions',)


@admin.register(OTP)
class OTPAdmin(admin.ModelAdmin):
    list_display = ['mobile_number', 'get_otp', 'is_verified', 'get_attempts', 'created_at']
    list_filter = ['is_verified', 'created_at']
    search_fields = ['mobile_number', 'otp']
    ordering = ['-created_at']
    readonly_fields = ['created_at']

    def has_add_permission(self, request):
        # Prevent manual OTP creation from admin
        return False

    def get_otp(self, obj):
        return getattr(obj, 'otp', 'N/A')
    get_otp.short_description = 'OTP'

    def get_attempts(self, obj):
        return getattr(obj, 'attempts', 'N/A')
    get_attempts.short_description = 'Attempts'
    

    # @admin.register(Address)
    # class AddressAdmin(admin.ModelAdmin):
    #     list_display = ['id', 'user', 'address_type', 'city', 'state', 'pincode', 'is_default', 'created_at']
    #     list_filter = ['address_type', 'is_default', 'city', 'state']
    #     search_fields = ['user__mobile_number', 'user__name', 'address_line1', 'city', 'pincode']
    #     ordering = ['-created_at']
    #     readonly_fields = ['created_at', 'updated_at']
    
    #     fieldsets = (
    #         ('User Information', {
    #             'fields': ('user', 'address_type', 'is_default')
    #         }),
    #         ('Address Details', {
    #             'fields': ('address_line1', 'address_line2', 'landmark', 'city', 'state', 'pincode')
    #         }),
    #         ('Location Coordinates', {
    #             'fields': ('latitude', 'longitude'),
    #             'classes': ('collapse',)
    #         }),
    #         ('Timestamps', {
    #             'fields': ('created_at', 'updated_at'),
    #             'classes': ('collapse',)
    #         }),
    #     )