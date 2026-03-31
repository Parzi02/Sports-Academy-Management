
---

## 1. Authentication & Onboarding Flow
[cite_start]The app uses a passwordless, OTP-based authentication system powered by 2factor.in[cite: 354].

1.  [cite_start]**Splash Screen**: The user lands on a "Get Started" screen[cite: 321, 355].
2.  [cite_start]**Role Selection**: The user selects their role as either **Member** or **Admin**[cite: 322, 323, 324].
3.  [cite_start]**Phone Entry**: The user enters their +91 mobile number and taps "Get OTP"[cite: 327, 328, 355].
4.  [cite_start]**OTP Verification**: The user enters a 4-digit code generated via 2factor.in[cite: 329, 355].
    * [cite_start]**Success & Context Routing**: The app checks the backend for the user's role and navigates accordingly[cite: 357, 358, 359]. Crucially, the backend also fetches the user's `branch_id`, permanently scoping their session to their specific physical academy location.
    * [cite_start]**Failure**: Option to resend the code after a 28-second cooldown[cite: 331, 355].

---

## 2. Admin / Coach App Flow (Branch-Scoped)
[cite_start]The Admin interface is organized into four primary tabs: **Home, Members, Attendance,** and **Events**[cite: 362]. All data displayed here is strictly isolated to the Admin's assigned branch.

### A. Home Dashboard
* [cite_start]**Stats**: View "Total Members" and "Total Events" counts specific to their branch[cite: 368].
* [cite_start]**Upcoming Events**: A scrollable list of upcoming activities happening at their location[cite: 370].
* [cite_start]**Profile/Notifications**: Persistent icons in the top bar lead to the Coach Profile or Notification center[cite: 366, 367].

### B. Member Management
* [cite_start]**Member List**: Search and filter members within their branch by Batch (e.g., Batch 1) or Payment Status (Paid/Due)[cite: 379, 380].
* **Add Member**: A floating button opens a form for personal details (Name, Phone, DOB, etc.) and enrollment details (Sport, Batch, Coach). [cite_start]New members are automatically mapped to the Admin's branch[cite: 383, 388, 390].
* [cite_start]**Member Profile**: Tapping a member card displays their ID (e.g., BA008), contact info, and enrollment status[cite: 393, 394, 396].
* [cite_start]**Payment Update**: Verify and update a member's payment status directly from their profile[cite: 398, 399].

### C. Attendance Tracking
* [cite_start]**Marking Attendance**: Admins select a Date and Batch belonging to their branch[cite: 409].
* [cite_start]**Action**: Toggle 'A' (Absent) or 'P' (Present) for each member in the list[cite: 415, 416].
* [cite_start]**Progress**: A summary row tracks the count of members marked (e.g., 02/05 Marked)[cite: 410].

### D. Event Management
* [cite_start]**Event List**: Filter events by All, Ongoing, Upcoming, or Past[cite: 420].
* **Create Event**: Create new events by defining titles, categories, dates, timings, and uploading a Base64 banner image. [cite_start]These events will only be visible to members of this specific branch[cite: 422, 423, 424].

---

## 3. Member App Flow (Branch-Scoped)
[cite_start]The Member interface is organized into four primary tabs: **Home, Attendance, Events,** and **Fee**[cite: 432].

### A. Home Dashboard
* [cite_start]**At-a-Glance**: Highlights personal "Attendance %", "Fee Status", and today's schedule[cite: 437, 438, 439].

### B. My Attendance
* [cite_start]**Calendar View**: Features a monthly calendar strip and a detailed log of past sessions with Present/Absent/Holiday statuses[cite: 444, 448, 449].
* [cite_start]**Summary**: A progress bar shows the overall attendance percentage for the month[cite: 445].

### C. Events & Registration
* [cite_start]**Browse**: Browse academy events specific to the member's branch[cite: 450].
* [cite_start]**Favorites**: Toggle a "Favorite" heart icon to save events to a list in the profile[cite: 452, 453, 478].
* [cite_start]**Details**: Tapping an event shows eligibility criteria, and a "Register Now" button[cite: 456, 458, 460].

### D. Fees & P2P UPI Payments
* [cite_start]**Due State**: Views current dues with a "Pay Now" CTA[cite: 465].
* **P2P UPI Payment Flow**: Tapping "Pay Now" triggers a direct P2P UPI intent (e.g., `upi://pay?pa=...`). This automatically opens installed UPI applications (GPay, PhonePe, Paytm) on the user's phone. Upon success, the app captures the UPI transaction reference ID.
* [cite_start]**Paid State**: Displays a "No Dues Left" banner with a checkmark[cite: 468].
* [cite_start]**Transaction History**: A list of past payments with the amount, date, and a download icon for receipts[cite: 470, 471, 473].

### E. Member Profile
* [cite_start]**Personalization**: Edit profile photo and view member ID[cite: 475, 476].
* [cite_start]**Information**: View Enrollment Details (Sport, Coach, Batch) and personal data[cite: 479, 480].

---

## 4. Key Role-Based Differences

| Feature | Admin Role | Member Role |
| :--- | :--- | :--- |
| **Branch Access** | Manages all data strictly within their assigned physical branch. | Views data strictly within their assigned physical branch. |
| **Attendance** | [cite_start]Marks attendance for the whole batch[cite: 416]. | [cite_start]Views personal attendance logs only[cite: 440]. |
| **Members** | [cite_start]Can add, search, and view all members in their branch[cite: 377, 383]. | [cite_start]No access to other members' data[cite: 360]. |
| **Fees** | [cite_start]Manually records payments or verifies them (Update Payment)[cite: 399]. | [cite_start]Views status and initiates payments via P2P UPI intent[cite: 461]. |
| **Events** | [cite_start]Can create and edit new branch events[cite: 422]. | [cite_start]Can favorite and register for branch events[cite: 452, 460]. |