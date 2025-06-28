from django.core.management.base import BaseCommand, CommandError
from django.contrib.auth import get_user_model
from django.conf import settings
from datetime import datetime, timedelta
import jwt

class Command(BaseCommand):
    help = "Generate a JWT for the given username"

    def add_arguments(self, parser):
        parser.add_argument('username', help='Existing Django username')

    def handle(self, *args, **options):
        User = get_user_model()
        try:
            user = User.objects.get(username=options['username'])
        except User.DoesNotExist as exc:
            raise CommandError('User not found') from exc

        payload = {
            'username': user.username,
            'iat': datetime.utcnow(),
            'exp': datetime.utcnow() + timedelta(hours=1)
        }
        secret = getattr(settings, 'JWT_SECRET_KEY', settings.JWT_SECRET_KEY)
        token = jwt.encode(payload, secret, algorithm='HS256')
        self.stdout.write(token)