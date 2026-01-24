# Phone-Only Setup Guide (No Server Needed!)

**Perfect For**: Starting immediately with zero cost  
**Setup Time**: 5 minutes  
**Requirements**: Android phone only

---

## Why Phone-Only Mode?

Your EthioWorkForce app is **fully functional offline**:

✅ **Store unlimited workers** (SQLite database on phone)  
✅ **Mark attendance** (QR scan or manual)  
✅ **Calculate payroll** (all calculations done locally)  
✅ **Generate reports** (Excel/PDF export)  
✅ **Backup to USB** (encrypted sneakernet sync)  

**No internet required for daily operations!**

---

## Quick Setup (5 Minutes)

### Step 1: Build the APK

```bash
cd frontend
flutter clean
flutter pub get
flutter build apk --release
```

**Output**: `build/app/outputs/flutter-apk/app-release.apk`

### Step 2: Install on Phone

**Option A - USB Cable**:
```bash
# Enable USB debugging on phone
# Connect phone to computer
adb install build/app/outputs/flutter-apk/app-release.apk
```

**Option B - File Transfer**:
1. Copy APK to phone via USB/Bluetooth/email
2. Open APK file on phone
3. Allow installation from unknown sources
4. Install

### Step 3: Configure Phone-Only Mode

1. Open app
2. Go to **Settings**
3. Enable **"Offline Mode"**
4. Disable **"Auto Sync"**
5. Set **"Backend URL"** to: `local://offline`

### Step 4: Initial Setup

1. **Add Sites**
   - Go to Sites menu
   - Add your site (e.g., "Main Office", "Construction Site A")

2. **Add Work Types**
   - Go to Work Types menu
   - Add role (e.g., "Site Engineer")
   - Set payment mode: Monthly/Daily
   - Set tax rule: Standard Employee or Daily Casual
   - Set daily rate or monthly salary

3. **Add Workers**
   - Go to Workers menu
   - Add worker with:
     - Name, Employee ID
     - Assign to site
     - Assign work type
     - Upload photo (optional)
   - Generate QR code

4. **Print QR Codes**
   - Each worker has a unique QR code
   - Click "View QR" → Screenshot
   - Print or save to show workers

---

## Daily Operations (All Offline)

### Morning: Mark Attendance

1. Open app
2. Tap **"QR Scanner"**
3. Scan each worker's QR code
4. Hear "Registered" + see green flash
5. Done!

**Or Manual Entry**:
1. Go to **Attendance** page
2. Select today's date
3. Tap **"Manual Entry"**
4. Check boxes for present workers
5. Save

### End of Day: Verify Attendance

1. Go to **Attendance** page
2. Review today's list
3. Override any mistakes (with reason)
4. Tap **"Lock Day"** to prevent changes

### End of Month: Generate Payroll

1. Go to **Payroll** page
2. Tap **"+ Generate Payroll"**
3. Select site and month
4. Tap **"Calculate"**
5. Review amounts
6. Tap **"Approve"**

### Export Payroll

1. Open approved payroll
2. Scroll to **"Payment Export"**
3. Choose format:
   - **CBE Bank** (Excel)
   - **Dashen Bank** (Excel)
   - **Awash Bank** (Excel)
   - **Telebirr** (CSV)
4. File downloads to phone
5. Share via email/WhatsApp or transfer to computer

---

## Data Backup (Weekly Recommended)

### Export to USB Drive

1. Go to **Settings** → **Sneakernet Sync**
2. Tap **"Export Data"**
3. Enter password (remember this!)
4. Select destination:
   - USB drive (via OTG cable)
   - Phone storage → copy to computer later
5. Encrypted file created: `sync_YYYYMMDD.zip`

### Store Backup Safely

- Keep on computer
- Upload to Google Drive (encrypted already)
- Store on USB flash drive
- Keep multiple copies

### Restore from Backup (If Phone Lost/Broken)

1. Install app on new phone
2. Go to **Settings** → **Sneakernet Sync**
3. Tap **"Import Data"**
4. Select backup file
5. Enter password
6. All data restored!

---

## Storage Requirements

**Typical Storage**:
- 100 workers: ~2 MB
- 1 year attendance: ~5 MB  
- Worker photos (100): ~50 MB
- **Total**: ~60 MB (very small!)

**Your phone has plenty of space.**

---

## Advanced Features (All Offline)

### Reports

**Attendance Report**:
1. Go to **Reports** → **Attendance**
2. Select date range
3. Select site
4. Tap **"Generate"**
5. Export to Excel/PDF

**Payroll Report**:
1. Go to **Reports** → **Payroll**
2. Select month
3. Export to Excel/PDF

**Pension Report**:
1. Go to **Reports** → **Pension**
2. Select period
3. Export (for ERCA submission)

### Ethiopian Calendar

1. Go to **Settings**
2. Enable **"Ethiopian Calendar"**
3. All dates show as: Meskerem 15, 2018

### Amharic Language

1. Go to **Settings**
2. Select **"አማርኛ"**
3. UI switches to Amharic

---

## Multi-Phone Setup (No Server)

If you need data on multiple phones:

### Option 1: Master Phone + USB Transfer

1. **Master phone** has all data
2. Export to USB weekly
3. Import on other phones
4. Each phone has read-only copy

### Option 2: Weekly Sync

1. Each phone works independently
2. Every Friday:
   - Phone A exports data
   - Phone B imports
   - Data merged

**Conflict Resolution**: Latest update wins

---

## Upgrading to Cloud Later

When you're ready for multi-device sync:

1. Keep using phone as before
2. Deploy backend (see FREE_DEPLOYMENT_GUIDE.md)
3. Update backend URL in settings
4. Enable sync
5. Phone uploads all data to cloud
6. Other devices can now sync

**Your data is safe on phone, cloud is just a copy!**

---

## Troubleshooting

### Q: Can I use without internet forever?

**A**: Yes! The app is fully functional offline indefinitely.

### Q: What if I lose my phone?

**A**: If you have USB backups, restore to new phone. If not, data is lost (that's why weekly backups are important).

### Q: Can multiple people use same phone?

**A**: Yes! Different users can login with different accounts. Or use a shared "site admin" account.

### Q: Battery usage?

**A**: Minimal. App only uses battery when:
- Scanning QR codes (camera)
- Generating reports (CPU)
- Normal operation: < 1% per day

### Q: Phone storage full?

**A**: Archive old data:
1. Export payroll to Excel
2. Delete old payroll from app
3. Keep Excel files on computer

### Q: How many workers can I manage?

**A**: Tested with 1000+ workers, works smoothly. Limited only by phone storage.

---

## Tips for Phone-Only Mode

✅ **Use a dedicated phone** for admin tasks  
✅ **Charge phone daily** (QR scanning uses battery)  
✅ **Backup weekly** to USB  
✅ **Keep phone secure** (screen lock)  
✅ **Train backup person** in case admin is absent  
✅ **Print QR codes** on durable material  
✅ **Store backups** in multiple locations  

---

## Cost Comparison

| Item | Cost |
|------|------|
| App installation | $0 |
| Daily operations | $0 |
| Data storage | $0 |
| Backups | $0 (USB drive ~$5 one-time) |
| **Total monthly** | **$0** |

Compare to cloud:
- Server: $0-10/month
- Database: $0-5/month
- Internet required: Yes

**Phone-only is truly free!**

---

## When to Add Cloud Server

Consider adding backend when:
- ✅ Need 3+ devices syncing
- ✅ Need remote access (view data from anywhere)
- ✅ Want automatic backups
- ✅ Have reliable internet
- ✅ Team is growing

**Until then, phone-only works perfectly!**

---

## Real-World Example

**Scenario**: Construction site with 50 daily laborers + 5 engineers

**Setup** (one-time):
- Install app on site manager's phone
- Add 55 workers
- Print 55 QR codes
- Give QR to each worker

**Daily** (5 minutes):
- Morning: Scan QR codes as workers arrive
- Evening: Lock attendance

**Monthly** (30 minutes):
- Generate payroll
- Export to CBE bank format
- Send Excel to accountant
- Accountant processes payment

**Total cost**: $0  
**Total time**: 2 hours/month  
**Savings vs manual**: 20+ hours/month  

---

## 🎉 You're Ready!

No server needed. No internet needed. No monthly costs.

**Just build, install, and start managing your workforce!**

---

**Questions? Issues?**
- GitHub: [your-repo]/issues
- Email: support@ethioworkforce.et

---

**Enjoy your free, offline-first workforce management system! 📱**
