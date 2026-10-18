# Supabase Database Setup Guide

## Step 1: Create Supabase Account

1. Visit [https://supabase.com](https://supabase.com)
2. Click **"Start your project"**
3. Sign up with GitHub (recommended) or email
4. Verify your email

## Step 2: Create New Project

1. Click **"New Project"**
2. Fill in details:
   - **Name**: `ethioworkforce-db`
   - **Database Password**: Generate a strong password (save it securely!)
   - **Region**: Choose closest to your users (e.g., `Southeast Asia` for Ethiopia proximity)
   - **Pricing Plan**: Free tier (500MB database, 50k monthly active users)
3. Click **"Create new project"**
4. Wait 2-3 minutes for setup

## Step 3: Get Database Connection String

1. Go to **Project Settings** → **Database**
2. Scroll to **Connection String** section
3. Select **"URI"** mode
4. Copy the connection string (looks like):
   ```
   postgresql://postgres:[YOUR-PASSWORD]@db.xxxxx.supabase.co:5432/postgres
   ```
5. Replace `[YOUR-PASSWORD]` with the password you created

## Step 4: Get API Keys (for future features)

1. Go to **Project Settings** → **API**
2. Copy these values:
   - **Project URL**: `https://xxxxx.supabase.co`
   - **anon public key**: For frontend API calls
   - **service_role key**: For backend admin operations (keep secret!)

## Step 5: Initialize Database Schema

### Option A: Using Supabase SQL Editor (Recommended)

1. Go to **SQL Editor** in Supabase dashboard
2. Click **"New Query"**
3. Run migrations from your local setup:

```bash
# First, export your local schema
cd backend
alembic upgrade head
pg_dump -h localhost -U postgres -d ethioworkforce --schema-only > schema.sql

# Then copy and paste the schema into Supabase SQL Editor
```

### Option B: Using Alembic (After connecting to Supabase)

1. Update `backend/.env` with Supabase credentials:
```env
DATABASE_URL=postgresql://postgres:[PASSWORD]@db.xxxxx.supabase.co:5432/postgres
```

2. Run migrations:
```bash
cd backend
alembic upgrade head
python scripts/init_db.py
```

## Step 6: Configure GitHub Secrets

Add these to your GitHub repository:

1. Go to your repo: `https://github.com/HD-CMP/EthioWorkForce`
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **"New repository secret"** and add:

| Secret Name | Value | Description |
|-------------|-------|-------------|
| `SUPABASE_DB_URL` | `postgresql://postgres:[PASSWORD]@db.xxxxx.supabase.co:5432/postgres` | Supabase database URL |
| `REDIS_URL` | Get from [Upstash](https://upstash.com) | Free Redis (follow next section) |
| `SECRET_KEY` | Generate 32+ random chars | JWT secret key |
| `RENDER_API_KEY` | Get from Render dashboard | For auto-deployment |

## Step 7: Setup Free Redis (Upstash)

1. Visit [https://upstash.com](https://upstash.com)
2. Sign up with GitHub
3. Create new database:
   - **Name**: `ethioworkforce-redis`
   - **Type**: Redis
   - **Region**: Choose closest
   - **Plan**: Free (10k commands/day)
4. Copy **Redis URL** from dashboard
5. Add to GitHub secrets as `REDIS_URL`

## Step 8: Test Connection

Test your Supabase connection locally:

```bash
cd backend

# Update .env file
DATABASE_URL=postgresql://postgres:[PASSWORD]@db.xxxxx.supabase.co:5432/postgres

# Test connection
python -c "from app.core.database import engine; print(engine.connect())"

# Run migrations
alembic upgrade head

# Initialize with demo data
python scripts/init_db.py
```

## Step 9: Verify in Supabase Dashboard

1. Go to **Table Editor** in Supabase
2. You should see tables:
   - `users`
   - `sites`
   - `workers`
   - `attendances`
   - `payrolls`
   - And more...

## Next Steps

✅ Database is ready!
✅ Proceed to GitHub Actions setup
✅ Deploy backend to Render
✅ Build mobile APK

---

## Troubleshooting

### Connection refused
- Check if your IP is allowed (Supabase allows all by default)
- Verify password is correct
- Ensure using port 5432

### SSL certificate error
Update connection string to include SSL:
```
postgresql://postgres:[PASSWORD]@db.xxxxx.supabase.co:5432/postgres?sslmode=require
```

### Migration errors
Reset database if needed:
```sql
-- In Supabase SQL Editor
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO public;
```

Then re-run migrations.
