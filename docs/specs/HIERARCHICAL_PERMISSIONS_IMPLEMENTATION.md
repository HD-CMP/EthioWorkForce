# Hierarchical Permissions & User Approval System

## Overview
A professional, world-class hierarchical permission system has been implemented for EthioWorkforce with role-based access control (RBAC), site-based data isolation, and user registration approval workflows.

## Key Features

### 1. **User Role Hierarchy**
- **SUPER_ADMIN**: Full system access, can approve user registrations, manage all users and sites
- **ADMIN**: Can manage users (except SUPER_ADMIN), access all sites, submit registration requests
- **SITE_ADMIN**: Can manage users for assigned sites only, submit registration requests
- **SUPERVISOR**: Site-level access, view and manage assigned site data
- **HR_OFFICER**: HR operations within assigned sites
- **VIEWER**: Read-only access to assigned sites

### 2. **User Registration Approval Workflow**

#### How It Works:
1. **ADMIN** or **SITE_ADMIN** submits a user registration request via `/api/v1/registration/request`
2. Request is stored with status `PENDING`
3. **SUPER_ADMIN** reviews pending requests via `/api/v1/registration/requests/pending`
4. **SUPER_ADMIN** approves or rejects via `/api/v1/registration/approve`
5. Upon approval, user is created and can be assigned to sites

#### Role Restrictions:
- **SITE_ADMIN** cannot request **SUPER_ADMIN** or **ADMIN** roles
- **ADMIN** cannot request **SUPER_ADMIN** role
- Only **SUPER_ADMIN** can approve/reject requests

### 3. **Site-Based Data Isolation**

#### User-Site Assignments:
- Users can be assigned to multiple sites via `UserSiteAssignment`
- One site can be marked as `is_primary` for each user
- **SUPER_ADMIN** and **ADMIN** have access to ALL sites
- Other roles only access their assigned sites

#### Data Filtering:
- **Workers**: Only see workers from assigned sites
- **Attendance**: Only see/create attendance for assigned sites
- **Payroll**: Only process payroll for assigned sites
- **Reports**: Only export data from accessible sites

### 4. **Permission Checks**

#### Endpoint-Level Protection:
All endpoints now enforce:
- Authentication (valid JWT token)
- Role-based authorization
- Site-based access control

#### Example Flows:

**Creating Attendance:**
1. User must be authenticated
2. User must have access to the site
3. Worker must belong to that site
4. Attendance is created and linked to site

**Viewing Workers:**
1. User must be authenticated
2. Query filtered by user's accessible sites
3. SUPER_ADMIN/ADMIN see all workers
4. SITE_ADMIN sees only their site's workers

## API Endpoints

### Registration Management
- `POST /api/v1/registration/request` - Submit user registration request
- `GET /api/v1/registration/requests` - List your registration requests
- `GET /api/v1/registration/requests/pending` - List pending requests (SUPER_ADMIN only)
- `POST /api/v1/registration/approve` - Approve/reject request (SUPER_ADMIN only)
- `DELETE /api/v1/registration/requests/{id}` - Cancel pending request

### User-Site Assignment
- `GET /api/v1/users/{user_id}/sites` - Get user's site assignments
- `POST /api/v1/users/{user_id}/sites` - Assign user to site (SUPER_ADMIN/ADMIN)
- `DELETE /api/v1/users/{user_id}/sites/{site_id}` - Remove site assignment

### Updated Endpoints with Permissions
- All `/api/v1/attendance/*` endpoints - Site-filtered
- All `/api/v1/workers/*` endpoints - Site-filtered
- All `/api/v1/payroll/*` endpoints - Site-filtered
- All `/api/v1/users/*` endpoints - Hierarchical permissions

## Database Schema

### New Tables:

#### `user_registration_requests`
- `id`: Primary key
- `username`, `email`, `full_name`: User details
- `role`: Requested role
- `hashed_password`: Pre-hashed password
- `requested_by_id`: Who requested (ADMIN/SITE_ADMIN)
- `approved_by_id`: Who approved (SUPER_ADMIN)
- `status`: PENDING | APPROVED | REJECTED | CANCELLED
- `request_reason`: Why this user is needed
- `approval_notes`: Notes from SUPER_ADMIN
- `reviewed_at`: Timestamp of approval/rejection

#### `user_site_assignments`
- `id`: Primary key
- `user_id`: Foreign key to users
- `site_id`: Foreign key to sites
- `is_primary`: Boolean flag for primary site

### Updated Tables:

#### `users`
- Added relationship: `site_assignments`

#### `sites`
- Added relationship: `user_assignments`

## Setup Instructions

### 1. Run Database Migration
```bash
cd backend
alembic upgrade head
```

### 2. Initialize Database with Sample Data
```bash
python scripts/init_db.py
```

This creates:
- **SUPER_ADMIN**: username=`admin`, password=`admin123`
- **ADMIN**: username=`adminuser`, password=`admin123`
- **SITE_ADMIN**: username=`siteadmin`, password=`siteadmin123`
- Two sites: Bole Construction Site, Piassa Development Site
- Site assignments for ADMIN and SITE_ADMIN

### 3. Test the System

#### Example 1: SITE_ADMIN Requests New User
```bash
# Login as SITE_ADMIN
POST /api/v1/auth/login
{
  "username": "siteadmin",
  "password": "siteadmin123"
}

# Request new user
POST /api/v1/registration/request
{
  "username": "newworker",
  "email": "newworker@example.com",
  "full_name": "New Worker",
  "password": "password123",
  "role": "SUPERVISOR",
  "request_reason": "Need supervisor for Bole site"
}
```

#### Example 2: SUPER_ADMIN Approves Request
```bash
# Login as SUPER_ADMIN
POST /api/v1/auth/login
{
  "username": "admin",
  "password": "admin123"
}

# View pending requests
GET /api/v1/registration/requests/pending

# Approve and assign to site
POST /api/v1/registration/approve
{
  "request_id": 1,
  "approved": true,
  "approval_notes": "Approved - needed for Bole site",
  "site_ids": [1]
}
```

#### Example 3: ADMIN Assigns User to Multiple Sites
```bash
# Assign user to additional site
POST /api/v1/users/2/sites
{
  "site_id": 2,
  "is_primary": false
}
```

## Security Features

### 1. **Authentication**
- All endpoints require valid JWT Bearer token
- Tokens expire after 30 minutes (configurable)

### 2. **Authorization**
- Role-based permission checks on every endpoint
- Hierarchical role validation (SITE_ADMIN cannot manage ADMIN)

### 3. **Data Isolation**
- Site-based filtering prevents cross-site data leakage
- Users only see data from their assigned sites

### 4. **Audit Trail**
- All user registration requests tracked
- Approval/rejection history maintained
- Timestamps for all critical actions

## Permission Matrix

| Action | SUPER_ADMIN | ADMIN | SITE_ADMIN | SUPERVISOR | HR_OFFICER | VIEWER |
|--------|-------------|-------|------------|------------|------------|--------|
| Approve user registrations | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Request user registration | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| View all sites | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| View assigned sites | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Create attendance (own sites) | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| Approve payroll (own sites) | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| Assign users to sites | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Delete users | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Change user roles | ✅ | ✅* | ❌ | ❌ | ❌ | ❌ |

*ADMIN cannot assign SUPER_ADMIN role

## Best Practices

### 1. **Role Assignment**
- Assign minimum required role for each user
- Use SITE_ADMIN for site managers
- Reserve ADMIN for multi-site managers
- Use SUPER_ADMIN sparingly (1-2 users max)

### 2. **Site Assignments**
- Always assign at least one site to non-admin users
- Mark one site as primary for each user
- Review site assignments quarterly

### 3. **Registration Workflow**
- Include detailed `request_reason` when requesting users
- SUPER_ADMIN should review requests within 24 hours
- Use `approval_notes` to document decisions

### 4. **Security**
- Change default passwords immediately
- Use strong passwords (min 8 characters)
- Rotate SUPER_ADMIN credentials monthly
- Enable 2FA (when implemented)

## Troubleshooting

### Issue: "You don't have access to this site"
**Solution**: User needs to be assigned to the site via User-Site Assignment endpoint

### Issue: "Insufficient permissions"
**Solution**: User's role doesn't have required permissions. Contact SUPER_ADMIN.

### Issue: "Only SUPER_ADMIN can perform this action"
**Solution**: This action (approving users, deleting users) requires SUPER_ADMIN role.

### Issue: Registration request shows as PENDING forever
**Solution**: Contact SUPER_ADMIN to review and approve/reject the request.

## Migration from Old System

If upgrading from a system without hierarchical permissions:

1. Run migration: `alembic upgrade head`
2. Assign existing users to sites:
   ```python
   # For each user, create UserSiteAssignment records
   POST /api/v1/users/{user_id}/sites
   ```
3. Review and update user roles as needed
4. Test permission system with each role
5. Train users on new registration workflow

## Future Enhancements

- [ ] Email notifications for registration approvals
- [ ] Bulk user registration import
- [ ] Site hierarchy (parent-child sites)
- [ ] Custom permission templates
- [ ] Activity logging and audit reports
- [ ] Two-factor authentication (2FA)
- [ ] SSO integration

## Support

For issues or questions:
1. Check the troubleshooting section
2. Review API documentation at `/api/docs`
3. Contact system administrator
