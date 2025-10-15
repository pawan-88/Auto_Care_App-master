from django.contrib import admin
from django.utils.html import format_html
from .models import Address, ServiceArea


@admin.register(Address)
class AddressAdmin(admin.ModelAdmin):
    """Enhanced address admin for new Address model structure"""
    
    list_display = [
        'address_type_display', 'user_display', 'address_short', 'coordinates_display', 
        'is_default', 'created_at'
    ]
    
    list_filter = [
        'address_type', 'is_default', 'created_at',
        ('user', admin.RelatedOnlyFieldListFilter),
    ]
    
    search_fields = [
        'address_line1', 'address_line2', 'city', 'state', 'pincode',
        'user__mobile_number', 'user__name'
    ]
    
    readonly_fields = ['created_at', 'address_line']
    
    fieldsets = (
        ('Address Information', {
            'fields': ('user', 'address_type', 'is_default')
        }),
        ('Address Details', {
            'fields': (
                'address_line1', 'address_line2', 'landmark', 
                'city', 'state', 'pincode', 'address_line'
            )
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
    
    def address_type_display(self, obj):
        """Display address type with icon"""
        icons = {
            'home': '🏠',
            'work': '🏢', 
            'other': '📍'
        }
        icon = icons.get(obj.address_type, '📍')
        return f"{icon} {obj.get_address_type_display()}"
    address_type_display.short_description = 'Type'
    
    def address_short(self, obj):
        """Display shortened address"""
        address_parts = [obj.address_line1, obj.city, obj.state]
        full_address = ', '.join(filter(None, address_parts))
        return full_address[:50] + "..." if len(full_address) > 50 else full_address
    address_short.short_description = 'Address'
    
    def coordinates_display(self, obj):
        """Display coordinates with Google Maps link"""
        google_maps_url = f"https://www.google.com/maps?q={obj.latitude},{obj.longitude}"
        return format_html(
            '{:.4f}, {:.4f} <a href="{}" target="_blank">🗺️</a>',
            obj.latitude, obj.longitude, google_maps_url
        )
    coordinates_display.short_description = 'GPS Coordinates'


@admin.register(ServiceArea)
class ServiceAreaAdmin(admin.ModelAdmin):
    """Enhanced service area admin"""
    
    list_display = [
        'name', 'center_coordinates', 'radius_km', 'active', 'address_count'
    ]
    
    list_filter = ['active']
    search_fields = ['name']
    ordering = ['name']
    
    def center_coordinates(self, obj):
        """Display center coordinates with Google Maps link"""
        google_maps_url = f"https://www.google.com/maps?q={obj.center_lat},{obj.center_lng}"
        return format_html(
            '{:.4f}, {:.4f} <a href="{}" target="_blank">🗺️</a>',
            obj.center_lat, obj.center_lng, google_maps_url
        )
    center_coordinates.short_description = 'Center Location'
    
    def address_count(self, obj):
        """Show how many addresses are in this service area (approximate)"""
        # This is a simple count - in production you might want more sophisticated logic
        from .models import Address
        addresses = Address.objects.all()
        count = sum(1 for addr in addresses if obj.contains(float(addr.latitude), float(addr.longitude)))
        return f"{count} addresses"
    address_count.short_description = 'Addresses in Area'
