# EthioWorkforce 🇪🇹

[![FastAPI](https://img.shields.io/badge/FastAPI-0.115-009688.svg?logo=fastapi)](https://fastapi.tiangolo.com)
[![Python](https://img.shields.io/badge/Python-3.11%2B-blue.svg?logo=python)](https://python.org)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B.svg?logo=flutter)](https://flutter.dev)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-336791.svg?logo=postgresql)](https://postgresql.org)
[![License](https://img.shields.io/badge/License-Proprietary-red.svg)]()
[![Ethiopian Labor](https://img.shields.io/badge/ERCA%20%26%20POESSA-Compliant-success.svg)]()

> **Enterprise-grade, offline-first workforce management, attendance tracking, and automated payroll system built specifically for Ethiopian labor regulations, operating sites, and financial institutions.**

---

## 🌟 Overview

**EthioWorkforce** solves critical workforce operational challenges for construction firms, agricultural plantations, manufacturing plants, and service enterprises operating across Ethiopia. It bridges the gap between remote, off-grid job sites and central financial auditing by combining:

- **Offline-First Resilience**: Full offline operation with SQLite local storage, QR code scanning, and USB "Sneakernet" sync for sites without reliable internet connectivity.
- **Ethiopian Labor & Tax Compliance**: Native Ethiopian calendar engine (13 months including Pagume), official ERCA progressive income tax schedules, and POESSA/PSSSA statutory pension contribution calculations (7% employee, 11% employer).
- **Direct Banking Integration**: One-click electronic payroll disbursement file generation for **Commercial Bank of Ethiopia (CBE)**, **Telebirr**, **Dashen Bank**, **Awash Bank**, and printable physical cash signature vouchers.
- **Executive Reporting Hub**: Flagship 5-tab enterprise analytics dashboard providing real-time labor cost breakdowns, census metrics, overtime audits, and tax withholding summaries.

---

## 🏛️ System Architecture

```
                             ┌───────────────────────────────────────────────┐
                             │              NEON POSTGRESQL                  │
                             │          Serverless Cloud Database            │
                             │   • Auto-scaling storage & SSL encryption     │
                             │   • Web SQL Query & Audit Console             │
                             └──────────────────────▲────────────────────────┘
                                                    │
                                          pg8000 + SSL (Pooled)
                                                    │
                             ┌──────────────────────┴────────────────────────┐
                             │            FASTAPI CLOUD BACKEND              │
                             │            (Render / Koyeb / VPS)             │
                             │   • REST APIs & Role-Based Access Control     │
                             │   • ERCA Tax & POESSA Pension Engine          │
                             │   • Interactive Swagger Docs: /api/docs       │
                             └──────────────────────▲────────────────────────┘
                                                    │
                                     REST API / JSON Sync Queue
                                                    │
                  ┌─────────────────────────────────┴─────────────────────────────────┐
                  │                                                                   │
       ┌──────────┴────────────────────────┐                       ┌──────────────────┴──────────────────┐
       │        FLUTTER WEB CLIENT         │                       │         FLUTTER MOBILE APP          │
       │     (GitHub Pages / Vercel)       │                       │       (Android APK / Offline)       │
       │ • Desktop & browser access        │                       │ • QR scanner for gate attendance    │
       │ • Executive reporting & payroll   │                       │ • Local SQLite offline store        │
       │ • Live inspection & audit portal  │                       │ • USB Sneakernet flash drive sync   │
       └───────────────────────────────────┘                       └─────────────────────────────────────┘
```

---

## 🚀 Key Modules & Capabilities

### 1. 📅 Dual Ethiopian & Gregorian Calendar Engine
- Native conversion between Gregorian dates and Ethiopian calendar years (`1900` – `2100` EC).
- Accurately computes leap years (Pagume 6 days vs. Pagume 5 days).
- Workers and administrators can switch date displays between Ethiopian Amharic notation and standard Gregorian dates.

### 2. 👥 Workforce & Operating Hierarchy
- Multi-tier structure: **Sites** (e.g., Bole Construction, Adama Factory) → **Workplaces** → **Work Types**.
- Comprehensive worker census tracking national ID, emergency contacts, payment period (daily, weekly, bi-weekly, monthly), and bank/mobile wallet accounts.

### 3. ⏱️ Attendance & Overtime Verification
- High-speed QR badge check-in / check-out.
- Multi-day bulk attendance approval for site managers.
- Multi-tiered overtime rates (Regular 1.25x, Night 1.5x, Weekend 2.0x, Public Holiday 2.5x).

### 4. 💰 Compliant Ethiopian Payroll Engine
- **Tax Rules**: Automatically implements 2024 ERCA progressive tax brackets (0% up to 600 ETB, scaling to 35% above 10,900 ETB).
- **Statutory Pension**: 7% employee contribution and 11% employer contribution for permanent and contracted staff; zero deductions for daily casual laborers.
- **Audit Locking**: Sealing a paid payroll permanently locks historical attendance and overtime records (`is_locked=True`) to prevent retrospective tampering.

### 5. 🏦 Banking & Disbursement Exports
Generates production-formatted disbursement files ready for batch upload:
- **Commercial Bank of Ethiopia (CBE)**: Official bulk upload `.xlsx` and `.csv` templates.
- **Telebirr**: Bulk mobile wallet transfer schedule.
- **Dashen Bank & Awash Bank**: Standard electronic fund transfer schedules.
- **Cash Signature Sheet**: Printable vouchers with Ethiopian date headers, worker breakdowns, and signature/thumbprint lines for unbanked casual staff.

### 6. 📊 Executive Reports Hub (`/reports`)
- **Executive Overview**: Total Gross Payroll, Net Disbursement, Tax liability, and Headcount analytics.
- **Bank & Disbursements**: Immediate export downloads for all financial institutions.
- **Tax & Compliance**: ERCA income tax schedules and POESSA statutory declaration reports.
- **Attendance & Overtime**: Detailed workforce audit rosters.
- **Workforce Census**: Human capital breakdown by operating site and labor classification.

---

## ☁️ Cloud Hosting & Quickstart

EthioWorkforce is configured for 100% free cloud hosting:

| Component | Free Platform | Setup Guide |
| :--- | :--- | :--- |
| **PostgreSQL** | [Neon Serverless Postgres](https://neon.tech) | [LIVE_DEPLOYMENT_GUIDE.md](LIVE_DEPLOYMENT_GUIDE.md#step-1-provision-the-free-postgresql-database-60-seconds) |
| **FastAPI Backend** | [Render Web Service](https://render.com) | [LIVE_DEPLOYMENT_GUIDE.md](LIVE_DEPLOYMENT_GUIDE.md#step-3-deploy-the-backend-to-render-3-minutes) |
| **Web Frontend** | [GitHub Pages](https://pages.github.com) | Auto-deployed via [`.github/workflows/deploy-web.yml`](.github/workflows/deploy-web.yml) |

### 1-Click Render Deployment
This repository contains a pre-configured `render.yaml`. When you link this repo to Render:
1. It automatically builds the Python 3.11 backend.
2. It executes `python scripts/init_cloud_db.py` to run database migrations and create the default admin.
3. It exposes your live API with free SSL (`https://ethioworkforce-api.onrender.com`).

### Default Admin Credentials
- **Username**: `admin`
- **Password**: `Admin@Ethio2026!`

### Live API Documentation
Once deployed, open Swagger UI at:
```text
https://<your-service>.onrender.com/api/docs
```

---

## 🧪 Verification & Testing

Verify end-to-end cloud health and endpoint integrity:
```bash
# Automated cloud smoke test suite
python backend/scripts/smoke_test_cloud.py --url https://<your-service>.onrender.com

# Backend unit tests & coverage
cd backend
pytest -v

# Frontend test suite & analysis
cd frontend
flutter analyze lib/
flutter test
```

---

## 📂 Documentation Directory

All detailed setup, architecture, and deployment manuals are organized under [`docs/`](docs/):

- **Deployment**: [`docs/deployment/`](docs/deployment/) (Render, Supabase, VPS, Mobile, Docker)
- **Local Setup**: [`docs/setup/`](docs/setup/) (PC, Phone-only, Web demo)
- **Specifications & Policies**: [`docs/specs/`](docs/specs/) (Security, Data Privacy, Testing Strategy, Permissions)
- **Production Cloud Guide**: [`LIVE_DEPLOYMENT_GUIDE.md`](LIVE_DEPLOYMENT_GUIDE.md)

---

## 📄 License & Attribution

Copyright © 2026 HD-CMP / EthioWorkforce. All rights reserved.
Developed for Ethiopian enterprise workforce operations.
