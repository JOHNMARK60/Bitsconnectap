# BITSConnect — CampusHub BITS
## System Demo Presentation (Laravel Web + Flutter Mobile)

> **Purpose:** Slide-by-slide demo script for presenting the **CampusHub BITS** attendance & campus management system.
> **Two front-ends covered:** the **Laravel Web Portal** (Admin/Event Manager/Scanner/Student/Alumni dashboards) and the **Flutter Mobile App** (BITSConnect) for Students, Scanners, and Alumni.
> **Backend:** Laravel 10 REST API (`/api/mobile/*`) secured with Sanctum Bearer tokens.

---

## How to use this document
Each slide below has:
- **On screen** — bullet points to display on the slide.
- **Presenter notes** — what to say.
- **Live demo** — exact paths/screens to navigate and click during the live run.

> ⌨️ **Keyboard/run reference**
> - Web portal: `php artisan serve` + `npm run dev` → open `http://127.0.0.1:8000`
> - Mobile app: `flutter run` (points to `https://bitsorg.info/api/` via `lib/core/constants/api_config.dart`)
> - Seeded logins (see `README.md`): Admin, Student, Scanner, Alumni — all `password`

---

# SECTION A — INTRODUCTION & AGENDA

## Slide 1 — Cover / Title

**On screen**
- **BITSConnect — CampusHub BITS**
- A Role-Based Campus Attendance & Record Management System
- **Laravel 10 Web Portal + Flutter Mobile App**

**Presenter notes**
- Good morning/afternoon. Today we demonstrate **CampusHub BITS**, a complete campus management platform built on **Laravel 10** for the backend with a **Flutter** mobile application for on-the-go access.
- The system handles users, roles, events, QR scanning, **face recognition attendance**, alumni records, announcements, and reporting exports.
- We will walk through both the **web portal** and the **mobile app**, showing how they share the same API and data.

---

## Slide 2 — Agenda

**On screen**
1. Overview & Tech Stack
2. Architecture & Authentication
3. **Laravel Web Portal** walkthrough
   - Admin Dashboard & User/Event Management
   - Event Manager & Reporting (Excel / Word / PDF)
   - Scanner module (QR scanning & patrol/geofence)
4. **Flutter Mobile App** walkthrough
   - Student module (events, QR + face attendance, profile, face registration, notifications, penalties)
   - Scanner module (QR scan, face verify, scan history)
   - Alumni module (profile, records, yearbook, work experience)
5. Key Features Highlight
6. Q&A / Closing

**Live demo**
- (No demo — just overview.)

---

## Slide 3 — Overview & Tech Stack

**On screen — Backend**
- PHP 8.1+, **Laravel 10**
- MySQL database
- Laravel Sanctum (API tokens)
- Maatwebsite Excel, DomPDF, PhpOffice PhpWord (export reports)
- Geofence / Haversine distance service
- Face recognition & embedding services
- Laravel UI auth scaffolding + Bootstrap 5 + Vite

**On screen — Mobile**
- Flutter (Dart)
- Provider (state management)
- `mobile_scanner`, `camera`, `image_picker`
- `geolocator` (GPS for geofence)
- `flutter_secure_storage` (token), `dio`/`http`
- Responsive landing page + role modules

**Presenter notes**
- One backend powering two front-ends. Mobile reuses the exact role logic and attendance rules enforced by Laravel.

**Live demo**
- (Optional) `composer.jb`/Read `campushub_bits/composer.json`.

---

## Slide 4 — Architecture & Data Flow

**On screen**
```
Flutter App (BITSConnect)          Laravel Web Portal (Blade)
      │  HTTPS / Bearer token             │  Session + CSRF
      ▼                                    ▼
        ┌───────────────────────────────────────┐
        │       Laravel 10 back-end             │
        │  Routes: routes/web.php, api.php      │
        │  Controllers: Api\Mobile\*, Admin\*,  │
        │  Student\*, Scanner\*, Alumni\*,      │
        │  EventManager\*                       │
        │  Services: GeofenceService, FaceSvc   │
        │  Middleware: IfAdmin/Student/Scanner/ │
        │  Alumni, PreventMobileAccess          │
        └───────────────────────────────────────┘
                       │
                       ▼
                     MySQL
      users, roles, other_details, events,
      attendance_logs, face_data, year_books,
      work_experiences, announcements,
      checkpoints, patrols, notifications
```

**Presenter notes**
- Explain that the Flutter app calls `/api/mobile/*` endpoints, sends `Authorization: Bearer <token>`, and receives JSON wrapped in `{ success, message, data }`.
- The web portal uses normal server-side Blade + session auth.

**Live demo**
- Show `campushub_bits/routes/api.php` (API), `routes/web.php` (web), and `bits_mobile_app/lib/core/constants/api_config.dart` (base URL).

---

# SECTION B — LARAVEL WEB PORTAL DEMO

## Slide 5 — Login & Role Redirect

**On screen**
- URL: `http://127.0.0.1:8000`
- Roles & default routes:
  - Admin → `/admin`
  - Student → `/student`
  - Scanner → `/scanner`
  - Alumni → `/alumni`
  - Event Manager → `/event-manager`

**Presenter notes**
- Sign in to show the role-based dashboards. Each role lands on its own dashboard.

**Live demo**
1. Open `http://127.0.0.1:8000`
2. Login as `admin@example.com` / `password` → lands on `/admin`.

---

## Slide 6 — Admin Dashboard & User Management

**On screen**
- Dashboard counts: total admins, students, scanners, alumni.
- **User Management** (`/admin/usersmanagement`):
  - List with pagination
  - Filter by name, academic year, role, year, section, gender, semester
  - Create / edit / delete users
  - Store profile photos (base64), check duplicate email

**Live demo**
1. From `/admin`, note the stat cards.
2. Go to `/admin/usersmanagement`.
3. Add or search a user; edit profile fields.
4. Click **Roles** (`/admin/roles`) and **Events** (`/admin/events`).

---

## Slide 7 — Event Management (Web)

**On screen**
- Create events with:
  - Name, short description
  - Event date
  - Login datetime / Logout datetime (attendance window)
  - Academic year, semester
- List/filter/update/delete events.

**Live demo**
1. Open `/admin/events` → click Create.
2. Fill the form (set a login datetime in the near past so attendance is open).
3. Save → event appears in the list and is available to students/scanners.

---

## Slide 8 — Event Manager & Reporting

**On screen**
- `/event-manager`
- List events with attendance counts.
- Filter by name, academic year, semester, date.
- View attendance logs for an event; filter by student ID/name/course/year/section.
- **Export reports** to Excel, Word, and PDF.
- Grouped views: **By Student** and **By Year & Section**.

**Live demo**
1. Open `/event-manager`.
2. Open an event → view attendance logs.
3. Click **Export Excel**, **Export Word**, **Export PDF** to show report generation.

---

## Slide 9 — Scanner & Geofence / Patrol (Web)

**On screen**
- Scanner dashboard `/scanner`:
  - Select an event, scan/submit student QR → records Login/Logout.
- Patrol & checkpoint geofencing `/scanner/patrol`:
  - Admin manages checkpoints & patrols at `/admin/geofence`.
  - Haversine distance computed **server-side**; verification accepted only inside checkpoint radius & accuracy/capture-time bounds.
  - Every attempt stored in `checkpoint_verifications`.

**Live demo**
1. (Patrol) As admin, open `/admin/geofence` → add a checkpoint.
2. Open scanner page (optionally) to show QR entry field.
3. Show `/scanner/patrol` UI.

---

# SECTION C — FLUTTER MOBILE APP DEMO

## Slide 10 — Flutter App: Launch & Landing Page

**On screen**
- Run `flutter run` (base URL `https://bitsorg.info/api/`).
- Screens launch order: **Splash → Landing** (`/`).
- Landing page sections: Hero, Stats, Features, Roles, Events, Operations, About, Footer.
- Login opens in a modal dialog.

**Screenshots available:** `docs/screenshots/landing_page_desktop.png`, `landing_page_mobile.png`.

**Live demo**
1. Launch app → Splash.
2. Show Landing scrolling (Features, Roles, Events).
3. Tap **Login** → modal.

---

## Slide 11 — Mobile Login & Secure Token

**On screen**
- Endpoint: `POST /api/mobile/login`
- Returns Bearer token; stored in secure storage.
- All protected requests send `Authorization: Bearer <token>` + `Accept: application/json`.

**Presenter notes**
- Show how the same credentials work on web and mobile because both hit one backend.
- Role determines destination:
  - Student → Student Dashboard
  - Alumni → Alumni Dashboard
  - Scanner → Scanner Dashboard

**Live demo**
1. In the login modal, enter `student@example.com` / `password`.
2. Observe redirect to the Student dashboard.

---

### 🎓 STUDENT MODULE (Mobile)

## Slide 12 — Student Dashboard

**On screen**
- Stat cards: **Attended Events**, **Available Events**, **Academic Level**.
- Attendance line chart, User Activity, Upcoming Events, Announcements.
- **Student QR Code** card (downloadable) for QR attendance.
- Profile summary: ID number, course, name, email, academic year, semester.
- API: `GET /api/mobile/student/dashboard`.

**Screenshot:** `docs/mobile-screenshots/dashboard-mobile.png`

**Live demo**
1. Land on Student Dashboard.
2. Scroll: review stat cards, upcoming events, announcements.
3. Show the Student QR code card.

---

## Slide 13 — Student Events & Attendance (QR)

**On screen**
- Events & Attendance screen (`/student/events`):
  - Summary pills: Total Events, Attended.
  - Event cards: name, description, date, login/logout time, academic year & semester badges.
  - **Attend** (login) and **Logout** buttons.
- APIs:
  - `GET /api/mobile/student/events`
  - `GET /api/mobile/student/attended-events`
  - `POST /api/mobile/student/attend`
  - `POST /api/mobile/student/logout-attendance`

**Presenter notes**
- Explain attendance window: login allowed between event login datetime and logout datetime; logout allowed at logout datetime until 1 hour after.

**Screenshot:** `docs/mobile-screenshots/qr-attendance-mobile.png`

**Live demo**
1. Go to Events screen.
2. Pick an open event → tap **Attend** → success (GPS geofence validated).
3. Tap **Logout** to close attendance.

---

## Slide 14 — Student Face Registration & Face Attendance

**On screen**
- **Face Registration** (`/student/face-registration`):
  - Requests camera permission; captures a face image; uploads.
- **Face Attendance** (`/student/face-attendance`):
  - Camera-based liveness capture → remote verify + geofence → record attendance.
- APIs:
  - `GET /api/mobile/student/face/status`
  - `POST /api/mobile/student/face/register`
  - `POST /api/mobile/student/attendance/face`

**Screenshot:** `docs/mobile-screenshots/face-attendance-mobile.png`

**Live demo**
1. Open **Face Registration** → grant camera → capture → upload → success.
2. Open **Face Attendance** → capture live face → verify → attendance recorded/success.

---

## Slide 15 — Student Profile, Change Password, Notifications & Penalties

**On screen**
- **Profile** (`/student/profile`): Account, Academic, Personal & Photo tabs; completion status pill (Complete / Needs update).
- **Change Password** (`/student/change-password`).
- **Notifications** + **Mark all read**.
- **Penalties** (attendance penalties).

**Live demo**
1. Open Profile → show tabs & completion progress.
2. Change Password (validate current password).
3. Open Notifications → mark all read.
4. Open Penalties.

---

### 📷 SCANNER MODULE (Mobile)

## Slide 16 — Scanner Dashboard & QR Scanning

**On screen**
- Scanner Dashboard: stat cards (Events, Today, Total scans), Recent Scans.
- **QR Attendance**:
  - Select event → Start Camera → scan student QR.
  - Verifies student, validates geofence (GPS) + event window, records Login/Logout.
  - Manual fallback and QR **void** with reason available.
- APIs:
  - `GET /api/mobile/scanner/dashboard`
  - `POST /api/mobile/scanner/verify`/`scan`
  - `POST /api/mobile/scanner/qr/void`

**Screenshot:** `docs/mobile-screenshots/outside-campus-alert-mobile.png`

**Live demo**
1. Logout, login as `scanner@example.com` → Scanner Dashboard.
2. Open **QR Attendance** → select event → scan the student's QR.
3. If outside venue, show the **outside campus alert**.
4. Show Scan History.

---

## Slide 17 — Scanner Face Verification & History

**On screen**
- **Face Verify**: capture a student face image → compare → Verified / Not Verified + confidence.
- **Scan History**: full list of scanned attendance records.
- Also supports registering a student's face on device.
- APIs:
  - `POST /api/mobile/scanner/face-verify`
  - `GET /api/mobile/scanner/scan-history`
  - `POST /api/mobile/scanner/students/{student}/face/register`

**Live demo**
1. Open **Face Verify** → camera → upload → show match result.
2. Open **Scan History** → review records.

---

### 🎓 ALUMNI MODULE (Mobile)

## Slide 18 — Alumni Dashboard, Profile & Records

**On screen**
- Alumni Dashboard: profile overview + announcements.
- **Profile** (`/alumni/profile`): account + extended profile, photo upload; completion status.
- **Records** (`/alumni/records`): graduation/yearbook & work history summary.
- APIs:
  - `GET /api/mobile/alumni/dashboard`
  - `GET /api/mobile/alumni/profile`

**Live demo**
1. Logout, login as `alumni@example.com` → Alumni Dashboard.
2. Open Profile → show completion progress.
3. Open Records.

---

## Slide 19 — Alumni Yearbook & Work Experience

**On screen**
- **Yearbook** (`/alumni/yearbook`): upload graduation picture, motto, graduation year/date.
- **Work Experience**: add/edit/delete position, company, contact, start/end dates, currently working flag, description.
- APIs:
  - `POST /api/mobile/alumni/yearbook`
  - `GET/POST/PUT/DELETE /api/mobile/alumni/work-experiences`
  - `GET /api/mobile/alumni/records`, `/events`

**Live demo**
1. Open **Yearbook** → upload a graduation photo + motto → save.
2. Open **Work Experiences** → add a record → save.
3. (Optional) Open **Events** to view campus events as alumni.

---

# SECTION D — KEY FEATURES & CLOSING

## Slide 20 — Key Features Highlight

**On screen**
- **Role-Based Access Control** (Admin, Student, Scanner, Alumni, Event Manager).
- **QR Attendance** with geofence (GPS) — server-side Haversine authority.
- **Face Recognition** registration + live verification (liveness).
- **Attendance Windows** (login/logout datetime rules; duplicate-login blocked).
- **Notifications** and **Penalties** for students.
- **Reporting** — Export attendance to **Excel, Word, PDF**.
- **Alumni records** — yearbook + work experience.
- **Patrol / Checkpoint geofencing** for guard workflows.
- One **shared API** across web and mobile.

**Presenter notes**
- Emphasize that security (distance recomputed on server, Sanctum tokens, role middleware, CSRF on web) is enforced regardless of which client is used.

---

## Slide 21 — Security, Monitoring & Audit

**On screen**
- Sanctum token auth on API.
- Role middleware: `IfAdmin`, `IfStudent`, `IfScanner`, `IfAlumni`.
- Server-side geofence recomputation (client distance never trusted).
- Rate-limited scanner verification (12/min).
- Audit logs: `interaction_logs`, `checkpoint_verifications`, face registration/verification logs, mobile audit logs.
- `PreventMobileAccess` middleware for web pages.

**Presenter notes**
- Highlight that both mobile and web changes are validated and logged server-side for a single source of truth.

---

## Slide 22 — Demo Recap / Flow Map

**On screen**
```
WEB PORTAL                      MOBILE APP
─────────────────────           ─────────────────────
/admin  (Admin)                 /splash → /landing → login
  Users, Roles, Events              Student: dashboard, events,
  Geofence checkpoints              QR + face attendance, profile,
/event-manager                      face register, notifications,
  Attendance, exports (xlsx,        penalties
  docx, pdf), by-student/section  /scanner: dashboard, QR scan,
/scanner (web)                      face verify, history
  QR entry, patrol                /alumni: dashboard, profile,
                                   yearbook, work experience
          └───────── shared Laravel API + MySQL ─────────┘
```

**Live demo**
- Quickly toggle between web (browser) and mobile to reinforce "one backend, two clients."

---

## Slide 23 — Q&A / Thank You

**On screen**
- Thank you!
- Questions?
- Contacts / credits welcome.

**Presenter notes**
- Invite questions. If asked about extending (new roles, more APIs, reporting), mention the modular controller/API structure makes it easy to grow.
- Offer to show `routes/api.php` and `routes/web.php` or specific screens again.

---

# APPENDIX — Quick Reference

## Seeded Login Accounts (`php artisan migrate --seed`)
| Role | Email | Password | Default |
| --- | --- | --- | --- |
| Admin | `admin@example.com` | `password` | `/admin` |
| Student | `student@example.com` | `password` | `/student` |
| Scanner | `scanner@example.com` | `password` | `/scanner` |
| Alumni | `alumni@example.com` | `password` | `/alumni` |

## Key Web Routes
| Feature | Route |
| --- | --- |
| Admin dashboard | `GET /admin` |
| User management | `GET /admin/usersmanagement` |
| Role management | `GET /admin/roles` |
| Event management | `GET /admin/events` |
| Geofence checkpoints | `GET /admin/geofence` |
| Event Manager | `GET /event-manager` |
| Scanner (web) | `GET /scanner` |

## Key Mobile API Endpoints (`/api/mobile/`)
| Area | Endpoints |
| --- | --- |
| Auth | `POST /login`, `POST /logout`, `GET /user` |
| Student | `/student/dashboard`, `/student/events`, `/student/attend`, `/student/logout-attendance`, `/student/profile`, `/student/face/register`, `/student/attendance/face`, `/student/qr-code`, `/student/notifications`, `/student/penalties`, `/student/change-password` |
| Scanner | `/scanner/dashboard`, `/scanner/events`, `/scanner/qr/verify`, `/scanner/scan`, `/scanner/face-verify`, `/scanner/scan-history`, `/scanner/qr/void` |
| Face | `/face/register`, `/face/verify`, `/face/enroll`, `/face/logs` |
| Alumni | `/alumni/dashboard`, `/alumni/profile`, `/alumni/records`, `/alumni/events`, `/alumni/yearbook`, `/alumni/work-experiences` |

## API Response Wrapper
```json
{
  "success": true,
  "message": "...",
  "data": { }
}
```

## Mobile Screenshots Available
`campushub_bits/docs/mobile-screenshots/`
- `dashboard-mobile.png`
- `attended-events-mobile.png`
- `face-attendance-mobile.png`
- `qr-attendance-mobile.png`
- `outside-campus-alert-mobile.png`

`campushub_bits/docs/screenshots/`
- `landing_page_desktop.png`
- `landing_page_mobile.png`

---

*Generated from CampusHub BITS (Laravel) + BITSConnect (Flutter) source.*

