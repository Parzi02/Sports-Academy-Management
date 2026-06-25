# 🏆 Sports Academy Management

A multi-branch Sports Academy Management platform designed to digitize academy operations, manage members, track attendance, organize events, and monitor fee payments through a centralized mobile application.

## Features

### Authentication

* OTP-based login using phone number
* Role-based access (Admin / Member)
* Secure session management

### Member Management

* Add and manage academy members
* Batch-wise member organization
* Member profile management
* Enrollment tracking

### Attendance Management

* Daily attendance marking
* Batch-wise attendance records
* Present/Absent tracking
* Attendance summaries

### Event Management

* Create academy events
* Manage upcoming and ongoing events
* Event banners and details
* Branch-specific event visibility

### Fee Management

* Track member payment status
* Paid/Due monitoring
* Fee reminders

### Multi-Branch Support

* Branch-wise data isolation
* Independent member management
* Branch-specific events and attendance

## Tech Stack

### Frontend

* Flutter

### Backend

* Node.js
* Express.js

### Database

* PostgreSQL
* Prisma ORM

### Authentication

* OTP Verification (2factor.in)

### Additional Libraries

* JWT Authentication
* bcryptjs
* Joi Validation
* Winston Logging
* Helmet Security
* Express Rate Limiter

## Project Structure

```text
Sports-Academy-Management/
├── backend/
│   ├── prisma/
│   ├── src/
│   ├── logs/
│   └── package.json
├── Appflow.md
├── Database_architecture.md
├── PRD.md
└── Sports_Academy_App_PRD.docx
```

## Installation

### Backend

```bash
cd backend

npm install

npm run dev
```

### Environment Variables

Create a `.env` file inside the backend folder and configure:

```env
DATABASE_URL=
JWT_SECRET=
OTP_API_KEY=
PORT=
```

## Core Modules

* Authentication
* Member Management
* Attendance Tracking
* Event Management
* Fee Tracking
* Branch Management
* Notifications

## Documentation

The repository includes:

* Product Requirements Document (PRD)
* Application Flow Documentation
* Database Architecture Documentation

## Demo

https://github.com/user-attachments/assets/c70babd1-8c90-4af0-b275-78a2a37f4e0a


## Future Enhancements

* Push Notifications
* Payment Gateway Integration
* Analytics Dashboard
* Coach Performance Tracking
* Advanced Reporting

## Author

**Sohan Kumar Mondal**

GitHub: https://github.com/Parzi02
LinkedIn: https://linkedin.com/in/sohan-mondal-01jul03
