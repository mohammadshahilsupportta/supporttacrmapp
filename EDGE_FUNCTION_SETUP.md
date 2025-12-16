# Edge Function Setup Guide

## Overview

The Edge Function `create_staff` uses Supabase Admin API to create staff members, bypassing client-side email validation that rejects some valid emails.

## Quick Setup

### Option 1: Using Supabase CLI (Recommended)

1. **Install Supabase CLI**
   ```bash
   npm install -g supabase
   ```

2. **Login to Supabase**
   ```bash
   supabase login
   ```

3. **Link your project**
   ```bash
   supabase link --project-ref nprkkrillxhgedgiajtc
   ```

4. **Deploy the function**
   ```bash
   supabase functions deploy create_staff
   ```

### Option 2: Using Supabase Dashboard

1. Go to your Supabase Dashboard: https://supabase.com/dashboard
2. Navigate to **Edge Functions** section
3. Click **Create a new function**
4. Name it `create_staff`
5. Copy the code from `supabase/functions/create_staff/index.ts`
6. Paste it into the function editor
7. Click **Deploy**

## How It Works

1. **Flutter app calls the Edge Function** with staff data
2. **Function verifies** the user is authenticated
3. **Function uses Admin API** to create auth user (bypasses email validation)
4. **Function creates** staff record in database
5. **Function assigns** category permissions
6. **Function returns** success with staff data

## Benefits

- ✅ Bypasses email validation restrictions
- ✅ Works with all email addresses (like the website)
- ✅ Service role key stays secure (server-side only)
- ✅ Automatic fallback to direct signUp if function unavailable

## Testing

After deployment, try creating a staff member with an email that was previously rejected (like "ramu@gmail.com"). The app will automatically use the Edge Function if it's available.

## Troubleshooting

If the Edge Function fails:
- Check Supabase Dashboard → Edge Functions → Logs
- Verify the function is deployed and active
- Check that service role key is configured
- The app will automatically fall back to direct signUp

