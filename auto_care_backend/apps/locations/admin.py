from django.contrib import admin
from django.utils.html import format_html
from .models import Address, ServiceArea

@admin.register(Address)
class AddressAdmin(admin.ModelAdmin):
    """Basic address admin"""
    
    list_display = [
        'label', 'user_display', 'address_line_short', 'coordinates_display', 
        'is_default', 'created_at'
    ]
    
    list_filter = [
        'is_default', 'created_at',
        ('user', admin.RelatedOnlyFieldListFilter),
    ]
    
    search_fields = ['label', 'address_line', 'user__mobile_number', 'user__name']
    
    readonly_fields = ['created_at']
    
    fieldsets = (
        ('Address Information', {
            'fields': ('user', 'label', 'address_line', 'is_default')
        }),
        ('Location Details', {
            'fields': ('latitude', 'longitude')
        }),
        ('Metadata', {
            'fields': ('created_at',),
            'classes': ('collapse',)
        })
    )
    
    def user_display(self, obj):
        return f"{obj.user.name or 'N/A'} ({obj.user.mobile_number})"
    user_display.short_description = 'User'
    
    def address_line_short(self, obj):
        return obj.address_line[:50] + "..." if len(obj.address_line) > 50 else obj.address_line
    address_line_short.short_description = 'Address'
    
    def coordinates_display(self, obj):
        google_maps_url = f"https://www.google.com/maps?q={obj.latitude},{obj.longitude}"
        return format_html(
            '{:.4f}, {:.4f} <a href="{}" target="_blank">🗺️</a>',
            obj.latitude, obj.longitude, google_maps_url
        )
    coordinates_display.short_description = 'GPS Coordinates'

@admin.register(ServiceArea)
class ServiceAreaAdmin(admin.ModelAdmin):
    """Basic service area admin"""
    
    list_display = [
        'name', 'center_coordinates', 'radius_km', 'active'
    ]
    
    list_filter = ['active']
    search_fields = ['name']
    
    def center_coordinates(self, obj):
        google_maps_url = f"https://www.google.com/maps?q={obj.center_lat},{obj.center_lng}"
        return format_html(
            '{:.4f}, {:.4f} <a href="{}" target="_blank">🗺️</a>',
            obj.center_lat, obj.center_lng, google_maps_url
        )
    center_coordinates.short_description = 'Center Location'