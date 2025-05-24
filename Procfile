release: python3 manage.py makemigrations
release: python3 manage.py migrate
release: python3 manage.py collectstatic --noinput
release: python3 manage.py createsuperuser

web: gunicorn config.wsgi