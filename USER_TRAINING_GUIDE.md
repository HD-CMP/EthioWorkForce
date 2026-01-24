# EthioWorkForce - User Training Guide

**Version**: 1.0.0  
**Date**: January 23, 2026  
**Languages**: English | አማርኛ (Amharic)

---

## Training Programs by Role

### 1. Administrator Training (2-day program)

**Target Audience**: Site Admins, HR Officers, System Administrators

**Day 1 - System Overview & Worker Management**

#### Session 1: System Introduction (2 hours)
- ✅ What is EthioWorkForce?
- ✅ Offline-first architecture explained
- ✅ User roles and permissions
- ✅ Ethiopian calendar integration
- ✅ Hands-on: System login and navigation

#### Session 2: Worker Management (3 hours)
- ✅ Adding new workers
- ✅ Assigning sites and work types
- ✅ Uploading worker photos
- ✅ Generating QR codes
- ✅ Managing worker status (active/inactive)
- ✅ **Practice Exercise**: Add 10 test workers

**Day 2 - Attendance & Payroll**

#### Session 3: Attendance Management (3 hours)
- ✅ QR code scanning
- ✅ Manual attendance entry
- ✅ Verifying daily attendance
- ✅ Overriding attendance records
- ✅ Locking attendance days
- ✅ **Practice Exercise**: Process one month of attendance

#### Session 4: Payroll Processing (3 hours)
- ✅ Understanding daily vs. permanent worker logic
- ✅ Generating monthly payroll
- ✅ Reviewing payroll reports
- ✅ Exporting to bank formats (CBE, Dashen, Awash)
- ✅ Generating pension reports
- ✅ **Practice Exercise**: Generate complete payroll for test data

---

### 2. Supervisor Training (1-day program)

**Target Audience**: Field Supervisors, Site Managers

#### Session 1: Mobile App Basics (2 hours)
- ✅ Installing the mobile app
- ✅ Logging in
- ✅ Navigating the interface
- ✅ Switching between English/Amharic
- ✅ Ethiopian vs. Gregorian calendar toggle

#### Session 2: QR Scanning & Attendance (3 hours)
- ✅ How QR codes work
- ✅ Scanning worker QR codes
- ✅ Audio/visual feedback understanding
- ✅ Marking attendance manually (if QR fails)
- ✅ Viewing daily attendance summary
- ✅ **Practice Exercise**: Scan 20 workers

#### Session 3: Offline Mode & Syncing (2 hours)
- ✅ Working without internet
- ✅ Understanding sync status
- ✅ Manual sync trigger
- ✅ Conflict resolution basics
- ✅ **Practice Exercise**: Offline attendance marking

---

### 3. HR Officer Training (1-day program)

**Target Audience**: Payroll Processors, HR Staff

#### Session 1: Payroll Fundamentals (2 hours)
- ✅ Daily worker vs. permanent staff taxation
- ✅ Ethiopian tax brackets (ERCA)
- ✅ Pension calculations (7% employee + 11% employer)
- ✅ Overtime calculations

#### Session 2: Payment Processing (3 hours)
- ✅ Generating payroll
- ✅ Exporting for bank transfers
- ✅ Telebirr/M-Pesa export formats
- ✅ Cash payment sheets
- ✅ Digital signature collection

#### Session 3: Reporting (2 hours)
- ✅ Generating pension reports (Excel/PDF)
- ✅ Attendance reports
- ✅ Payroll summaries
- ✅ **Practice Exercise**: Complete end-to-end payroll cycle

---

### 4. Worker Orientation (30 minutes)

**Target Audience**: All Workers

#### Quick Training Session
- ✅ What is the QR code?
- ✅ How to check in daily
- ✅ What to do if QR is lost/damaged
- ✅ How to view attendance history (if app access)
- ✅ Privacy: What data is collected

---

## Step-by-Step Procedures

### Procedure 1: Adding a New Worker

**Role Required**: Admin or Site Admin

**Steps**:
1. Navigate to **Workers** menu
2. Click **+ Add Worker** button
3. Fill required fields:
   - Employee ID: `EMP001` (unique)
   - Full Name: `Abebe Kebede`
   - Site: Select from dropdown
   - Work Type: Select from dropdown
   - Hire Date: Use calendar picker
4. Optional fields:
   - Upload photo (JPG/PNG, max 5MB)
   - Phone number
   - National ID
   - Bank details
5. Click **Save**
6. Generate QR code by clicking **Generate QR Code** button
7. Print QR code for worker

**Common Errors**:
- ❌ **"Employee ID already exists"**: Use a different ID
- ❌ **"Site is required"**: Select a site from dropdown

---

### Procedure 2: Marking Daily Attendance (QR Scan)

**Role Required**: Supervisor

**Steps**:
1. Open mobile app
2. Tap **QR Scanner** from home screen
3. Point camera at worker's QR code
4. Wait for:
   - ✅ Green flash = Success
   - 🔊 "Registered" voice announcement (Amharic: "ተመዝግቧል")
5. Worker name appears on screen for 2 seconds
6. Repeat for next worker

**Troubleshooting**:
- 📷 **QR not scanning**: Check camera focus, ensure good lighting
- ⚠️ **"Worker already checked in today"**: Normal, worker scanned twice
- ❌ **"QR code invalid"**: QR may be damaged, use manual entry

---

### Procedure 3: Manual Attendance Entry

**Role Required**: Supervisor or Admin

**Steps**:
1. Navigate to **Attendance** page
2. Select date using calendar
3. Click **Manual Entry** button
4. Worker list appears with checkboxes
5. Check boxes for present workers
6. Click **Save Attendance**
7. Confirm action

---

### Procedure 4: Verifying Daily Attendance

**Role Required**: Site Admin or Admin

**Steps**:
1. Navigate to **Attendance** page
2. Select date
3. Review list of workers marked present/absent
4. For corrections:
   - Click **Override** next to worker name
   - Select new status (Present/Absent/Excused)
   - **Must enter reason** (min 10 characters)
   - Click **Save Override**
5. Once satisfied, click **Lock Day**
6. Locked days cannot be edited (prevents fraud)

---

### Procedure 5: Generating Monthly Payroll

**Role Required**: Admin or HR Officer

**Steps**:
1. Navigate to **Payroll** page
2. Click **+ Generate Payroll**
3. Select:
   - Site (or "All Sites")
   - Period: Month/Year (e.g., January 2026)
4. Click **Calculate**
5. System processes:
   - Counts attendance days per worker
   - Calculates daily workers: `Days × Daily Rate`
   - Calculates permanent staff: `Salary - Tax - Pension`
6. Review payroll summary
7. Click **Approve Payroll**

---

### Procedure 6: Exporting Payroll for Bank Transfer

**Role Required**: Admin or HR Officer

**Steps**:
1. Open approved payroll
2. Scroll to **Payment Export** section
3. Select bank format:
   - **CBE** (Commercial Bank of Ethiopia)
   - **Dashen Bank**
   - **Awash Bank**
4. Click **Export to Excel**
5. Excel file downloads automatically
6. Open file, verify data
7. Upload to bank's online portal

**Excel Format** (CBE example):
```
Account Number | Beneficiary Name | Amount | Reference
1234567890     | Abebe Kebede    | 8500   | Salary Jan 2026
```

---

### Procedure 7: USB Sync (Sneakernet Mode)

**Role Required**: Site Admin

**When**: Site has no internet for 30+ days

**Steps**:
1. On mobile app, navigate to **Settings**
2. Tap **Sneakernet Sync**
3. Tap **Export Data to USB**
4. Enter password (min 8 characters)
5. Connect USB drive to phone
6. Select USB drive destination
7. File saved as: `sync_YYYYMMDD_encrypted.zip`
8. Transport USB to head office
9. Head office admin:
   - Navigates to **Sync → Import**
   - Selects USB file
   - Enters password
   - Clicks **Import and Merge**
10. Data synced to central system

---

## Training Assessment

### Administrator Assessment (20 questions)

**Sample Questions**:

1. ✅ What are the TWO types of workers in EthioWorkForce?
   - Answer: Daily/Casual workers and Permanent/Contract workers

2. ✅ Daily workers receive how much tax deduction?
   - Answer: Zero (0%)

3. ✅ What is the employee pension contribution rate?
   - Answer: 7%

4. ✅ Can you edit attendance after locking a day?
   - Answer: No

5. ✅ What is the minimum reason length for attendance override?
   - Answer: 10 characters

**Pass Score**: 80% (16/20 correct)

---

### Supervisor Assessment (Practical)

**Task**: Mark attendance for 10 workers using QR scan

**Grading Criteria**:
- ✅ Successfully scans 9/10 codes (90%)
- ✅ Identifies when QR is invalid
- ✅ Knows how to switch to manual entry
- ✅ Verifies attendance summary

---

## Common Questions & Answers

**Q1: What happens if I lose my QR code?**  
**A**: Contact your site admin to generate a new QR code. Your old QR will be deactivated for security.

**Q2: Can I edit payroll after it's marked as "Paid"?**  
**A**: No. Once paid, payroll is locked. Any corrections require creating a supplementary payment.

**Q3: How do I know if my attendance was marked?**  
**A**: You'll hear a voice confirmation and see a green flash when successfully checked in.

**Q4: What if the app doesn't sync?**  
**A**: The app works offline. Data will auto-sync when internet returns. For prolonged outages, use USB sync.

**Q5: Can I change a worker's role mid-month?**  
**A**: Yes, use the **Role Change Request** feature. The change takes effect from a specified date.

**Q6: How long is payroll data stored?**  
**A**: 7 years, as required by Ethiopian law.

**Q7: Can workers see their own payroll data?**  
**A**: Only if given Viewer role access. By default, workers cannot login to the system.

**Q8: What happens if I mark attendance for the wrong date?**  
**A**: Admins can override or delete incorrect attendance records (with mandatory reason).

**Q9: Is the mobile app available on iOS?**  
**A**: Currently Android only. iOS version planned for future release.

**Q10: How do I report a bug or issue?**  
**A**: Contact support@ethioworkforce.et or call the helpline.

---

## Training Resources

### Video Tutorials (to be created)
- [ ] System Introduction (15 min)
- [ ] Worker Management (20 min)
- [ ] QR Scanning Tutorial (10 min)
- [ ] Payroll Processing (25 min)
- [ ] Offline Sync Walkthrough (15 min)

### Downloadable Resources
- [ ] Quick Reference Cards (PDF)
- [ ] QR Code Templates
- [ ] Payroll Calculation Cheat Sheet
- [ ] Troubleshooting Guide

---

## Support Contacts

**Technical Support**:
- Email: support@ethioworkforce.et
- Phone: +251-XXX-XXX-XXX
- Hours: Mon-Fri, 8:00 AM - 5:00 PM

**Training Inquiries**:
- Email: training@ethioworkforce.et

**Emergency (System Down)**:
- 24/7 Hotline: +251-XXX-XXX-XXX

---

**Document Owner**: EthioWorkForce Training Team  
**Last Updated**: January 23, 2026  
**Next Review**: April 23, 2026
