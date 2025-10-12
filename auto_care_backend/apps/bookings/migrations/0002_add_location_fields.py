from django.db import migrations, models
import django.db.models.deletion

class Migration(migrations.Migration):
    """Add location support to Booking model"""
    
    dependencies = [
        ('bookings', '0001_initial'),
        ('locations', '0001_initial'),  # Ensure locations app is ready
    ]

    operations = [
        migrations.AddField(
            model_name='booking',
            name='latitude',
            field=models.DecimalField(
                decimal_places=6, 
                max_digits=9,
                help_text='GPS latitude of service location'
            ),
        ),
        migrations.AddField(
            model_name='booking',
            name='longitude',
            field=models.DecimalField(
                decimal_places=6, 
                max_digits=9,
                help_text='GPS longitude of service location'
            ),
        ),
        migrations.AddField(
            model_name='booking',
            name='service_address',
            field=models.TextField(
                help_text='Full address text for service location'
            ),
        ),
        migrations.AddField(
            model_name='booking',
            name='address',
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                to='locations.address',
                help_text="Reference to user's saved address (if used)"
            ),
        ),
        migrations.AddIndex(
            model_name='booking',
            index=models.Index(
                fields=['latitude', 'longitude'], 
                name='bookings_bo_latitud_idx'
            ),
        ),
    ]