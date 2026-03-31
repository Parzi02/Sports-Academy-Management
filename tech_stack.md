Here is the updated Technical Stack for the Sports Academy Mobile App (v1.4), which incorporates the multi-branch architecture, Base64 image storage, and your specific integrations for local notifications, OTP, and payments:

### 1. Frontend Development (Mobile)
* [cite_start]**Framework**: Flutter (iOS & Android) for cross-platform development[cite: 335, 341].
* [cite_start]**State Management**: `flutter_riverpod` [cite: 512] (used to manage global state, including the user's active `branch_id`).
* [cite_start]**Navigation**: `go_router` [cite: 512] (implements declarative, role-based, and branch-based route guards).
* [cite_start]**Networking**: `dio` [cite: 512] (HTTP client with interceptors to inject JWT and `branch_id` headers).
* [cite_start]**Local Security**: `flutter_secure_storage` [cite: 512] (securely stores the JWT on the device).

### 2. Backend & Architecture
* [cite_start]**API Architecture**: RESTful API [cite: 529] (e.g., Node.js/Express, Python/FastAPI, or Go).
* **Multi-Tenancy Model**: Row-Level Data Isolation. The backend middleware intercepts the user's JWT, extracts their assigned `branch_id`, and strictly appends `WHERE branch_id = ?` to all database queries to prevent cross-branch data leaks.
* **Security Protocol**: JWT (JSON Web Tokens) for session management; [cite_start]HTTPS for all API communication[cite: 541].

### 3. Database & Storage Strategy
* [cite_start]**Database Engine**: PostgreSQL (Relational Database)[cite: 335, 341].
* **Image Storage Strategy**: **Base64 Encoding**. External cloud storage (like AWS S3) is bypassed entirely. All media (profile photos, event banners) is converted to Base64 strings on the client side and stored directly in PostgreSQL `TEXT` columns.
* **Data Lifecycle Management**: A server-side Cron Job (scheduled task) runs daily to execute the 7-day data retention policy, automatically nullifying heavy Base64 strings and descriptions from past events to optimize database performance.

### 4. Key Integrations & Core Packages
* **Authentication**: **2factor.in** (External SMS gateway for highly reliable OTP delivery).
* **Payments**: **P2P UPI Intent** (using `url_launcher` or a dedicated UPI package to trigger native apps like GPay, PhonePe, or Paytm via `upi://pay?...` deep links).
* [cite_start]**Push Notifications**: `flutter_local_notifications` [cite: 512] (Scheduled locally on the device for fee reminders, upcoming events, and persistent foreground alerts, bypassing the need for a remote push server).
* [cite_start]**Image Capture**: `image_picker` [cite: 512] (for selecting profile photos or event banners before Base64 conversion).
* [cite_start]**Date/Time Formatting**: `intl` [cite: 512] (for consistent formatting of dates and times across the app).