# Supabase Setup Guide for LoreFit

This guide will walk you through setting up Supabase for LoreFit.

## Step 1: Create Supabase Project

1. Go to https://supabase.com/dashboard
2. Sign in with your GitHub account (davidpm1021)
3. Click "New Project"
4. Fill in project details:
   - **Name:** `lorefit` or `LoreFit`
   - **Database Password:** (create a strong password and save it!)
   - **Region:** Choose closest to you (e.g., `us-east-1` for East Coast)
   - **Plan:** Free tier is perfect for MVP
5. Click "Create new project"
6. Wait ~2 minutes for project initialization

## Step 2: Get Your API Credentials

Once your project is created:

1. In the left sidebar, click the **Settings** gear icon
2. Click **API** in the Project Settings menu
3. You'll see three important values:

### Copy These Values:

**Project URL:**
```
https://xxxxxxxxxxxxx.supabase.co
```

**anon (public) key:**
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**service_role key:** (Click "Reveal" first)
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

## Step 3: Update .env.local

Open `C:\Users\david\Cursor Projects\LoreFit\.env.local` and replace the placeholder values:

```env
# Replace these with your actual Supabase credentials
NEXT_PUBLIC_SUPABASE_URL=https://xxxxxxxxxxxxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

NEXT_PUBLIC_APP_URL=http://localhost:3000
```

## Step 4: Run Database Migrations

### Option A: Using Supabase Dashboard (Easiest)

1. In Supabase dashboard, click **SQL Editor** in the left sidebar
2. Click **New query**
3. Copy and paste the contents of each migration file in order:
   - `supabase/migrations/20250101000001_create_profiles_table.sql`
   - `supabase/migrations/20250101000002_create_user_points_table.sql`
   - `supabase/migrations/20250101000003_create_workouts_table.sql`
   - `supabase/migrations/20250101000004_create_activity_sync_table.sql`
   - `supabase/migrations/20250101000005_create_user_baselines_table.sql`
   - `supabase/migrations/20250101000006_create_user_challenges_table.sql`
4. Click **Run** for each migration
5. Verify no errors appear

### Option B: Using Supabase CLI (Advanced)

```bash
# Install Supabase CLI
npm install -g supabase

# Link to your project
supabase link --project-ref your-project-ref

# Run migrations
supabase db push
```

## Step 5: Verify Database Setup

1. In Supabase dashboard, click **Table Editor**
2. You should see these tables:
   - ✅ profiles
   - ✅ user_points
   - ✅ workouts
   - ✅ activity_sync
   - ✅ user_baselines
   - ✅ user_challenges

3. Click on **profiles** table
4. You should see columns: id, username, display_name, etc.

## Step 6: Enable Email Authentication

1. In Supabase dashboard, go to **Authentication** → **Providers**
2. **Email** should already be enabled
3. Under **Email** settings:
   - Enable **Confirm email** (optional for MVP)
   - Set **Site URL** to `http://localhost:3000`
   - Add **Redirect URLs**: `http://localhost:3000/**`
4. Click **Save**

## Step 7: Test the Connection

1. Restart your Next.js dev server:
   ```bash
   # Stop current server (Ctrl+C)
   npm run dev
   ```

2. Open http://localhost:3000
3. You should see the homepage with **no errors**
4. Check browser console - should be clean!

## Step 8: Verify RLS Policies

1. In Supabase dashboard, click **Authentication** → **Policies**
2. You should see policies for each table
3. Example policies to verify:
   - `profiles`: "Users can view own profile"
   - `workouts`: "Users can view own workouts"
   - `user_points`: "Points are viewable by everyone"

## Troubleshooting

### "Invalid API key" error
- Double-check you copied the entire key (they're very long!)
- Make sure no extra spaces before/after the key
- Verify you're using the **anon** key, not service_role for NEXT_PUBLIC_SUPABASE_ANON_KEY

### "Relation does not exist" error
- Migrations didn't run correctly
- Re-run migrations in the SQL Editor
- Check for error messages in the SQL output

### "Row Level Security policy violation"
- RLS is enabled but policies didn't apply
- Re-run the migration files that contain the policies
- Check in Authentication → Policies that policies exist

## Next Steps

Once Supabase is set up:

1. ✅ Test user signup (we'll build this next)
2. ✅ Verify profile creation
3. ✅ Check points initialization
4. ✅ Test authentication flow

---

**Need help?** Check the Supabase docs: https://supabase.com/docs

Or create an issue in the LoreFit repo: https://github.com/davidpm1021/LoreFit/issues
