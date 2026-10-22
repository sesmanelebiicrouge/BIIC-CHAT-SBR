# Automatic updates and release safety

## Web
- A push to `main` runs analysis, tests, a production Supabase endpoint smoke test, and a release build before the Pages deployment job can run.
- After a successful deployment, `.github/workflows/production-health.yml` checks the public URL with retries.
- A scheduled check runs twice per hour. If the public page remains unhealthy, the workflow attempts to restore the previous `gh-pages` commit using a compare-and-swap push. For a deployment-triggered rollback, it first verifies that the latest published commit belongs to the deployment being checked, so it will not intentionally undo a newer deployment.
- A transient CDN or GitHub Pages propagation delay can still cause a false alarm. Review the workflow log if a rollback occurs.

## Android
- Every push to `main` and pull request builds and tests a debug APK, uploaded as a short-lived CI artifact.
- A debug APK is for testing only; it is not a production Android release and does not update installed apps automatically.
- Production Android updates require one stable signing identity and a distribution channel. For Google Play, configure Play Console app signing/release access and a service-account secret before automating uploads. For direct APK distribution, securely configure a long-lived keystore and publish only APKs signed with that same key.
- Do not generate a new signing key per build. Never commit keystores, passwords, service-role keys, or signing credentials.

## Limits
- The public-site check verifies that the page is served; it does not test account creation, email delivery, messaging, push notifications, or Supabase policies end-to-end.
- Supabase schema migrations are deliberately not run automatically. Reconcile the remote migration history and review a migration before applying it to production.
