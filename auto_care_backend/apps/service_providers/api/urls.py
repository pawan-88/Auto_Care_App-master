from django.urls import path
from .views import (
    ProviderRegistrationView,
    ProviderLoginView,
    ProviderVerifyOTPView,
    ProviderProfileView,
    AvailableJobsView,
    AssignmentActionView,
    complete_service,
    update_location,
    toggle_availability,
    mark_en_route,
    PendingAssignmentsView,
    ActiveAssignmentView,
    CompletedAssignmentView,
)

urlpatterns = [
    # Authentication
    path('register/', ProviderRegistrationView.as_view(), name='provider-register'),
    path('login/', ProviderLoginView.as_view(), name='provider-login'),
    path('verify-otp/', ProviderVerifyOTPView.as_view(), name='provider-verify-otp'),

    # Profile
    path('profile/', ProviderProfileView.as_view(), name='provider-profile'),

    # Jobs & Assignments
    path('jobs/available/', AvailableJobsView.as_view(), name='available-jobs'),
    path('assignments/pending/', PendingAssignmentsView.as_view(), name='pending-assignments'),
    path('assignments/active/', ActiveAssignmentView.as_view(), name='active-assignments'),
    path('assignments/history/', CompletedAssignmentView.as_view(), name='assignments-history'),

    path('assignments/<int:assignment_id>/action/', AssignmentActionView.as_view(), name='assignment-action'),
    path('assignments/<int:assignment_id>/en-route/', mark_en_route, name='mark-en-route'),
    path('assignments/<int:assignment_id>/complete/', complete_service, name='complete-service'),

    # Location & Availability
    path('location/update/', update_location, name='update-location'),
    path('availability/toggle/', toggle_availability, name='toggle-availability'),
]
