release: python3 manage.py migrate
release: python3 manage.py collectstatic --noinput

web: DJANGO_ENV=production gunicorn config.wsgi
