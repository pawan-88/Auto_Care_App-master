from django.contrib import admin
from .models import Booking

@admin.register(Booking)
class BookingAdmin(admin.ModelAdmin):
    """Basic booking admin - no location features yet"""
    
    list_display = [
        'id', 'user', 'vehicle_type', 'date', 'time_slot', 
        'status', 'created_at'
    ]
    
    list_filter = [
        'status', 'vehicle_type', 'date', 'created_at'
    ]
    
    search_fields = [
        'user__mobile_number', 'user__name', 'notes', 'id'
    ]
    
    ordering = ['-created_at']
    readonly_fields = ['created_at']
    
    fieldsets = (
        ('Booking Information', {
            'fields': ('user', 'vehicle_type', 'date', 'time_slot', 'status')
        }),
        ('Additional Information', {
            'fields': ('notes', 'created_at'),
            'classes': ('collapse',)
        })
    )
    
    actions = ['mark_confirmed', 'mark_completed']
    
    def mark_confirmed(self, request, queryset):
        updated = queryset.filter(status='pending').update(status='confirmed')
        self.message_user(request, f'{updated} booking(s) marked as confirmed.')
    mark_confirmed.short_description = 'Mark selected bookings as Confirmed'
    
    def mark_completed(self, request, queryset):
        updated = queryset.filter(status='confirmed').update(status='completed')
        self.message_user(request, f'{updated} booking(s) marked as completed.')
    mark_completed.short_description = 'Mark selected bookings as Completed'