from django.urls import path
from .views import SendOTPView, VerifyOTPView, UserProfileView, AddressListCreateView, AddressDetailView, SetDefaultAddressView
from rest_framework_simplejwt.views import TokenRefreshView

urlpatterns = [

    # Authentication
    path('send-otp/', SendOTPView.as_view(), name='send-otp'),
    path('verify-otp/', VerifyOTPView.as_view(), name='verify-otp'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token-refresh'),

    # Profile
    path('profile/', UserProfileView.as_view(), name='profile'),
    

     # Addresses
    path('addresses/', AddressListCreateView.as_view(), name='address-list-create'),
    path('addresses/<int:pk>/', AddressDetailView.as_view(), name='address-detail'),
    path('addresses/<int:pk>/set-default/', SetDefaultAddressView.as_view(), name='set-default-address'),
]