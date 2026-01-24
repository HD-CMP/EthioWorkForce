# EthioWorkforce Setup Guide

## Prerequisites

- **Python 3.11+**
- **PostgreSQL 15+**
- **Redis 7+**
- **Flutter 3.16+**
- **Docker & Docker Compose** (optional, recommended)

## Backend Setup

### Option 1: Using Docker (Recommended)

```bash
cd EthioWorkforce
docker-compose up -d
```

This will start:
- PostgreSQL database on port 5432
- Redis on port 6379
- FastAPI backend on port 8000
- Celery worker for background tasks

### Option 2: Manual Setup

1. **Create Virtual Environment**
```bash
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

2. **Install Dependencies**
```bash
pip install -r requirements.txt
```

3. **Configure Environment**
```bash
cp .env.example .env
```

Edit `.env` and update:
- `DATABASE_URL`: Your PostgreSQL connection string
- `SECRET_KEY`: Generate a secure key (min 32 characters)
- `REDIS_URL`: Your Redis connection string

4. **Initialize Database**
```bash
python scripts/init_db.py
```

5. **Run Migrations**
```bash
alembic upgrade head
```

6. **Start Server**
```bash
python run.py
```

The API will be available at `http://localhost:8000`
API Documentation: `http://localhost:8000/api/docs`

## Frontend Setup

### Flutter Application

1. **Navigate to Frontend**
```bash
cd frontend
```

2. **Install Dependencies**
```bash
flutter pub get
```

3. **Generate Code**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

4. **Run Application**

For Desktop (Windows):
```bash
flutter run -d windows
```

For Mobile (Android):
```bash
flutter run -d <device_id>
```

For Web:
```bash
flutter run -d chrome
```

## Default Credentials

After running `scripts/init_db.py`, you can log in with:

- **Username**: admin
- **Password**: admin123

**⚠️ IMPORTANT**: Change the default password immediately in production!

## Testing

### Backend Tests
```bash
cd backend
pytest -v --cov=app
```

### Frontend Tests
```bash
cd frontend
flutter test
```

## Development Workflow

1. **Start Backend** (Docker or manual)
2. **Start Frontend** (Flutter run)
3. **Access Application** at the Flutter app
4. **Access API Docs** at http://localhost:8000/api/docs

## Database Migrations

### Create New Migration
```bash
cd backend
alembic revision --autogenerate -m "description"
```

### Apply Migrations
```bash
alembic upgrade head
```

### Rollback Migration
```bash
alembic downgrade -1
```

## Production Deployment

### Backend

1. Set `ENVIRONMENT=production` in `.env`
2. Use strong `SECRET_KEY`
3. Configure production database
4. Use HTTPS
5. Enable Sentry for error tracking
6. Set up proper CORS origins

### Frontend

1. Build for production:
```bash
flutter build apk --release  # For Android
flutter build windows --release  # For Windows
```

2. Configure production API endpoint in `lib/core/network/dio_client.dart`

## Troubleshooting

### Database Connection Issues
- Verify PostgreSQL is running
- Check `DATABASE_URL` in `.env`
- Ensure database exists

### Redis Connection Issues
- Verify Redis is running
- Check `REDIS_URL` in `.env`

### Flutter Build Issues
- Run `flutter clean`
- Delete `pubspec.lock`
- Run `flutter pub get` again
- Run build_runner again

## Support

For issues, please check the project documentation or contact the development team.
