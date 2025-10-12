from django.urls import path
from .views import BookingListCreateView, BookingDetailView

urlpatterns = [
    # Basic booking endpoints
    path('', BookingListCreateView.as_view(), name='booking-list-create'),
    path('<int:pk>/', BookingDetailView.as_view(), name='booking-detail'),
]