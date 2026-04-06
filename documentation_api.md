# Walkthrough - Firebase Cloud Messaging & Notifications

I have successfully implemented the notification flow for students when a Guru updates their status.

## Changes Made

### 1. Database Schema
Updated `prisma/schema.prisma` with two new models:
- **`FCMToken`**: Stores student FCM tokens (supports multiple devices).
- **`Notification`**: Stores the history of notifications sent to students.

Used `npx prisma generate` to update the client.

### 2. Service Layer
Refactored `src/app/service/pushNotif.ts`:
- **`sendNotification(tokens: string[], ...)`**: Now supports sending to multiple tokens at once using `sendEachForMulticast`.
- **`createAndSendNotification(...)`**: A high-level helper that:
    1. Saves the notification to the database.
    2. Fetches all active tokens for the student.
    3. Triggers the push notification.
- Added **auto-cleanup**: If a token is invalid (unregistered), it is automatically removed from the database.

### 3. Student API Routes
- **`POST /api/student/fcm-token`**: Allows students to register/update their FCM tokens upon login.
- **`GET /api/student/notifications`**: Fetches the notification history with cursor-based pagination.
- **`PATCH /api/student/notifications`**: Marks notifications as read (supports specific ID or "mark all").

### 4. Guru API Integration
Integrated notification triggers in the Following routes:
- **Achievements**: `PUT /api/guru/achievement/[id]/route.ts`
- **Independent Submissions**: `PUT /api/guru/independent-submissions/[id]/route.ts`
- **Registrations**: `PUT /api/guru/registrations/[id]/route.ts`

## How to Test

### 1. Save Token
From the Flutter app (or Postman), call:
`POST /api/student/fcm-token`
Body: `{ "token": "your_fcm_token_here" }`

### 2. Trigger Notification
As a Guru, update the status of:
- An independent submission.
- A competition registration.
- An achievement verification.

### 3. Fetch Notifications
As a student, fetch your list:
`GET /api/student/notifications?limit=10`

---
> [!NOTE]
> Make sure your `serviceAccountKey.json` is correctly placed in `src/app/service/` as referenced in `firebaseService.ts`.
