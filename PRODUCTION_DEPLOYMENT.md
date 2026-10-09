# Lumina production launch runbook

This repository change prepares a deployment path; it does not mean a live service has been created or that the app is certified production-ready.

## Recommended stack
- Flutter Android app; keep offline data in device SQLite.
- FastAPI container on Render.
- Managed PostgreSQL on Render, in the same region as the API.
- Cloudflare Registrar/DNS is one option for a domain selected and purchased by the owner.
- OpenAI Responses API is called only from FastAPI; never embed the provider API key in Flutter.

## 1. Deploy a staging environment first
1. Review this branch and merge only after tests and code review.
2. Create a Render account and connect the GitHub repository.
3. Import the Blueprint from render.yaml. Review current plan prices and region availability before confirming paid resources.
4. Set CORS_ORIGINS to the exact HTTPS origin(s) actually used by the customer website, if any. Do not use wildcards with credentials or localhost in production.
5. Keep AI_PROVIDER=none until an AI key is configured in the Render environment UI. For online AI set AI_PROVIDER=openai, set AI_API_KEY as a secret, and choose a supported model in AI_MODEL.
6. Verify health, HTTPS, database connectivity, signup/login, permissions and logs using dedicated staging accounts.

## 2. Domain
1. Search and purchase an available domain through a registrar.
2. In Render, add the purchased domain to the API service as api.yourdomain.com.
3. Apply the exact DNS records Render displays. Wait for DNS and TLS certificate issuance.
4. Set CORS_ORIGINS to the actual HTTPS frontend origin; the mobile app itself does not use browser CORS.
5. Never assume a domain is available until the registrar confirms it.

## 3. Secrets and customer accounts
- Generate a unique secret with a cryptographically secure generator. Do not reuse a development secret.
- Never run python seed.py against production: it creates known development users, passwords, and invitation codes.
- Do not publish test credentials or let public registration assign privileged roles.
- Provision an owner-controlled administrator through a reviewed one-time process before launch; do not seed a default admin password.
- Never store OpenAI keys in Flutter assets, source code, app config, or logs.

## 4. Data and migration safety
- Configure and test database backups and restore before accepting customer data.
- This code currently calls SQLAlchemy create_all at startup. That is not a substitute for reviewed database migrations. Add and test Alembic migrations before production schema changes and before considering the deployment launch-ready.
- Confirm privacy policy, terms, retention/deletion procedures, support contact, age-appropriate handling, and licenses for every lesson/video before public release.

## 5. Release gates (must all pass)
- CI tests pass; run Flutter analyze, Flutter tests, and an Android release build on a clean checkout.
- Test every role and verify server-side authorization on every protected endpoint.
- Test password reset, email verification, refresh-token rotation/reuse, logout, rate limits and account deletion.
- Test offline-first behavior in airplane mode, restart, reconnect, retries, duplicate sync events and conflicting updates.
- Verify no app API secrets; review dependency and mobile security findings.
- Verify backups/restoration, monitoring, alerting, and rollback.
- Perform staging end-to-end tests on real devices before public distribution.

## Current limitations to resolve
- The development seed script contains demo accounts and invitation codes; use it locally only.
- The online tutor integration is optional and must be validated against the selected provider/model and cost controls.
- The app still needs a full end-to-end review of role permissions, settings persistence, sync idempotency, email verification/password recovery, and database migrations.
- No domain, paid service, AI billing account, store listing, or production deployment is created by these files.
