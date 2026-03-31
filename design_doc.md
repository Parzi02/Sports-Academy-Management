
---

## 1. Design Philosophy
The app aims for a "Premium Professional" aesthetic. [cite_start]It balances the stark clarity of a sports management tool with energetic accents to motivate athletes[cite: 342, 344].

* [cite_start]**Clarity**: High contrast between text and background for readability in outdoor environments (e.g., at the turf)[cite: 541].
* [cite_start]**Action-Oriented**: Primary actions (Add Member, Pay Now, Register) are highlighted in the signature brand color[cite: 383, 422, 465].
* [cite_start]**Role-Specific Experience**: Distinct dashboard layouts for Admins and Members while maintaining a unified brand identity[cite: 340].

---

## 2. Visual Style Guide

### 2.1 Color Palette
Based on the reference theme, we move away from pure monochrome to a **Purple & Slate** scheme.

| Element | Color Hex | Usage |
| :--- | :--- | :--- |
| **Primary (Brand)** | `#6236FF` | [cite_start]Buttons (CTAs), Selected Nav Icons, OTP "Get OTP" [cite: 328, 521] |
| **Secondary (Accent)** | `#B5A1FF` | [cite_start]Progress bars, light-tinted pills for "Success" [cite: 214, 277] |
| **Background** | `#FFFFFF` | [cite_start]Main screen backgrounds [cite: 522] |
| **Surface** | `#F8F9FE` | [cite_start]Input fields, Card backgrounds, Search bars [cite: 379, 523] |
| **Text (Primary)** | `#1A1A1A` | [cite_start]Headers, Titles, Bold labels [cite: 373, 456] |
| **Status (Success)** | `#27AE60` | [cite_start]"Paid" badges, "Present" indicators [cite: 524, 527] |
| **Status (Alert)** | `#EB5757` | [cite_start]"Due" badges, "Absent" indicators [cite: 525, 526] |

### 2.2 Typography
* **Font Family**: Inter or SF Pro (Sans-Serif)
* [cite_start]**Headers**: Bold, 24pt-28pt (e.g., "Welcome, Madhu Sri") [cite: 435]
* [cite_start]**Sub-headers**: Semi-bold, 18pt (e.g., "Upcoming Events") [cite: 369]
* [cite_start]**Body Text**: Medium, 14pt (e.g., "Total Members: 60") [cite: 3]
* [cite_start]**Captions**: Regular, 12pt (e.g., "Sun, 2 Feb 2026") [cite: 10]

---

## 3. UI Components & Patterns

### 3.1 Buttons & CTAs
* [cite_start]**Primary CTA**: Rounded pill shape (Radius: 30px), Solid `#6236FF` background with White text[cite: 321, 460].
* [cite_start]**Secondary/View**: Light gray `#F5F5F5` pill with dark text[cite: 375].
* [cite_start]**Floating Action Button (FAB)**: Deep Purple circle with a White "+" icon for adding members or events[cite: 383, 422].

### 3.2 Cards & Containers
* [cite_start]**Event Cards**: Large top-rounded image (16:9 ratio), with title, venue, and time details placed in the white space below[cite: 371, 372, 374].
* [cite_start]**Member Cards**: 2-column grid style with centered profile photo and payment status badge at the bottom-right[cite: 382, 384, 387].
* [cite_start]**Summary Cards**: Gradient backgrounds (Purple to Light Purple) used for "Attendance %" and "Fee Status" on the member home screen[cite: 437].

### 3.3 Status Indicators
* **Attendance Toggle**: Circular buttons. 'P' turns solid green when active; [cite_start]'A' turns solid red when active[cite: 415, 416].
* **Fee Status**: Pill-shaped badges. "Paid" uses green-tinted backgrounds; [cite_start]"Due" uses red-tinted backgrounds[cite: 387, 524, 525].

---

## 4. Key Screen Applications

### 4.1 Onboarding (Auth)
[cite_start]Following the reference image, the **Get Started** screen features a full-bleed athlete image with a purple overlay gradient at the bottom for text readability[cite: 321]. [cite_start]The **Sign-In** screen uses the white surface with the `#6236FF` brand color for the "Continue" button[cite: 328, 404].

### 4.2 Member Home
* [cite_start]**Stat Cards**: Two horizontal cards with large icons[cite: 437].
* [cite_start]**Today's Events**: A carousel of event cards with high-quality photography[cite: 438, 439].

### 4.3 Admin Attendance
* **Date Strip**: Horizontal scrolling dates. [cite_start]Selected date is highlighted with a brand-purple circle[cite: 409, 444].
* [cite_start]**Batch Selection**: Dropdown filters using a light-purple border when focused[cite: 409].

---

## 5. Implementation Notes
* [cite_start]**Dynamic Assets**: Use `cached_network_image` for event banners and profile photos to ensure smooth scrolling[cite: 512].
* [cite_start]**Animations**: Slide-up transitions for the "Add Member" and "Add Event" forms to signify a temporary task layer[cite: 388, 423].
* [cite_start]**Iconography**: Use clean, outlined icons for the bottom nav bar, switching to solid filled icons for the active state[cite: 521].