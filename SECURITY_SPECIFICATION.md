# EthioWorkForce - Security & Access Control Specification

**Version**: 1.0.0  
**Date**: January 23, 2026  
**Status**: Production Specification

---

## Table of Contents
1. [Authentication System](#authentication-system)
2. [Authorization & Role-Based Access Control](#authorization--role-based-access-control)
3. [Data Encryption](#data-encryption)
4. [Audit Trail & Logging](#audit-trail--logging)
5. [Session Management](#session-management)
6. [Security Best Practices](#security-best-practices)
7. [Compliance & Standards](#compliance--standards)

---

## 1. Authentication System

### 1.1 User Authentication Flow

**Technology**: JWT (JSON Web Tokens) with RSA-256 encryption

**Authentication Process**:
1. User submits credentials (username + password)
2. Backend validates against bcrypt-hashed password in database
3. System generates two tokens:
   - **Access Token**: Short-lived (30 minutes), used for API requests
   - **Refresh Token**: Long-lived (7 days), used to obtain new access tokens
4. Tokens stored securely on client (flutter_secure_storage)

**Password Requirements**:
- Minimum 8 characters
- Must contain: uppercase, lowercase, number, special character
- Cannot contain username
- Cannot be previously used password (stores 5 password history)
- Must change every 90 days (configurable)

**Account Lockout Policy**:
- Maximum 5 failed login attempts
- Lockout duration: 15 minutes
- Requires admin intervention after 3 lockouts in 24 hours

### 1.2 Multi-Factor Authentication (MFA)

**Status**: Phase 2 Enhancement (Optional for v1.0)

**Supported Methods**:
- SMS-based OTP (primary for Ethiopia context)
- Authenticator apps (Google Authenticator, Microsoft Authenticator)
- Email-based OTP (fallback)

**MFA Enforcement**:
- **Mandatory** for: Super Admin, Admin, HR Officer
- **Optional** for: Site Admin, Supervisor, Viewer

---

## 2. Authorization & Role-Based Access Control (RBAC)

### 2.1 User Roles & Permissions Matrix

| Role | Code | Description | User Management | Site Management | Worker CRUD | Attendance | Payroll | Reports | System Config |
|------|------|-------------|-----------------|-----------------|-------------|------------|---------|---------|---------------|
| **Super Admin** | `super_admin` | Full system access | ✅ Full | ✅ Full | ✅ Full | ✅ Full | ✅ Full | ✅ Full | ✅ Full |
| **Admin** | `admin` | Organization-wide management | ✅ Create/Edit Users | ✅ All Sites | ✅ Full | ✅ Verify/Override | ✅ Approve/Generate | ✅ All Reports | ✅ Work Types |
| **Site Admin** | `site_admin` | Site-level authority | ❌ No | ✅ Assigned Site Only | ✅ Site Workers Only | ✅ Verify/Override | ✅ View Only | ✅ Site Reports | ❌ No |
| **HR Officer** | `hr_officer` | Payroll & reporting | ❌ No | ✅ View All | ✅ View All | ✅ View All | ✅ Generate/Export | ✅ All Reports | ❌ No |
| **Supervisor** | `supervisor` | Field operations | ❌ No | ✅ Assigned Site Only | ✅ View Site Workers | ✅ Mark Attendance | ❌ No | ✅ Attendance Reports | ❌ No |
| **Viewer** | `viewer` | Read-only access | ❌ No | ✅ View Assigned | ✅ View Assigned | ✅ View Only | ❌ No | ✅ View Only | ❌ No |

### 2.2 Permission Enforcement

**API Level** (Backend):
```python
@router.get("/payroll/{id}")
def get_payroll(
    id: int,
    current_user: User = Depends(require_role([UserRole.ADMIN, UserRole.HR_OFFICER]))
):
    # Only Admins and HR Officers can access payroll details
```

**UI Level** (Frontend):
- Role-based widget rendering
- Disabled buttons for insufficient permissions
- Hidden menu items based on role

**Data Level** (Database):
- Row-level security for Site-specific data
- Automatic filtering based on user's assigned sites

### 2.3 Special Permissions

**Attendance Override**:
- **Who**: Admin, Site Admin
- **Requires**: Mandatory text reason (min 10 characters)
- **Logged**: Audit trail with timestamp, user, reason

**Payroll Approval**:
- **Who**: Admin only
- **Workflow**: Draft → Pending → Approved → Paid
- **Cannot Reverse**: Once "Paid" status set, cannot be edited (archival only)

**Worker Deletion**:
- **Soft Delete**: Workers never truly deleted (is_active = false)
- **Who**: Admin only
- **Restriction**: Cannot delete if worker has attendance/payroll records

---

## 3. Data Encryption

### 3.1 Data At Rest

**Database Encryption**:
- PostgreSQL with transparent data encryption (TDE)
- Encrypted backups with AES-256
- Sensitive fields additionally encrypted:
  - `hashed_password` (bcrypt)
  - `national_id` (AES-256)
  - `bank_account_number` (AES-256)

**Mobile Database**:
- SQLite database encrypted with SQLCipher
- Encryption key derived from device security credentials
- Auto-lock after 15 minutes of inactivity

### 3.2 Data In Transit

**API Communication**:
- **Production**: HTTPS only (TLS 1.2+)
- **Certificate**: Let's Encrypt wildcard certificate
- **HSTS**: Strict-Transport-Security header enabled
- **Certificate Pinning**: Mobile app pins backend certificate

**Sneakernet Sync**:
- Exported files encrypted with AES-256
- Password-based key derivation (PBKDF2, 100,000 iterations)
- SHA-256 checksum for integrity verification

### 3.3 File Storage Security

**Uploaded Files**:
- Stored outside web root (`/var/ethioworkforce/uploads/`)
- Random UUID filenames (prevents enumeration)
- File type validation (whitelist: jpg, png, pdf)
- Maximum file size: 5MB per file
- Scanned for malware (ClamAV integration recommended)

---

## 4. Audit Trail & Logging

### 4.1 Audit Log Schema

**Logged Events**:
- User login/logout
- Failed login attempts
- User creation/modification/deactivation
- Worker CRUD operations
- Attendance verification/override
- Payroll approval/payment execution
- Report generation/export
- Settings changes

**Audit Log Fields**:
```python
{
    "id": 123,
    "user_id": 5,
    "action": "ATTENDANCE_OVERRIDE",
    "entity_type": "attendance",
    "entity_id": 456,
    "old_value": {"status": "present"},
    "new_value": {"status": "absent", "reason": "Worker left early - sick"},
    "ip_address": "192.168.1.50",
    "user_agent": "EthioWorkforce Mobile v1.0.0",
    "timestamp": "2026-01-23T14:30:00+03:00"
}
```

### 4.2 Log Retention

- **Audit Logs**: Retained for 7 years (Ethiopian legal requirement)
- **Application Logs**: Retained for 90 days
- **Access Logs**: Retained for 1 year
- **Log Rotation**: Daily rotation, compressed archives

### 4.3 Log Security

- Write-once storage (cannot be modified after creation)
- Separate database/file system from application data
- Restricted access (Super Admin only)
- Encrypted at rest
- Regular integrity checks (checksum verification)

---

## 5. Session Management

### 5.1 Token Lifecycle

**Access Token**:
- Expiry: 30 minutes
- Stored: Mobile - Secure Storage, Web - httpOnly cookie
- Automatically refreshed when within 5 minutes of expiry

**Refresh Token**:
- Expiry: 7 days
- Rotation: New refresh token issued on each use (prevents replay attacks)
- Revocation: Stored revocation list in Redis

### 5.2 Session Invalidation

**Automatic Logout**:
- Access token expiry
- Refresh token expiry
- User account deactivation
- Password change
- Role change (security-sensitive)

**Manual Logout**:
- User-initiated logout invalidates both tokens
- "Logout All Devices" option available in settings

**Forced Logout**:
- Admin can force logout specific user
- All sessions terminated immediately

---

## 6. Security Best Practices

### 6.1 Input Validation

**All User Inputs**:
- Server-side validation (never trust client)
- Parameterized SQL queries (prevents SQL injection)
- HTML escaping (prevents XSS)
- File upload validation (type, size, content)

### 6.2 Rate Limiting

**Login Endpoint**: 5 attempts per 15 minutes per IP
**API Endpoints**: 100 requests per minute per user
**File Upload**: 10 uploads per hour per user
**Report Generation**: 20 reports per hour per user

### 6.3 CORS Configuration

**Production**:
```python
CORS_ORIGINS = [
    "https://app.ethioworkforce.com",
    "https://admin.ethioworkforce.com"
]
```

**Development**:
```python
CORS_ORIGINS = [
    "http://localhost:3000",
    "http://localhost:8080"
]
```

### 6.4 Security Headers

```http
Strict-Transport-Security: max-age=31536000; includeSubDomains
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
Content-Security-Policy: default-src 'self'
Referrer-Policy: no-referrer
```

---

## 7. Compliance & Standards

### 7.1 Ethiopian Legal Requirements

**Data Sovereignty**:
- All data stored on Ethiopian servers (or on-premise)
- No data transferred outside Ethiopia without explicit consent
- Compliant with Ethiopian Data Protection Proclamation (when enacted)

**Tax & Pension Compliance**:
- ERCA tax calculation accuracy audited annually
- Pension contributions verified by government auditors
- Payroll records retained for 7 years

### 7.2 Industry Standards

**Compliance Frameworks**:
- ISO 27001 principles (Information Security Management)
- OWASP Top 10 protection
- GDPR principles (privacy by design, data minimization)

### 7.3 Security Certifications (Roadmap)

- [ ] ISO 27001 Certification (Year 2)
- [ ] SOC 2 Type II (Year 2)
- [ ] Ethiopian Cyber Security Agency approval (Year 1)

---

## 8. Incident Response Plan

### 8.1 Security Incident Classification

**Critical (P1)**: Data breach, unauthorized access to payroll, system compromise
**High (P2)**: Repeated failed login attacks, suspected malware, unauthorized data export
**Medium (P3)**: Single unauthorized access attempt, policy violation
**Low (P4)**: Suspicious activity, minor configuration issues

### 8.2 Response Procedures

**Immediate Actions (0-1 hour)**:
1. Identify and isolate affected systems
2. Notify security team and management
3. Preserve evidence (logs, snapshots)
4. Activate incident response team

**Short-term (1-24 hours)**:
1. Conduct preliminary investigation
2. Implement containment measures
3. Notify affected users (if applicable)
4. Document all actions

**Long-term (1-7 days)**:
1. Full forensic analysis
2. Root cause identification
3. Implement permanent fixes
4. Update security policies
5. Conduct post-mortem

### 8.3 Contact Information

**Security Team**:
- Email: security@ethioworkforce.et
- Phone: +251-XXX-XXX-XXX (24/7)
- Emergency Escalation: CTO, CEO

**External Contacts**:
- Ethiopian Cyber Security Agency
- Law enforcement (if criminal activity)
- Legal counsel

---

## 9. Regular Security Maintenance

### 9.1 Periodic Activities

**Daily**:
- Monitor security logs for anomalies
- Check failed login attempts

**Weekly**:
- Review user access levels
- Audit file uploads

**Monthly**:
- Security patch updates
- Access review (remove inactive users)
- Backup restoration test

**Quarterly**:
- Penetration testing
- Security training for staff
- Policy review and update

**Annually**:
- Full security audit
- Disaster recovery drill
- Password rotation enforcement

---

## 10. Developer Security Guidelines

### 10.1 Secure Coding Practices

**Never**:
- Hard-code passwords, API keys, or secrets
- Log sensitive data (passwords, tokens, national IDs)
- Trust user input without validation
- Use MD5 or SHA1 for password hashing
- Expose detailed error messages to users

**Always**:
- Use parameterized queries
- Validate and sanitize all inputs
- Use bcrypt for password hashing
- Implement least privilege principle
- Keep dependencies updated

### 10.2 Code Review Checklist

- [ ] No hardcoded secrets
- [ ] All inputs validated
- [ ] SQL injection prevention
- [ ] XSS protection implemented
- [ ] Authorization checks present
- [ ] Sensitive data encrypted
- [ ] Error handling doesn't leak info
- [ ] Logging doesn't expose secrets

---

**Document Owner**: EthioWorkForce Security Team  
**Review Cycle**: Quarterly  
**Last Review**: January 23, 2026  
**Next Review**: April 23, 2026
