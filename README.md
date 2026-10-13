# TripMate — Smart Travel Planner

TripMate is a full-stack travel planning platform built with a Django REST API and a Flutter mobile client.

## Features
- User registration, login, token-based auth, profile management, and password reset
- Destination discovery with search, filters, and saved destinations
- Itinerary planning, expense tracking, and budget summaries
- Reservation management with QR verification
- Travel videos and notifications
- PostgreSQL-ready backend configuration with SQLite fallback for local development

## Backend setup

1. Create a virtual environment if needed.
2. Install backend dependencies:
   ```bash
   python -m pip install -r requirements.txt
   ```
3. Copy environment settings:
   ```bash
   copy .env.example .env
   ```
4. Set `GEOAPIFY_API_KEY` in `.env` using a newly generated Geoapify key. Keep it on the Django server; do not pass it to Flutter or commit `.env`.
5. Create database tables:
   ```bash
   python manage.py migrate
   ```
6. Load sample destination data for the existing TripMate home and destination features:
   ```bash
   python seed_data.py
   ```
7. Start the server so Android emulators and other devices can reach it:
   ```bash
   python manage.py runserver 0.0.0.0:8000
   ```

The live place-discovery endpoint is `GET /api/destinations/discover/?q=Paris&limit=20`. It uses Geoapify Geocoding and Places APIs, caches provider results briefly, and returns provider attribution. It never substitutes seeded destinations when provider search fails.

## Flutter app setup

1. Open the frontend project:
   ```bash
   cd frontend
   flutter pub get
   flutter run
   ```
2. Run the Flutter app with the appropriate backend base URL:
   ```bash
   # Flutter web / desktop on the same machine
   flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000/api

   # Android emulator
   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
   ```
3. Explore searches for real provider-backed places. OpenStreetMap tiles provide the interactive map and attribution; no Google Maps key is required.

## Environment variables
- `SECRET_KEY`
- `DEBUG`
- `ALLOWED_HOSTS`
- `DATABASE_URL`
- `JWT_SECRET_KEY`
- `EMAIL_BACKEND`
- `EMAIL_HOST`
- `EMAIL_PORT`
- `EMAIL_USE_TLS`
- `EMAIL_HOST_USER`
- `EMAIL_HOST_PASSWORD`
- `DEFAULT_FROM_EMAIL`
- `GEOAPIFY_API_KEY` (backend only; required for live place discovery)

## Useful commands
```bash
python manage.py makemigrations
python manage.py migrate
python manage.py test
pytest -q
cd frontend && flutter analyze
``` 
