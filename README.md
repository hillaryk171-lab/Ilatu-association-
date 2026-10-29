# ILATU Standalone Complete Website Package

This is a complete static-site deployment bundle for the existing ILATU public website and its administrator dashboard. The files are at the ZIP root so they can be uploaded directly to Netlify after extraction.

## Package contents
- `index.html` — existing public ILATU website, including its embedded images and original page content.
- `admin.html` — administrator dashboard for gallery photos, news, events, drafts, publishing, deletion, and JSON backup.
- `supabase_setup.sql` — additive database and storage setup for shared live content. It does not alter the existing member, contributions, payment, receipt, or profile tables.
- `netlify.toml` — Netlify publish directory, security headers, and `/admin` shortcut.
- `ILATU_Admin_Dashboard_Prototype_original.html` — preserved original dashboard prototype for reference.
- `DEPLOY_FIRST.txt` — short deployment checklist.

## Deploy to Netlify
1. Extract this ZIP.
2. Open the existing Netlify site and deploy the extracted package contents (the files themselves, not an extra nested folder). Keep `index.html`, `admin.html`, `netlify.toml`, and `supabase_setup.sql` at the published root.
3. If this Supabase content-management setup has not been installed before, review `supabase_setup.sql` and run it once in the Supabase project configured in the HTML files. If your existing website and admin dashboard already use this table, do not rerun setup SQL unnecessarily. The Learn More information is included in `index.html`; this setup script is for the photo/news/event content-management features.
4. In Supabase **Authentication → Users**, create or verify the administrator account `hillaryk171@gmail.com`. Use a new strong password and verify the email. Do not use a password shared in chat.
5. Add the live site URL to Supabase **Authentication → URL Configuration** redirect URLs.
6. Visit `/admin.html` (or `/admin`) and sign in. Start by saving a draft, then test publishing after confirming it looks correct.

## Important limits
- The public website includes the Learn More sections. The administrator dashboard in this package manages photo, news and event content; it does not provide a separate Learn More editor. Shared logins, live publishing and image uploads require an internet connection and the configured Supabase backend. They are not offline-only features.
- This package has not been deployed to your Netlify account, and the SQL has not been run against your live Supabase project from this environment. Successful live sign-in, upload and publishing therefore cannot yet be confirmed.
- The browser uses the Supabase public anon key; it is not an admin password. Row-level security in `supabase_setup.sql` limits edits to the verified admin email. Never place a Supabase service-role key or account password in HTML or GitHub.
- Existing member and financial tables are not intentionally changed by the setup SQL.
