# Supabase backend and security setup

BIIC CHAT contains private user content. Do not make chat or profile storage buckets public.

## Database

Run all migrations in order, through `supabase/migrations/007_phone_accounts_and_deletion.sql` using Supabase migrations or the SQL editor.

## Storage

Create two private buckets:
- chat_media
- avatars

Use authenticated Storage access or short-lived signed URLs. Never ship a Supabase service-role key in the Flutter application.

## Realtime

Enable Realtime/Postgres Changes for:
- messages
- conversations
- conversation_members

## Production security

- Keep Row Level Security enabled.
- Test policies with at least two different authenticated users.
- Add abuse and rate controls before public launch.
- Configure backups and monitoring.
