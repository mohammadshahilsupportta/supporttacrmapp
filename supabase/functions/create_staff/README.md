# Create Staff Edge Function

This Supabase Edge Function uses Admin API to create staff members, bypassing client-side email validation restrictions.

## Deployment Instructions

### Prerequisites
1. Install Supabase CLI: https://supabase.com/docs/guides/cli
2. Login to Supabase: `supabase login`
3. Link your project: `supabase link --project-ref your-project-ref`

### Deploy the Function

1. Navigate to the project root directory
2. Deploy the function:
   ```bash
   supabase functions deploy create_staff
   ```

### Environment Variables

The function uses these environment variables (automatically available in Supabase):
- `SUPABASE_URL` - Your Supabase project URL
- `SUPABASE_ANON_KEY` - Your Supabase anon key
- `SUPABASE_SERVICE_ROLE_KEY` - Your Supabase service role key (for Admin API)

These are automatically set by Supabase when deploying.

### Testing

After deployment, the Flutter app will automatically try to use this Edge Function when creating staff members. If the function is not available, it will fall back to direct `signUp()` (which may fail for some emails due to validation).

### How It Works

1. The function receives staff creation data from the Flutter app
2. Verifies the requesting user is authenticated
3. Uses Admin API to create the auth user (bypasses email validation)
4. Creates the staff record in the database
5. Assigns category permissions if provided
6. Returns the created staff data

### Security

- The function verifies the user is authenticated before creating staff
- Service role key is only used server-side (never exposed to client)
- All operations are performed server-side for security

