# Version 1.0.1+2

Release date: 2026-08-12

## Added

- Displays the app version in the landing-page footer.
- Adds Android update checks with optional or required updates configured by the server.
- Adds a public `/api/mobile/app-update` endpoint for update metadata.

## Changed

- Uses the supported `/api/mobile/` API base path.
- API v1 requests are retired and return `410 Gone` with migration guidance.

## Fixed

- Prevents overlapping QR, face-attendance, and QR-void submissions from reaching the server.
- Converts unexpected scanner failures into user-friendly messages instead of app crashes.

---

## Version log format

Add a new release at the top of this file using the same **Added**, **Changed**, and **Fixed** sections. Keep the mobile app version, backend `APP_VERSION`, and `MOBILE_APP_LATEST_VERSION` aligned for every published release.
