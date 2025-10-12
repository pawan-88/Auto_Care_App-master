# Generated manually for security improvements

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('accounts', '0002_otp_alter_user_options_alter_user_managers_and_more'),
    ]

    operations = [
        migrations.AddField(
            model_name='otp',
            name='is_verified',
            field=models.BooleanField(default=False),
        ),
        migrations.AddField(
            model_name='otp',
            name='attempts',
            field=models.IntegerField(default=0),
        ),
        migrations.AddIndex(
            model_name='otp',
            index=models.Index(fields=['mobile_number', 'created_at'], name='accounts_ot_mobile__idx'),
        ),
        migrations.AddIndex(
            model_name='otp',
            index=models.Index(fields=['mobile_number', 'is_verified'], name='accounts_ot_mobile__verified_idx'),
        ),
    ]