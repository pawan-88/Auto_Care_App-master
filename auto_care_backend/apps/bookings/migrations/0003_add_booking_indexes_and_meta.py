# Generated manually for performance and ordering

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('bookings', '0002_booking_notes'),
    ]

    operations = [
        migrations.AddIndex(
            model_name='booking',
            index=models.Index(fields=['user', 'date'], name='bookings_bo_user_id_date_idx'),
        ),
        migrations.AddIndex(
            model_name='booking',
            index=models.Index(fields=['status', 'created_at'], name='bookings_bo_status_created_idx'),
        ),
        migrations.AlterModelOptions(
            name='booking',
            options={'ordering': ['-created_at']},
        ),
    ]