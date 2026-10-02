# MASTER PROMPT — UNIFIED STORAGE, MEDIA MANAGEMENT & AUTOMATED DATABASE BACKUP/RESTORE

Analyze the entire application architecture, existing backend, database layer, authentication/authorization system, deployment configuration, environment variables, storage integrations, scheduled jobs, and administration modules before making any changes.

The objective is to implement a **complete, production-ready, reusable Storage & Database Backup Infrastructure** that can be applied consistently across all my applications.

Do **not** create mock implementations, placeholders, fake services, incomplete routes, or UI-only features. Every feature described below must be fully implemented, connected to the real backend, secured, tested, documented, and operational.

---

## 1. UNIFIED MEDIA/STORAGE ARCHITECTURE

For **all media and file storage operations across the application**, implement the following provider hierarchy:

### Primary Storage — Cloudinary

Use **Cloudinary as the primary media-storage provider**.

Cloudinary should handle, where applicable:

- Images
- Product images
- User/profile images
- Documents
- Videos
- Application media
- Uploaded attachments
- Generated media
- Image transformations
- Optimization
- CDN delivery
- Secure deletion
- Replacement of existing media
- Metadata management

All Cloudinary credentials must come exclusively from environment variables.

Never hard-code:

- API keys
- API secrets
- Cloud names
- Tokens
- Credentials

---

## 2. FIRST FALLBACK / LOAD-BALANCING — UPLOADTHING

Implement **UploadThing as the secondary storage provider**.

The architecture must support both:

### Failover

If Cloudinary is unavailable, unreachable, incorrectly configured, rate-limited, or returns a storage/upload failure, automatically attempt UploadThing.

### Load balancing

The architecture must also be capable of routing selected workloads to UploadThing when appropriate, rather than forcing every file through Cloudinary.

The storage abstraction layer must therefore support:

```text
Application
     ↓
Storage Service Abstraction
     ↓
 ┌─────────────────────┐
 │ Cloudinary          │ ← Primary
 └─────────┬───────────┘
           │ failure / routing
           ↓
 ┌─────────────────────┐
 │ UploadThing         │ ← Secondary / Failover
 └─────────┬───────────┘
           │ failure
           ↓
 ┌─────────────────────┐
 │ Cloudflare R2       │ ← Final Fallback
 └─────────────────────┘
```

The application must **not directly couple business logic to a specific provider**.

Instead, create a centralized storage abstraction/service such as:

```text
StorageService
StorageProvider
CloudinaryProvider
UploadThingProvider
CloudflareR2Provider
StorageFailoverManager
```

Adapt naming to the existing project's architecture.

---

# 3. FINAL FALLBACK — CLOUDFLARE R2

Use **Cloudflare R2 as the final storage fallback**.

The fallback chain must be:

```text
1. Cloudinary
      ↓
2. UploadThing
      ↓
3. Cloudflare R2
```

If all providers fail:

- return a controlled error;
- log the failure;
- preserve the database consistency;
- never create a database record pointing to a file that was not successfully stored;
- provide an appropriate administrator/system error;
- never silently lose the uploaded file.

---

# 4. STORAGE PROVIDER HEALTH MONITORING

Create a provider health mechanism.

For every provider, track:

- Availability
- Connection status
- Upload success rate
- Upload failures
- Response latency
- Last successful operation
- Last failure
- Error type
- Provider status
- Current role: primary/fallback
- Configuration status

The Super Admin must be able to see the storage infrastructure status from the administration backend.

Example:

```text
Cloudinary       ● Operational
UploadThing      ● Operational
Cloudflare R2    ● Operational
```

If a provider becomes unavailable, the system should automatically use the next provider without requiring manual intervention.

---

# 5. STORAGE DATABASE DESIGN

Create or update the database model so that media records are provider-independent.

A media record should be able to contain information such as:

- Unique media ID
- Original filename
- MIME type
- File size
- Storage provider
- Provider asset ID
- Storage path/key
- Public/secure URL
- Checksum/hash
- Entity/module relationship
- Uploaded by
- Created date
- Updated date
- Status
- Metadata
- Backup/reference information

Do not design the database so that it assumes every file is stored on Cloudinary.

The database must remain provider-agnostic.

---

# 6. IMPORTANT: DATABASE BACKUP SYSTEM

Build a **complete backend database backup module**.

This is not simply a database export button.

It must be a complete production backup infrastructure.

The system must automatically create a backup of the application's database **once every week**.

The backup process must:

1. Connect to the production database.
2. Create a consistent database backup.
3. Include all required database information.
4. Preserve schema and data.
5. Compress the backup.
6. Encrypt the backup where technically appropriate.
7. Store backup metadata.
8. Upload/store the backup securely.
9. Validate that the backup was successfully created.
10. Validate backup integrity.
11. Record the backup status.
12. Notify/log success or failure.
13. Automatically apply the retention policy.

---

# 7. BACKUP FREQUENCY

Default schedule:

```text
Weekly
```

Create exactly one scheduled backup cycle per week unless the existing infrastructure requires a more suitable execution strategy.

The scheduled job must be reliable across the application's deployment environment.

Do not rely on an in-memory timer such as:

```javascript
setInterval()
```

for production backup scheduling.

Use the application's appropriate production scheduling mechanism, such as:

- Cron
- Scheduled serverless function
- Hosting-provider scheduled function
- Queue/worker
- Dedicated scheduler

depending on the actual deployment architecture.

---

# 8. BACKUP CONTENT

Each backup must contain everything necessary to reconstruct the database.

Include, as appropriate:

- Database schema
- Tables
- Columns
- Indexes
- Constraints
- Relationships
- Sequences
- Database data
- Required extensions
- Views
- Functions/procedures where applicable
- Relevant database metadata

The restore system must not depend on the application's current database contents to reconstruct missing historical information.

---

# 9. BACKUP COMPRESSION

Every backup must be compressed to minimize storage consumption.

Use an appropriate production-grade compression format such as:

```text
.gz
```

or another technically appropriate format.

Example:

```text
securelearn-db-2026-08-26.sql.gz
```

The final format should depend on the database engine and restoration tooling.

---

# 10. BACKUP STORAGE

Backups must be stored separately from the live production database.

**Do not store backups only inside the same database server.**

Use secure object storage or another dedicated backup location.

The backup infrastructure should preferably support:

```text
Primary Backup Storage
        ↓
Secondary Backup Storage
```

if the existing architecture permits it.

The backup storage must not interfere with the application's normal media-storage system.

Keep **application media storage** and **database backup storage** logically separated.

---

# 11. BACKUP RETENTION POLICY — 6 WEEKS

Implement a strict retention policy.

The system must retain only the **6 most recent weeks of database backups**.

Example:

```text
Week 1  → Keep
Week 2  → Keep
Week 3  → Keep
Week 4  → Keep
Week 5  → Keep
Week 6  → Keep
Week 7  → Delete
```

Every time a new backup is successfully created:

1. Identify all existing backups.
2. Sort them chronologically.
3. Keep the six most recent valid backups.
4. Delete backups older than the six-week retention window.
5. Remove their associated metadata.
6. Confirm deletion.
7. Log the cleanup operation.

Do not delete a newer valid backup simply because it has an unexpected filename/date.

Use reliable backup metadata and timestamps.

---

# 12. SUPER ADMIN BACKUP DASHBOARD

Create a complete **Backup Management Dashboard** inside the Super Admin backend.

The Super Admin must be able to see:

### Backup statistics

- Total backups
- Successful backups
- Failed backups
- Latest backup
- Next scheduled backup
- Oldest retained backup
- Storage consumed
- Retention period
- Backup health
- Last cleanup operation

### Backup list

For every backup show:

- Backup ID
- Date/time
- Database
- Size before compression
- Compressed size
- Compression ratio
- Status
- Storage provider
- Duration
- Checksum/integrity status
- Created by/system
- Retention status

---

# 13. SUPER ADMIN BACKUP ACTIONS

The Super Admin must be able to:

### View

Inspect backup metadata and status.

### Download

Download a backup file securely.

### Export

Export a backup to an appropriate supported format.

### Delete

Manually delete a backup when authorized.

### Create Backup Now

Allow an authorized Super Admin to manually trigger a backup.

### Verify Backup

Run an integrity check against the backup.

### Restore Backup

Restore a selected backup.

### View Restore History

Display every restoration attempt and its result.

---

# 14. RESTORE SYSTEM

Implement a complete database restoration mechanism.

The Super Admin must be able to restore:

```text
Backup → Existing Database
```

and, where technically supported:

```text
Backup → Another Database
```

The system must allow the administrator to specify the target database/environment safely.

Supported targets should be designed according to the actual database architecture, for example:

```text
Production
Preproduction
Staging
Development
External PostgreSQL database
```

Do not expose raw database credentials in the frontend.

---

# 15. CRITICAL RESTORE SAFETY

A restore operation must **never silently corrupt or unexpectedly overwrite the current database**.

Before every restore:

1. Authenticate the Super Admin.
2. Verify authorization.
3. Require explicit confirmation.
4. Display the selected backup.
5. Display the target database/environment.
6. Display the potential impact.
7. Validate backup integrity.
8. Validate database compatibility.
9. Create a safety snapshot/backup of the current target database where possible.
10. Start the restoration process.
11. Verify the restored database.
12. Run integrity checks.
13. Verify required tables and relationships.
14. Verify application connectivity.
15. Record the result.

---

# 16. PREVENT DATABASE CACHE / STALE DATA AFTER RESTORE

This is critical.

After a restore, the application must **not continue displaying stale cached data from before the restoration**.

Analyze the entire application's caching architecture and implement appropriate cache invalidation.

After a successful restore:

- invalidate application caches;
- invalidate server-side caches;
- invalidate database query caches where applicable;
- invalidate Redis/cache entries if Redis is used;
- invalidate Next.js/React server caches if applicable;
- invalidate ISR/revalidation caches where applicable;
- invalidate relevant CDN caches where appropriate;
- invalidate stale session/application state when necessary;
- restart/revalidate workers when necessary;
- ensure fresh database queries are executed.

The restored database must become the authoritative source of truth.

Do not allow old cached application data to overwrite restored data.

---

# 17. RESTORE TRANSACTION / RECOVERY STRATEGY

Design the restore process to minimize downtime and prevent partial restoration.

Where technically possible, use:

```text
Pre-restore validation
        ↓
Safety backup
        ↓
Restore
        ↓
Integrity verification
        ↓
Cache invalidation
        ↓
Application revalidation
        ↓
Health checks
        ↓
Restore completed
```

If restoration fails:

- do not leave the database in an unknown state;
- attempt rollback/recovery using the safety backup when technically possible;
- mark the restore as failed;
- record the error;
- notify the Super Admin;
- preserve the original backup.

---

# 18. RESTORE TO ANOTHER DATABASE

The restoration architecture must not assume that the target database is always the current production database.

Build the restore engine so that it can restore to another compatible database when authorized.

However:

- never expose raw connection strings in the UI;
- never log database passwords;
- validate the target database;
- verify database engine/version compatibility;
- verify schema compatibility;
- require explicit authorization;
- log who initiated the operation;
- log target environment;
- log backup used;
- log start/end time;
- log result.

---

# 19. SECURITY REQUIREMENTS

The backup and restore system is highly privileged.

Apply strict security controls.

Only authorized **Super Admins** may:

- View backups
- Download backups
- Delete backups
- Create manual backups
- Restore backups
- Restore to another database

Implement:

- RBAC
- Permission checks
- Server-side authorization
- Audit logging
- Rate limiting where appropriate
- Secure download URLs
- Expiring signed URLs where supported
- Encryption in transit
- Encryption at rest where supported
- Secret management
- CSRF protection where applicable
- Input validation
- Path traversal protection
- SSRF protection where applicable
- Command injection protection
- SQL injection protection

Never trust authorization checks performed only on the frontend.

---

# 20. AUDIT LOGGING

Every backup and restore operation must create an audit event.

Record:

```text
Who
What
When
Where
Target
Source backup
Action
Result
Duration
Error
IP/device metadata where appropriate
```

Examples:

```text
BACKUP_CREATED
BACKUP_FAILED
BACKUP_DELETED
BACKUP_DOWNLOADED
BACKUP_VERIFIED
RESTORE_STARTED
RESTORE_COMPLETED
RESTORE_FAILED
RESTORE_ROLLED_BACK
RETENTION_CLEANUP
```

---

# 21. FAILURE HANDLING

The backup system must be resilient.

If a backup fails:

- do not delete the previous valid backup;
- log the failure;
- notify the appropriate administrator;
- retry according to a controlled retry policy;
- preserve the previous six-week backup set;
- never mark a failed backup as valid.

The system should distinguish between:

```text
PENDING
IN_PROGRESS
SUCCESS
FAILED
CORRUPTED
DELETED
RESTORING
RESTORED
```

---

# 22. BACKUP INTEGRITY

Every backup should have an integrity mechanism.

Generate an appropriate checksum/hash such as:

```text
SHA-256
```

Store the checksum as backup metadata.

During:

- backup creation;
- upload;
- download;
- restore;

verify integrity where appropriate.

A corrupted backup must never be automatically restored.

---

# 23. DATABASE COMPATIBILITY

Before restoration, automatically verify:

- Database engine
- Database version compatibility
- Backup format
- Schema compatibility
- Required extensions
- Required privileges
- Target database accessibility

If compatibility cannot be confirmed, stop the restore and show a clear error.

---

# 24. ENVIRONMENT SEPARATION

Clearly separate:

```text
Development
Preproduction
Production
```

Backups and restoration must respect environment boundaries.

Production credentials must never be exposed to:

- frontend code;
- browser bundles;
- logs;
- Git repositories;
- client-side configuration.

Use environment variables/secrets appropriate to each environment.

For example:

```text
.env
.env.preproduction
.env.production
```

Ensure the correct configuration is loaded for each environment.

Never copy production secrets into source control.

---

# 25. API ARCHITECTURE

Build dedicated backend endpoints/services for:

```text
GET    /api/.../backups
POST   /api/.../backups
GET    /api/.../backups/:id
GET    /api/.../backups/:id/download
POST   /api/.../backups/:id/verify
POST   /api/.../backups/:id/restore
DELETE /api/.../backups/:id
POST   /api/.../backups/cleanup
GET    /api/.../backups/status
GET    /api/.../backups/restore-history
```

Adapt routes to the application's existing API/versioning conventions.

Do not blindly create duplicate APIs if an existing backup architecture already exists.

---

# 26. BACKGROUND JOB ARCHITECTURE

Long-running operations must not block normal HTTP requests.

Database:

- Backup creation
- Compression
- Upload
- Verification
- Restore
- Cleanup

should use appropriate background jobs/workers where necessary.

The UI should expose job status such as:

```text
Queued
Running
Processing
Completed
Failed
```

---

# 27. STORAGE AND BACKUP COST OPTIMIZATION

Design the system to minimize unnecessary storage costs.

Implement:

- Compression
- Six-week retention
- Automatic cleanup
- No duplicate backup uploads
- Efficient metadata
- Streaming where appropriate
- Multipart upload for large files where supported
- Automatic cleanup of incomplete uploads

Do not keep unlimited historical backups.

---

# 28. MEDIA DELETION CONSISTENCY

For normal application media, ensure database records and external storage remain synchronized.

When a media asset is deleted:

1. Delete/mark the database record appropriately.
2. Delete the external asset when safe.
3. Handle provider failures.
4. Log the operation.
5. Prevent orphaned media where possible.

When replacing an asset:

- upload the replacement first;
- verify successful storage;
- update the database;
- then remove the old asset.

This prevents broken media references.

---

# 29. OBSERVABILITY

Add structured logs and monitoring for:

### Storage

- Upload success/failure
- Provider used
- Failover events
- Latency
- File size
- Error reason

### Backup

- Backup started
- Backup completed
- Backup failed
- Compression
- Upload
- Verification
- Cleanup

### Restore

- Restore started
- Validation
- Restore completed
- Restore failed
- Rollback
- Cache invalidation
- Health checks

Do not log secrets or sensitive database contents.

---

# 30. ADMIN UI

Create a professional Super Admin interface with sections such as:

### Storage Infrastructure

```text
Cloudinary       Operational
UploadThing      Operational
Cloudflare R2    Operational
```

### Database Backup

```text
Latest Backup
Next Backup
Backups Retained
Storage Used
Backup Health
```

### Backup History

Provide filtering by:

- Date
- Status
- Environment
- Size
- Provider

### Restore Center

Allow the Super Admin to:

- Select backup
- Verify backup
- Select target
- Confirm restore
- Monitor progress
- View result

Use strong warnings for production restoration.

---

# 31. PRODUCTION RESTORE CONFIRMATION

For production restoration, require an additional confirmation step.

Example flow:

```text
Restore Backup
      ↓
Select Backup
      ↓
Validate Backup
      ↓
Select Production
      ↓
Display Warning
      ↓
Confirm
      ↓
Require explicit final confirmation
      ↓
Create safety backup
      ↓
Restore
      ↓
Invalidate caches
      ↓
Run health checks
      ↓
Complete
```

Never allow accidental one-click production restoration.

---

# 32. TESTING REQUIREMENTS

Create comprehensive tests.

### Unit tests

Test:

- Storage provider selection
- Cloudinary failure
- UploadThing fallback
- R2 fallback
- Backup creation
- Compression
- Checksums
- Retention
- Cleanup
- Restore validation
- Authorization
- Cache invalidation

### Integration tests

Test real integration between:

```text
Application
Storage layer
Database
Backup engine
Object storage
Authentication
Admin module
```

### E2E tests

Test complete flows:

```text
Upload → Cloudinary
Cloudinary failure → UploadThing
Cloudinary + UploadThing failure → R2

Create backup → Compress → Store → Verify

Select backup → Restore → Invalidate cache → Verify application
```

Test failed scenarios as well.

Target the project's existing test-coverage standard and do not reduce existing coverage.

---

# 33. DOCUMENTATION

Create complete technical documentation covering:

- Architecture
- Storage providers
- Provider priority
- Failover mechanism
- Environment variables
- Backup schedule
- Backup format
- Backup storage
- Retention policy
- Restore procedure
- Emergency recovery
- Security
- Troubleshooting
- Monitoring
- Cron/scheduler configuration
- Production deployment

Also document exactly how a Super Admin can perform a restore.

---

# 34. ENVIRONMENT VARIABLES

Identify all required credentials and configuration variables.

Examples may include:

```text
CLOUDINARY_CLOUD_NAME
CLOUDINARY_API_KEY
CLOUDINARY_API_SECRET

UPLOADTHING_TOKEN

R2_ACCOUNT_ID
R2_ACCESS_KEY_ID
R2_SECRET_ACCESS_KEY
R2_BUCKET_NAME
R2_ENDPOINT

BACKUP_STORAGE_BUCKET
BACKUP_ENCRYPTION_KEY

BACKUP_CRON_SECRET
```

Use the actual variable naming conventions of the project.

Do not invent unnecessary variables when an existing configuration already provides the same functionality.

Never expose server-only credentials to the frontend.

---

# 35. IMPORTANT ARCHITECTURAL PRINCIPLE

The entire implementation must be provider-independent.

Business logic should call:

```text
storage.upload()
storage.delete()
storage.getUrl()
storage.replace()
```

rather than:

```text
cloudinary.upload()
```

directly.

Likewise, business logic should call:

```text
backup.create()
backup.verify()
backup.restore()
backup.cleanup()
```

rather than directly executing database backup commands throughout the application.

This ensures the infrastructure remains maintainable and reusable across all applications.

---

# 36. IMPLEMENTATION RULES

Before implementing:

1. Analyze the current codebase.
2. Identify existing storage functionality.
3. Identify existing database architecture.
4. Identify existing authentication/RBAC.
5. Identify existing scheduled jobs.
6. Identify existing cache layers.
7. Identify existing admin dashboard.
8. Identify existing environment configurations.
9. Identify deployment platform.
10. Reuse existing architecture where appropriate.

Do not duplicate existing services.

Do not remove working functionality without a migration strategy.

Do not introduce unnecessary dependencies.

---

# 37. FINAL VALIDATION

After implementation, perform a complete audit.

Verify:

### Storage

- [ ] Cloudinary works as primary.
- [ ] UploadThing works as fallback/load-balancing provider.
- [ ] Cloudflare R2 works as final fallback.
- [ ] Provider failover works automatically.
- [ ] Database records remain consistent.
- [ ] No orphaned media are created unnecessarily.

### Backup

- [ ] Weekly automatic backup works.
- [ ] Backup contains complete database information.
- [ ] Backup is compressed.
- [ ] Backup integrity is verified.
- [ ] Backup is stored separately from the live database.
- [ ] Six-week retention is enforced.
- [ ] Older backups are automatically deleted.

### Restore

- [ ] Super Admin can view backups.
- [ ] Super Admin can download backups.
- [ ] Super Admin can verify backups.
- [ ] Super Admin can restore backups.
- [ ] Restore to another compatible database works.
- [ ] Production restore has strong confirmation.
- [ ] Safety backup is created before restore.
- [ ] Restore failures are handled safely.
- [ ] Cache is invalidated after restore.
- [ ] Application reads the restored database state.
- [ ] Restore history is recorded.

### Security

- [ ] Only authorized Super Admins can perform privileged actions.
- [ ] Secrets are never exposed.
- [ ] Credentials are never logged.
- [ ] Backup files are securely protected.
- [ ] Download links are protected/expiring where possible.
- [ ] Audit logs are complete.

### Production

- [ ] Development configuration is separated from production.
- [ ] Preproduction configuration is separated from production.
- [ ] Production scheduler works.
- [ ] Background jobs work.
- [ ] Monitoring/logging works.
- [ ] No mock data remains.
- [ ] No placeholder functionality remains.
- [ ] No TODO implementation remains for this module.

---

# FINAL OBJECTIVE

Deliver a **fully operational enterprise-grade Storage + Database Backup & Disaster Recovery module** with this architecture:

```text
                    APPLICATION
                         │
                         ▼
                STORAGE ABSTRACTION
                         │
          ┌──────────────┼──────────────┐
          ▼              ▼              ▼
     CLOUDINARY      UPLOADTHING     CLOUDFLARE R2
      PRIMARY        FALLBACK/          FINAL
                     LOAD BALANCER      FALLBACK


                    DATABASE
                       │
                       ▼
              WEEKLY BACKUP ENGINE
                       │
              ┌────────┴────────┐
              ▼                 ▼
         COMPRESS             VERIFY
              │                 │
              └────────┬────────┘
                       ▼
              SECURE BACKUP STORAGE
                       │
                       ▼
             RETAIN LAST 6 WEEKS
                       │
                       ▼
              DELETE OLDER BACKUPS


                  SUPER ADMIN
                       │
          ┌────────────┼─────────────┐
          ▼            ▼             ▼
        VIEW         EXPORT        RESTORE
          │            │             │
          └────────────┼─────────────┘
                       ▼
              SAFETY BACKUP FIRST
                       │
                       ▼
                  RESTORE DB
                       │
                       ▼
              INVALIDATE ALL CACHE
                       │
                       ▼
                HEALTH CHECKS
                       │
                       ▼
                 AUDIT + LOG
```

The final implementation must be **production-ready, secure, fault-tolerant, observable, tested, documented, and maintainable**, and must integrate cleanly with the application's existing architecture rather than existing as a disconnected standalone feature.