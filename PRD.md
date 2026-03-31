
---

# PRODUCT REQUIREMENTS DOCUMENT
**Product**: Sports Academy Mobile App (v1.4)
[cite_start]**Platform**: iOS & Android (Flutter) [cite: 341]
**Architecture**: Multi-Branch (Multi-Tenant)
[cite_start]**Backend**: PostgreSQL / REST API [cite: 341]
**Key Integrations**: 2factor.in (OTP), P2P UPI (Payments), Local Notifications
**Status**: Final Approved Draft

---

## 1. Product Overview
### 1.1 Purpose
[cite_start]The Sports Academy app provides a digitized, centralized platform for managing day-to-day academy operations[cite: 339, 340] across **multiple physical academy branches**. [cite_start]It serves two distinct user roles — Members (athletes/students) and Coaches/Admins — providing each with a tailored interface[cite: 340] linked explicitly to their assigned branch.

### 1.2 Goals & Objectives
* **Multi-Branch Isolation**: Ensure Admins and Members only interact with data, events, and batches relevant to their specific physical branch.
* [cite_start]**Digitize Operations**: Replace manual registers with real-time attendance tracking[cite: 343].
* **Streamline Payments**: Support direct fee collection via P2P UPI intent integration.
* **Optimize Storage**: Store media directly in the database using Base64 encoding with a strict 7-day data retention cleanup policy to maintain performance.
* **On-Device Communication**: Utilize local scheduled push notifications for automated fee reminders and upcoming batch alerts, removing reliance on external push servers.

### 1.3 Target Users
* [cite_start]**Member**: Academy students/athletes who track their own attendance, fees, and events[cite: 351] for their specific branch.
* **Branch Admin / Coach**: Academy staff assigned to a specific branch who manage local members, mark attendance, schedule sessions, and create local events.

---

## 2. Design System & User Interface
The application utilizes a **"Premium Professional"** aesthetic, balancing clean layouts with energetic sports-oriented accents.

* **Color Palette**:
    * **Primary (Brand)**: `#6236FF` (Royal Purple) used for primary actions, selected navigation icons, and active states.
    * **Surface/Background**: `#FFFFFF` (White) and `#F8F9FE` (Light Gray/Purple tint) for cards and inputs.
    * **Status - Success**: `#27AE60` (Green) for "Paid" badges and "Present" ('P') attendance markers.
    * **Status - Alert**: `#EB5757` (Red) for "Due" badges and "Absent" ('A') attendance markers.
* **Typography**: Clean Sans-Serif (Inter or SF Pro) optimized for high readability outdoors.
* **Imagery**: Full-bleed athletic photography on onboarding screens with purple gradient overlays for text contrast.

---

## 3. User Flows & Authentication
### 3.1 Passwordless Onboarding (via 2factor.in)
[cite_start]The app uses a secure, phone number + OTP based authentication system[cite: 354]. 
1. [cite_start]**Role Selection**: User selects "Member" or "Admin"[cite: 355].
2. [cite_start]**Phone Entry**: User inputs their +91 mobile number[cite: 355].
3. **OTP Generation & Verification**: The app triggers an OTP via the **2factor.in** SMS gateway, ensuring highly reliable delivery. [cite_start]The user enters the 4-digit code to authenticate[cite: 355].

### 3.2 Context-Aware Routing
[cite_start]Upon successful OTP verification, the app reads the user's role[cite: 357] and `branch_id` from the backend.
* [cite_start]Cross-role access is blocked by frontend navigation guards[cite: 360].
* **Branch Isolation**: The backend automatically scopes all subsequent API requests to the user's assigned branch.

---

## 4. Core Feature Specifications

### 4.1 Admin / Coach Interface
* [cite_start]**Home Dashboard**: Displays high-level stats ("Total Members", "Total Events")[cite: 368] specific to their branch, and a scrollable list of upcoming local events.
* **Member Management**:
    * View a searchable, filterable list of enrolled members within their branch.
    * [cite_start]"Add Member" form captures personal details, enrollment batch, and sport[cite: 388, 389, 390].
    * [cite_start]Verify and update a member's payment status directly from their profile[cite: 398, 399].
* [cite_start]**Attendance Tracking**: Filter by Date and Batch to quickly toggle members as Present ('P') or Absent ('A')[cite: 409, 415, 416].
* [cite_start]**Event Management**: Create new events by defining titles, categories, dates, timings, and uploading a Base64 banner image[cite: 423, 424].

### 4.2 Member Interface & P2P UPI Payments
* [cite_start]**Home Dashboard**: Highlights personal "Attendance %", "Fee Status", and today's schedule[cite: 437, 438, 439] at their branch.
* [cite_start]**My Attendance**: Features a monthly calendar strip and a detailed log of past sessions with Present/Absent/Holiday statuses[cite: 444, 448, 449].
* [cite_start]**Events**: Browse academy events, toggle a "Favorite" heart icon, view eligibility criteria, and register[cite: 452, 453, 458, 460].
* **Fees & P2P UPI**: 
    * [cite_start]Views current dues with a "Pay Now" CTA[cite: 465].
    * **Payment Flow**: Tapping "Pay Now" generates a strict P2P UPI intent URI (`upi://pay?pa=merchant@upi&pn=Academy...`). This automatically opens the installed UPI apps (GPay, PhonePe, Paytm) on the user's device. 
    * Once the transaction completes, the app captures the UPI transaction reference ID and updates the backend.

---

## 5. Technical Architecture & Data Management

### 5.1 Technology Stack
* [cite_start]**Frontend**: Flutter (iOS & Android)[cite: 341].
* [cite_start]**State Management & Routing**: `flutter_riverpod` and `go_router`[cite: 512].
* [cite_start]**Networking & Security**: `dio` (HTTP client), `flutter_secure_storage` (JWT)[cite: 512].
* **External APIs**: **2factor.in** (OTP Services), `url_launcher` (P2P UPI intent handling).
* **Local Notifications**: `flutter_local_notifications`. Scheduled locally on the device for fee reminders, upcoming events, and persistent foreground alerts during active sessions if needed, bypassing the need for a remote push server.

### 5.2 Image Storage Strategy (Base64)
All media (profile photos, event banners) are converted to **Base64 encoded strings** via Flutter and stored directly in the PostgreSQL database.
* Displayed using Flutter's native `Image.memory()` decoder.
* "List" API endpoints (e.g., fetch all members) must exclude the Base64 columns from the SQL `SELECT` statement to maintain fast load times.

### 5.3 Data Retention & Cleanup Policy
To prevent PostgreSQL database bloat from large Base64 strings, an automated cleanup policy is enforced for Events.
* **Retention Phase**: For **7 days** after the event concludes, all event data remains fully accessible.
* **Purge Phase (Cron Job)**: A backend scheduled task runs daily. For any event where the date is older than 7 days, the `image_base64` and `description` columns are permanently set to `NULL`.
* **Archival Data**: Event Title, Date, Venue, and associated financial/payment records are kept indefinitely.

---

## 6. Multi-Tenant Database Schema (PostgreSQL)

### 6.1 Branches Table (New)
* `id`: UUID (PK)
* `name`: VARCHAR(100) *(e.g., 'Koramangala Branch')*
* `city`: VARCHAR(100)

### 6.2 Users Table
* `id`: UUID (PK)
* `branch_id`: UUID (FK → branches) *(Isolates user to a branch)*
* [cite_start]`phone`: VARCHAR(15) UNIQUE [cite: 485]
* [cite_start]`name`: VARCHAR(100) [cite: 485]
* [cite_start]`role`: ENUM('member', 'admin') [cite: 485]
* `profile_photo_base64`: TEXT
* [cite_start]`member_id`: VARCHAR(20) [cite: 485]

### 6.3 Events Table
* [cite_start]`id`: UUID (PK)[cite: 495]
* `branch_id`: UUID (FK → branches)
* [cite_start]`title`: VARCHAR(200) [cite: 495]
* [cite_start]`description`: TEXT *(Purged after 7 days)* [cite: 495]
* [cite_start]`date`: DATE [cite: 495]
* `image_base64`: TEXT *(Purged after 7 days)*
* [cite_start]`status`: ENUM('upcoming', 'ongoing', 'past') [cite: 495]

### 6.4 Payments Table 
* [cite_start]`id`: UUID (PK)[cite: 493]
* [cite_start]`member_id`: UUID (FK → users) [cite: 493]
* [cite_start]`amount`: NUMERIC(10,2) [cite: 493]
* [cite_start]`payment_method`: ENUM('cash', 'upi') [cite: 493]
* `upi_transaction_id`: VARCHAR(100) *(Stores reference ID from P2P intent)*
* [cite_start]`status`: ENUM('success', 'failed', 'pending') [cite: 493]

---

## 7. Non-Functional Requirements
* [cite_start]**Performance**: The app should load the home screen within 2 seconds on a standard 4G connection[cite: 541]. API queries must strictly filter by `branch_id` and omit Base64 columns on list views.
* **Security**: JWT stored in `flutter_secure_storage`; all API calls over HTTPS; [cite_start]OTP expires after 5 minutes[cite: 541].
* [cite_start]**Offline Capability**: Cached data (last fetched attendance, events) should be viewable when offline[cite: 541]. Base64 images require an active connection unless previously cached.
* [cite_start]**Scalability**: Backend should handle up to 500 concurrent members[cite: 541] per branch without degraded performance.