# EthioWorkForce Production Deployment Checklist

## Pre-Deployment Checklist

### Backend API

- [ ] **Environment Configuration**
  - [ ] Create production `.env` file with secure credentials
  - [ ] Generate strong `SECRET_KEY` (minimum 32 characters)
  - [ ] Configure production `DATABASE_URL`
  - [ ] Set `ENVIRONMENT=production` and `DEBUG=false`
  - [ ] Update `CORS_ORIGINS` with production frontend URL

- [ ] **Database**
  - [ ] PostgreSQL installed and running
  - [ ] Production database created
  - [ ] Database user created with appropriate permissions
  - [ ] Run all migrations: `alembic upgrade head`
  - [ ] Verify database schema is up to date
  - [ ] Configure automated daily backups

- [ ] **Security**
  - [ ] SSL/TLS certificate installed (Let's Encrypt recommended)
  - [ ] HTTPS enabled on all endpoints
  - [ ] Firewall configured (allow ports 80, 443, 22 only)
  - [ ] SSH key-based authentication enabled
  - [ ] Password authentication disabled for SSH
  - [ ] Database not exposed to public internet
  - [ ] API rate limiting configured

- [ ] **Server Setup**
  - [ ] Nginx installed and configured as reverse proxy
  - [ ] Systemd service created for automatic startup
  - [ ] Application runs as non-root user (www-data)
  - [ ] Log directory created: `/var/log/ethioworkforce/`
  - [ ] Log rotation configured
  - [ ] Server timezone set correctly (Africa/Addis_Ababa)

- [ ] **Application Testing**
  - [ ] Health endpoint returns 200 OK: `GET /health`
  - [ ] Authentication endpoint working: `POST /api/v1/auth/login`
  - [ ] All API endpoints tested with Postman/curl
  - [ ] File upload functionality tested
  - [ ] Export functionality tested (CBE, Dashen, Awash, Telebirr)
  - [ ] Pension report generation tested (Excel and PDF)
  - [ ] QR code generation tested

### Mobile Application (Android)

- [ ] **Configuration**
  - [ ] Update `pubspec.yaml` version number
  - [ ] Set production backend URL in DioClient or Settings
  - [ ] App icon configured (1024x1024 PNG)
  - [ ] Splash screen configured
  - [ ] App name finalized in AndroidManifest.xml and Info.plist
  - [ ] Package name set: `com.ethioworkforce.app`

- [ ] **Permissions**
  - [ ] Camera permission added to AndroidManifest.xml
  - [ ] Storage permissions added to AndroidManifest.xml
  - [ ] Internet permission added to AndroidManifest.xml
  - [ ] Camera permission added to iOS Info.plist
  - [ ] Photo library permission added to iOS Info.plist

- [ ] **Build Configuration**
  - [ ] Keystore generated for app signing
  - [ ] `key.properties` file created with keystore details
  - [ ] ProGuard rules configured (if using code obfuscation)
  - [ ] Release build configuration updated in `build.gradle`

- [ ] **Assets**
  - [ ] All translation files complete (`en.json`, `am.json`)
  - [ ] App icons in all required sizes generated
  - [ ] Audio files added or graceful fallback confirmed
  - [ ] All images optimized (compressed)

- [ ] **Testing**
  - [ ] App runs successfully on physical Android device
  - [ ] QR code scanning works correctly
  - [ ] Attendance marking tested end-to-end
  - [ ] Offline mode tested (enable offline, use app, sync later)
  - [ ] Sneakernet export/import tested with USB transfer
  - [ ] All payment export buttons functional
  - [ ] Localization tested (switch between English/Amharic)
  - [ ] Ethiopian calendar toggle tested
  - [ ] Audio feedback tested (TTS announcements)
  - [ ] Visual feedback overlays working
  - [ ] Settings page all controls functional
  - [ ] Backend URL configuration working
  - [ ] No crashes during normal usage (30+ minutes testing)

### iOS Application (Optional - if targeting iOS)

- [ ] **Configuration**
  - [ ] Bundle identifier configured
  - [ ] Development team selected in Xcode
  - [ ] Signing certificates configured
  - [ ] App icon configured for all sizes

- [ ] **Testing**
  - [ ] App runs on iOS Simulator
  - [ ] App runs on physical iPhone/iPad
  - [ ] All features tested (same as Android checklist)

## Deployment Execution

### Backend Deployment Steps

1. [ ] SSH into production server
2. [ ] Clone repository to `/opt/ethioworkforce/`
3. [ ] Create and activate Python virtual environment
4. [ ] Install dependencies from `requirements.txt`
5. [ ] Copy `.env` file to backend directory
6. [ ] Run database migrations
7. [ ] Create systemd service file
8. [ ] Enable and start service
9. [ ] Configure Nginx reverse proxy
10. [ ] Test Nginx configuration
11. [ ] Restart Nginx
12. [ ] Install SSL certificate
13. [ ] Verify HTTPS working
14. [ ] Test API health endpoint
15. [ ] Monitor logs for errors

### Mobile App Deployment Steps

#### Android

1. [ ] Update version number in `pubspec.yaml`
2. [ ] Clean build cache: `flutter clean`
3. [ ] Get dependencies: `flutter pub get`
4. [ ] Build release APK: `flutter build apk --release`
5. [ ] Test APK on physical device
6. [ ] Build App Bundle: `flutter build appbundle --release` (for Play Store)
7. [ ] Upload to Google Play Console (if publishing to store)
8. [ ] OR Distribute APK directly to users via USB/email

#### iOS

1. [ ] Open project in Xcode
2. [ ] Update version and build number
3. [ ] Build release: `flutter build ios --release`
4. [ ] Archive app in Xcode
5. [ ] Upload to App Store Connect (if publishing to store)
6. [ ] OR Create IPA for enterprise distribution

## Post-Deployment Verification

### Backend

- [ ] API accessible at production URL
- [ ] Health check returns success
- [ ] Authentication working
- [ ] Database queries performing well (< 500ms)
- [ ] Logs being written correctly
- [ ] Backup cron job running
- [ ] System monitoring in place

### Mobile App

- [ ] App connects to production API
- [ ] Login successful with test credentials
- [ ] All features working as expected
- [ ] Performance acceptable on low-end devices
- [ ] Battery usage reasonable
- [ ] No memory leaks during extended use

## Monitoring Setup

- [ ] **Application Monitoring**
  - [ ] Set up error tracking (optional: Sentry)
  - [ ] Configure uptime monitoring (optional: UptimeRobot)
  - [ ] Set up log aggregation (optional: ELK stack)

- [ ] **Server Monitoring**
  - [ ] CPU usage monitoring
  - [ ] Memory usage monitoring
  - [ ] Disk space alerts (< 80% usage)
  - [ ] Database connection pool monitoring

- [ ] **Alerts**
  - [ ] Email alerts for API downtime
  - [ ] Email alerts for database issues
  - [ ] Disk space alerts
  - [ ] Error rate threshold alerts

## Training and Documentation

- [ ] **User Training**
  - [ ] Admin users trained on web dashboard
  - [ ] Field supervisors trained on mobile app
  - [ ] Workers trained on QR code check-in process
  - [ ] HR team trained on payroll exports
  - [ ] IT team trained on sneakernet sync process

- [ ] **Documentation**
  - [ ] User manual created (English and Amharic)
  - [ ] Admin guide created
  - [ ] API documentation available
  - [ ] Troubleshooting guide prepared
  - [ ] Emergency contact list prepared

## Rollback Plan

- [ ] **Backup Strategy**
  - [ ] Database backup before deployment
  - [ ] Previous APK version saved
  - [ ] Previous backend code tagged in git

- [ ] **Rollback Procedure**
  - [ ] Steps to restore database documented
  - [ ] Steps to revert backend code documented
  - [ ] Steps to redistribute previous APK documented

## Go-Live Checklist

### Day Before Launch

- [ ] Final testing completed
- [ ] All stakeholders notified
- [ ] Support team briefed
- [ ] Rollback plan reviewed
- [ ] Backup verified

### Launch Day

- [ ] Deploy backend at off-peak hours
- [ ] Verify backend health
- [ ] Distribute mobile app to pilot group first
- [ ] Monitor logs for errors
- [ ] Collect user feedback
- [ ] Address critical issues immediately

### Post-Launch (First Week)

- [ ] Daily log review
- [ ] User feedback collection
- [ ] Performance monitoring
- [ ] Database growth tracking
- [ ] Issue resolution

## Success Criteria

- [ ] API uptime > 99.5%
- [ ] App crash rate < 1%
- [ ] Average API response time < 500ms
- [ ] User satisfaction score > 4/5
- [ ] Zero critical security issues
- [ ] All planned features working

## Sign-Off

- [ ] **Technical Lead**: __________________ Date: __________
- [ ] **Project Manager**: _________________ Date: __________
- [ ] **Client Approval**: _________________ Date: __________

---

## Notes

Add any deployment-specific notes, issues encountered, or workarounds here:

```
(Notes section - to be filled during actual deployment)
```

---

## Version History

| Version | Date | Deployed By | Notes |
|---------|------|-------------|-------|
| 1.0.0   |      |             | Initial production release |
|         |      |             |       |

---

**Last Updated**: 2024-01-22  
**Document Owner**: EthioWorkForce Technical Team
