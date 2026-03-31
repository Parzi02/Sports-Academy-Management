
### **1. High-Level Architecture Overview**
* **Database Engine**: PostgreSQL
* **Paradigm**: Relational Database Management System (RDBMS)
* **Architecture Style**: **Multi-Tenant (Row-Level Isolation)**. A single shared database serves multiple physical branches.
* **Primary Keys (PK)**: UUIDs are used across all tables for secure, unguessable identifiers.
* **Storage Strategy**: External cloud storage is bypassed. Media is stored directly in the database as Base64 encoded `TEXT`.
* **Cleanup Mechanism**: A backend Cron Job runs daily to purge heavy Base64 strings and descriptions from the `events` table 7 days after an event concludes.

---

### **2. Entity-Relationship Schema**

#### **Branches Table (NEW)**
Defines the physical locations of the academy. This is the root tenant identifier.

| Column | Data Type | Constraints / Notes |
| :--- | :--- | :--- |
| `id` | UUID | **Primary Key** |
| `name` | VARCHAR(100) | e.g., 'Koramangala Branch' |
| `city` | VARCHAR(100) | |
| `contact_phone` | VARCHAR(15) | |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |

#### **Users Table**
Stores both Members and Admins. Scoped to a specific branch to prevent cross-branch data access.

| Column | Data Type | Constraints / Notes |
| :--- | :--- | :--- |
| `id` | UUID | **Primary Key** |
| `branch_id` | UUID | **Foreign Key** → `branches(id)` (Isolates user to a branch) |
| `phone` | VARCHAR(15) | UNIQUE, NOT NULL (Used for OTP) |
| `name` | VARCHAR(100) | NOT NULL |
| `email` | VARCHAR(150) | Optional |
| `dob` | DATE | |
| `gender` | VARCHAR(20) | 'Male', 'Female', 'Other' |
| `address` | TEXT | |
| `role` | ENUM | 'member', 'admin' |
| `profile_photo_base64` | TEXT | **Base64 string of user photo** |
| `member_id` | VARCHAR(20) | Auto-generated (e.g., BA008) |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |

#### **Batches Table**
Defines the training groups, sports, and assigned coaches for a specific branch.

| Column | Data Type | Constraints / Notes |
| :--- | :--- | :--- |
| `id` | UUID | **Primary Key** |
| `branch_id` | UUID | **Foreign Key** → `branches(id)` |
| `name` | VARCHAR(50) | e.g., 'Batch 1' |
| `sport` | VARCHAR(50) | e.g., 'Basketball' |
| `coach_id` | UUID | **Foreign Key** → `users(id)` |
| `start_time` | TIME | e.g., 07:00 |
| `end_time` | TIME | e.g., 09:30 |
| `capacity` | INT | Maximum members allowed |

#### **Events Table**
Stores academy activities. Scoped to a branch and subject to the 7-day data retention cleanup policy.

| Column | Data Type | Constraints / Notes |
| :--- | :--- | :--- |
| `id` | UUID | **Primary Key** |
| `branch_id` | UUID | **Foreign Key** → `branches(id)` (Ensures events only show to local members) |
| `title` | VARCHAR(200) | Permanent record |
| `description` | TEXT | **Nullified 7 days after event date** |
| `sport_category` | VARCHAR(50) | e.g., 'Football' |
| `event_category` | VARCHAR(50) | e.g., 'Tournament' |
| `date` | DATE | Permanent record |
| `start_time` | TIME | |
| `end_time` | TIME | |
| `venue` | VARCHAR(100) | |
| `image_base64` | TEXT | **Base64 string; Nullified 7 days after event date** |
| `status` | ENUM | 'upcoming', 'ongoing', 'past' |
| `created_by` | UUID | **Foreign Key** → `users(id)` |

#### **Enrollments Table**
Links a Member to a specific Batch. *(Inherits branch scope via `member_id` and `batch_id`)*

| Column | Data Type | Constraints / Notes |
| :--- | :--- | :--- |
| `id` | UUID | **Primary Key** |
| `member_id` | UUID | **Foreign Key** → `users(id)` |
| `batch_id` | UUID | **Foreign Key** → `batches(id)` |
| `membership_type` | VARCHAR(50) | e.g., 'Quarterly' |
| `start_date` | DATE | |
| `end_date` | DATE | |
| `payment_status` | ENUM | 'paid', 'due' |

#### **Attendance Table**
The daily transactional log for member presence. *(Inherits branch scope via `member_id` and `batch_id`)*

| Column | Data Type | Constraints / Notes |
| :--- | :--- | :--- |
| `id` | UUID | **Primary Key** |
| `member_id` | UUID | **Foreign Key** → `users(id)` |
| `batch_id` | UUID | **Foreign Key** → `batches(id)` |
| `date` | DATE | Session date |
| `status` | ENUM | 'present', 'absent', 'holiday', 'pending' |
| `marked_by` | UUID | **Foreign Key** → `users(id)` (Admin/Coach) |
| `marked_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |

#### **Payments Table**
Records financial transactions, accommodating the direct P2P UPI flow. *(Inherits branch scope via `member_id`)*

| Column | Data Type | Constraints / Notes |
| :--- | :--- | :--- |
| `id` | UUID | **Primary Key** |
| `member_id` | UUID | **Foreign Key** → `users(id)` |
| `enrollment_id` | UUID | **Foreign Key** → `enrollments(id)` |
| `amount` | NUMERIC(10,2) | |
| `payment_method` | ENUM | 'cash', 'upi' |
| `upi_transaction_id` | VARCHAR(100) | **Reference ID captured from UPI intent** |
| `paid_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| `recorded_by` | UUID | **Foreign Key** → `users(id)` (If manual cash) |
| `status` | ENUM | 'success', 'failed', 'pending' |

#### **Event Favourites Table**
Tracks which members have bookmarked specific events. *(Inherits branch scope via `member_id`)*

| Column | Data Type | Constraints / Notes |
| :--- | :--- | :--- |
| `id` | UUID | **Primary Key** |
| `member_id` | UUID | **Foreign Key** → `users(id)` |
| `event_id` | UUID | **Foreign Key** → `events(id)` |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |

---

### **3. Key Database Operations & Rules**

* **Multi-Tenant Context-Aware Routing (NEW)**: To prevent horizontal privilege escalation, the backend API must extract the `branch_id` from the authenticated user's JWT. Every API query must automatically append a filter for that branch (e.g., `SELECT * FROM events WHERE branch_id = [JWT_BRANCH_ID]`).
* **API Payload Optimization**: To ensure the mobile app meets the < 2-second load time requirement, SQL queries fetching list views **must omit** the `profile_photo_base64` and `image_base64` columns.
* **Automated Cleanup Job**: A scheduled task (Cron) runs server-side daily. The SQL executed looks similar to:
  ```sql
  UPDATE events 
  SET image_base64 = NULL, description = NULL 
  WHERE date < CURRENT_DATE - INTERVAL '7 days' AND status = 'past';
  ```