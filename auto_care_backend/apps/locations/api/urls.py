from django.urls import path
from .views import (
    AddressListCreateView, 
    AddressRetrieveUpdateDeleteView,
    ServiceAreaListCreateView, 
    ServiceAreaDetailView
)

urlpatterns = [
    # Address endpoints
    path("addresses/", AddressListCreateView.as_view(), name="address-list-create"),
    path("addresses/<int:pk>/", AddressRetrieveUpdateDeleteView.as_view(), name="address-detail"),
    
    # Service area endpoints (admin only)
    path("service-areas/", ServiceAreaListCreateView.as_view(), name="service-area-list"),
    path("service-areas/<int:pk>/", ServiceAreaDetailView.as_view(), name="service-area-detail"),
]