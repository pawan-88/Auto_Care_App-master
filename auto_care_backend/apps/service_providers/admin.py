from django.contrib import admin
from .models import ServiceProvider, ServiceAssignment

@admin.register(ServiceProvider)
class ServiceProviderAdmin(admin.ModelAdmin):
    list_display = [
        'employee_id', 'full_name', 'phone_number', 
        'specialization', 'verification_status', 
        'is_available', 'rating', 'total_jobs_completed'
    ]
    list_filter = [
        'verification_status', 'specialization', 
        'is_available', 'background_check_completed'
    ]
    search_fields = ['employee_id', 'full_name', 'phone_number', 'email']
    readonly_fields = ['joined_date', 'created_at', 'updated_at', 'last_location_update']
    
    fieldsets = (
        ('User Account', {
            'fields': ('user',)
        }),
        ('Personal Information', {
            'fields': ('employee_id', 'full_name', 'phone_number', 'email')
        }),
        ('Professional Details', {
            'fields': ('specialization', 'experience_years', 'service_areas')
        }),
        ('Location & Availability', {
            'fields': (
                'current_latitude', 'current_longitude', 
                'is_available', 'last_location_update'
            )
        }),
        ('Verification', {
            'fields': (
                'verification_status', 'verification_documents', 
                'background_check_completed'
            )
        }),
        ('Performance', {
            'fields': ('rating', 'total_jobs_completed', 'total_earnings')
        }),
        ('Timestamps', {
            'fields': ('joined_date', 'created_at', 'updated_at')
        }),
    )
    
    filter_horizontal = ['service_areas']


@admin.register(ServiceAssignment)
class ServiceAssignmentAdmin(admin.ModelAdmin):
    list_display = [
        'id', 'booking', 'service_provider', 'status', 
        'assigned_at', 'accepted_at', 'completed_at'
    ]
    list_filter = ['status', 'assigned_at']
    search_fields = ['booking__id', 'service_provider__full_name']
    readonly_fields = [
        'assigned_at', 'accepted_at', 'rejected_at', 
        'started_at', 'completed_at', 'cancelled_at'
    ]
    
    fieldsets = (
        ('Assignment Details', {
            'fields': ('booking', 'service_provider', 'status')
        }),
        ('Timeline', {
            'fields': (
                'assigned_at', 'accepted_at', 'rejected_at',
                'started_at', 'completed_at', 'cancelled_at'
            )
        }),
        ('Time Estimates', {
            'fields': (
                'estimated_arrival_time', 'actual_arrival_time',
                'estimated_completion_time'
            )
        }),
        ('Notes', {
            'fields': ('provider_notes', 'rejection_reason')
        }),
    )
