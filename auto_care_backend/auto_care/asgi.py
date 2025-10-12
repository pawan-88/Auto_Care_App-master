import os
import django
from channels.routing import ProtocolTypeRouter, URLRouter
from channels.auth import AuthMiddlewareStack
from django.core.asgi import get_asgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'auto_care.settings')
django.setup()

django_asgi_app = get_asgi_application()

import apps.bookings.routing as booking_routing  # you will create this

application = ProtocolTypeRouter({
    "http": django_asgi_app,
    "websocket": AuthMiddlewareStack(
        URLRouter(
            booking_routing.websocket_urlpatterns
        )
    ),
})
