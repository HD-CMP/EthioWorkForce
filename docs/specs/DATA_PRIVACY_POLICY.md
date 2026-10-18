# EthioWorkForce - Data Privacy & Retention Policy

**Version**: 1.0.0  
**Date**: January 23, 2026  
**Effective Date**: January 23, 2026

---

## Table of Contents
1. [Policy Overview](#policy-overview)
2. [Data Classification](#data-classification)
3. [Data Collection](#data-collection)
4. [Data Usage](#data-usage)
5. [Data Storage & Security](#data-storage--security)
6. [Data Retention](#data-retention)
7. [Data Subject Rights](#data-subject-rights)
8. [Data Breach Response](#data-breach-response)
9. [Compliance](#compliance)

---

## 1. Policy Overview

### 1.1 Purpose

This policy establishes guidelines for collecting, processing, storing, and protecting personal data of workers, employees, and users within the EthioWorkForce system.

### 1.2 Scope

This policy applies to:
- All worker personal data
- All user account data
- Attendance records
- Payroll information
- Financial data
- Uploaded files and documents

### 1.3 Responsibilities

**Data Controller**: Organization deploying EthioWorkForce  
**Data Processor**: EthioWorkForce system administrators  
**Data Protection Officer**: [To be appointed by organization]

---

## 2. Data Classification

### 2.1 Public Data

**Examples**: Site names, work type categories, public announcements

**Protection Level**: Low  
**Access**: All authenticated users

### 2.2 Internal Data

**Examples**: Worker names, employee IDs, site assignments

**Protection Level**: Medium  
**Access**: Role-based access control

### 2.3 Confidential Data

**Examples**: Phone numbers, bank account numbers, salary amounts

**Protection Level**: High  
**Access**: Restricted to authorized roles (Admin, HR Officer)  
**Encryption**: Required at rest

### 2.4 Highly Confidential Data

**Examples**: National IDs, passwords, tax information

**Protection Level**: Critical  
**Access**: Minimum necessary access only  
**Encryption**: Required at rest and in transit  
**Logging**: All access logged in audit trail

---

## 3. Data Collection

### 3.1 Data Minimization

We collect only data that is:
- **Necessary** for workforce management
- **Relevant** to employment or payroll processing
- **Adequate** but not excessive

### 3.2 Worker Personal Data Collected

**Identity Information**:
- Full name (required)
- Employee ID (required)
- Date of birth (optional)
- Gender (optional)
- Photo (optional)

**Contact Information**:
- Phone number (optional)
- Emergency contact (optional)

**Employment Information**:
- Hire date (required)
- Site assignment (required)
- Work type/role (required)
- Employment status (required)

**Financial Information**:
- Bank name (optional)
- Bank account number (optional)
- Salary/wage rate (required for payroll)

**Government-Required Information**:
- National ID (required for tax compliance)
- Tax identification number (if applicable)

**Attendance & Performance**:
- Daily attendance records
- Overtime hours
- Leave records

### 3.3 Consent

**Explicit Consent Required For**:
- Photo capture and storage
- Processing of national ID for tax purposes
- Sharing data with third-party payment processors

**Consent Documentation**:
- Written consent form signed during onboarding
- Digital consent recorded in system with timestamp
- Consent can be withdrawn at any time

### 3.4 Data Sources

- Worker self-reporting during onboarding
- HR department data entry
- QR code scanning for attendance
- Biometric devices (if applicable)
- Site administrators

---

## 4. Data Usage

### 4.1 Lawful Basis for Processing

We process personal data based on:

1. **Contract Performance**: Processing necessary for employment contract
2. **Legal Obligation**: Tax reporting, pension contributions (ERCA requirements)
3. **Consent**: Photo storage, data sharing with banks
4. **Legitimate Interest**: Payroll processing, attendance tracking

### 4.2 Permitted Uses

- **Attendance Management**: Tracking worker presence
- **Payroll Calculation**: Computing wages and deductions
- **Tax Compliance**: Reporting to Ethiopian Revenue & Customs Authority (ERCA)
- **Pension Reporting**: Submitting pension contributions
- **Payment Processing**: Transferring salaries to bank accounts
- **Record Keeping**: Maintaining employment history
- **Dispute Resolution**: Investigating attendance disputes

### 4.3 Prohibited Uses

- Selling or renting worker data to third parties
- Using data for marketing purposes
- Sharing data with unauthorized parties
- Processing data outside Ethiopia without consent
- Using data for purposes not disclosed to workers

---

## 5. Data Storage & Security

### 5.1 Storage Locations

**Primary Database**:
- Location: On-premise server or Ethiopian data center
- Type: PostgreSQL encrypted database
- Backup: Daily encrypted backups retained for 30 days

**Mobile Devices**:
- Location: Encrypted SQLite database
- Encryption: SQLCipher with device-based key derivation
- Auto-lock: After 15 minutes of inactivity

**File Storage**:
- Location: `/var/ethioworkforce/uploads/` (server)
- Encryption: Files encrypted at rest
- Access: Restricted file system permissions

### 5.2 Data Sovereignty

**Requirement**: All data must remain within Ethiopia

**Exceptions** (with explicit consent):
- Cloud backups to approved data centers
- Technical support for critical issues

### 5.3 Encryption Standards

**At Rest**:
- Database: AES-256 encryption
- File storage: AES-256 encryption
- Backups: AES-256 encrypted archives

**In Transit**:
- HTTPS/TLS 1.2+ for all API communication
- Certificate pinning on mobile applications

**Password Storage**:
- bcrypt hashing with salt (minimum 12 rounds)
- Never stored in plain text

### 5.4 Access Controls

**Role-Based Access**:
- Super Admin: Full access
- Admin: Organization-wide access
- Site Admin: Site-specific access only
- HR Officer: Payroll and reports only
- Supervisor: Attendance marking only
- Viewer: Read-only access

**Access Logging**:
- All access to confidential data logged
- Logs retained for 7 years
- Logs reviewed monthly for anomalies

---

## 6. Data Retention

### 6.1 Retention Periods

| Data Type | Retention Period | Legal Basis |
|-----------|------------------|-------------|
| Worker personal data | 7 years after termination | Ethiopian labor law |
| Payroll records | 7 years | ERCA tax requirements |
| Attendance records | 7 years | Ethiopian labor law |
| Tax documents | 7 years | ERCA regulations |
| Pension records | 10 years | Pension agency requirements |
| Audit logs | 7 years | Compliance and security |
| Application logs | 90 days | Technical maintenance |
| Backup files | 30 days | Disaster recovery |

### 6.2 Data Deletion

**Automatic Deletion**:
- Inactive user accounts: After 2 years of inactivity (with warning)
- Old backups: After 30 days
- Application logs: After 90 days

**Manual Deletion Triggers**:
- Worker termination + 7 years
- User account closure request
- Consent withdrawal (where applicable)

**Deletion Method**:
- Secure overwriting (not just marking as deleted)
- Multi-pass deletion for highly confidential data
- Deletion confirmation logged in audit trail

### 6.3 Right to be Forgotten

**Worker Request Process**:
1. Worker submits written request to Data Protection Officer
2. DPO verifies identity
3. Legal team confirms no legal obligation to retain data
4. Data securely deleted within 30 days
5. Worker notified of completion

**Exceptions** (data that CANNOT be deleted):
- Data required by law (tax, pension records)
- Data subject to legal proceedings
- Data required for active contracts

---

## 7. Data Subject Rights

### 7.1 Right to Access

Workers have the right to:
- Request a copy of their personal data
- View what data is stored about them
- Receive data in portable format (JSON/PDF)

**Request Process**:
- Submit request via Settings → Privacy → Request My Data
- Identity verification required
- Data provided within 30 days

### 7.2 Right to Rectification

Workers can:
- Correct inaccurate personal data
- Update outdated information

**Implementation**:
- Workers can update: Phone, emergency contact, bank details
- HR/Admin required for: Name, employee ID, national ID

### 7.3 Right to Object

Workers can object to:
- Processing of optional data (photos, optional fields)
- Automated decision-making (if applicable)

**Cannot Object To**:
- Processing required by law (tax reporting)
- Processing required for employment contract

### 7.4 Right to Data Portability

Workers can request:
- Export of their complete employment record
- Attendance history in CSV/PDF format
- Payroll history in Excel format

**Process**:
- Settings → Privacy → Export My Data
- Encrypted ZIP file generated
- Download link valid for 7 days

---

## 8. Data Breach Response

### 8.1 Breach Definition

A data breach is:
- Unauthorized access to personal data
- Accidental loss or destruction of data
- Unauthorized modification of data
- Unauthorized disclosure of data

### 8.2 Breach Response Procedure

**Immediate Actions** (within 1 hour):
1. Identify and contain the breach
2. Notify Data Protection Officer
3. Preserve evidence
4. Activate incident response team

**Short-term Actions** (within 24 hours):
1. Assess scope and severity
2. Notify affected individuals if high risk
3. Notify Ethiopian Cyber Security Agency (if applicable)
4. Implement containment measures

**Long-term Actions** (within 7 days):
1. Full forensic investigation
2. Implement remediation measures
3. Update security policies
4. Conduct post-mortem review

### 8.3 Notification Requirements

**Affected Workers** (if high risk):
- Notification within 72 hours
- Description of breach
- Likely consequences
- Measures taken to address breach
- Contact point for questions

**Regulatory Authorities**:
- Notification to Ethiopian Cyber Security Agency
- Notification to ERCA (if tax data affected)

---

## 9. Compliance

### 9.1 Legal Framework

This policy complies with:
- Ethiopian Labor Proclamation
- Ethiopian Revenue & Customs Authority (ERCA) regulations
- Ethiopian Pension Agency requirements
- International privacy principles (GDPR-inspired)

### 9.2 Policy Updates

This policy is reviewed:
- Annually (minimum)
- When laws change
- After major system updates
- After data breaches

**Version Control**:
- All changes documented
- Users notified of significant changes
- Acceptance required for major changes

### 9.3 Training & Awareness

**Mandatory Training**:
- All system administrators: Annual privacy training
- HR staff: Data handling procedures
- Site administrators: Data minimization principles

**Training Topics**:
- Data classification
- Secure data handling
- Incident reporting
- Worker rights

### 9.4 Accountability

**Data Protection Officer**:
- Monitors compliance
- Conducts privacy impact assessments
- Handles data subject requests
- Reports to management

**Audit & Monitoring**:
- Quarterly privacy audits
- Monthly access log reviews
- Annual penetration testing
- Continuous security monitoring

---

## 10. Third-Party Data Sharing

### 10.1 Approved Third Parties

**Banks** (for salary transfers):
- Commercial Bank of Ethiopia (CBE)
- Dashen Bank
- Awash Bank
- Only: Name, account number, transfer amount

**Telebirr/M-Pesa** (for mobile money):
- Only: Phone number, transfer amount

**Government Agencies**:
- ERCA: Tax-related data
- Pension Agency: Pension contribution data

### 10.2 Data Processing Agreements

All third-party processors must:
- Sign data processing agreement
- Comply with this privacy policy
- Implement adequate security measures
- Allow audits of their systems
- Notify us of any breaches

### 10.3 International Transfers

**Default**: No data transferred outside Ethiopia

**If Required** (with explicit consent):
- Adequacy assessment conducted
- Standard contractual clauses signed
- Worker explicitly informed and consents

---

## 11. Worker Privacy Rights Summary

**You have the right to**:
- ✅ Know what data we collect about you
- ✅ Access your personal data
- ✅ Correct inaccurate data
- ✅ Request deletion (where legally possible)
- ✅ Object to processing (where applicable)
- ✅ Withdraw consent
- ✅ Export your data
- ✅ File a complaint

**How to Exercise Your Rights**:
- In-app: Settings → Privacy & Data Rights
- Email: privacy@ethioworkforce.et
- Phone: +251-XXX-XXX-XXX
- In-person: Speak to HR Department

---

## 12. Contact Information

**Data Protection Officer**:
- Name: [To be appointed]
- Email: dpo@ethioworkforce.et
- Phone: +251-XXX-XXX-XXX

**Privacy Inquiries**:
- Email: privacy@ethioworkforce.et
- Response time: Within 5 business days

**Data Breach Reporting**:
- Emergency: security@ethioworkforce.et
- 24/7 Hotline: +251-XXX-XXX-XXX

---

**Document Owner**: Data Protection Officer  
**Approved By**: Executive Management  
**Last Updated**: January 23, 2026  
**Next Review**: January 23, 2027
