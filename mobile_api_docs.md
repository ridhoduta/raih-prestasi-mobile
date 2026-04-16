# [API Documentation: Academic System for Mobile]

This document provides the technical details for the endpoints used to manage and retrieve academic data.

## Base URL: `/api/admin/academic`

### 1. Fetch Students & Academic Data (GET)
Use this to display the list of students with achievements and their corresponding scores.

**Query Parameters:**
| Parameter | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `search` | String | No | Search by student name or NISN |
| `academicYear` | String | Yes | Format example: `2023/2024` |
| `semester` | String | Yes | Enum: `GANJIL` or `GENAP` |

**Response (JSON):**
```json
[
  {
    "id": "student_id",
    "name": "Ridho Duta",
    "nisn": "12345678",
    "kelas": "XII-A",
    "achievements": [
      {
        "id": "ach_id",
        "competitionName": "OSN Matematika",
        "result": "Juara 1",
        "points": 100
      }
    ],
    "academicScores": [
      {
        "id": "score_id",
        "subject": "Matematika",
        "score": 95,
        "academicYear": "2023/2024",
        "semester": "GANJIL"
      }
    ]
  }
]
```

---

### 2. Save Academic Scores (POST)
Use this to submit or update scores for a specific student.

**Request Body:**
```json
{
  "action": "saveScores",
  "data": {
    "studentId": "uuid_student",
    "academicYear": "2023/2024",
    "semester": "GANJIL",
    "scores": [
      { "subject": "Bahasa Indonesia", "score": 88 },
      { "subject": "Fisika", "score": 92 }
    ]
  }
}
```

---

### 3. Save Report File Metadata (POST)
Use this after uploading a file to Supabase to save the reference in the database.

**Request Body:**
```json
{
  "action": "saveAcademicFile",
  "data": {
    "fileUrl": "https://supabase-url.com/reports/rapor123.pdf",
    "academicYear": "2023/2024",
    "semester": "GANJIL"
  }
}
```

---

## Technical Notes for Mobile (Flutter/Dart)
*   **Model Mapping**: In your Dart models, ensure `points` and `score` are handled as `int` or `double`.
*   **Semester Enum**: Use an `enum` in Dart to match `GANJIL` and `GENAP` strings exactly (case-sensitive).
*   **Authentication**: Ensure requests include the required session cookies or tokens (if your mobile app uses the same auth system).
*   **Endpoints**: If your mobile app needs specific data for the *logged-in student* only, you might need a new endpoint like `/api/student/academic` which we can create based on this admin logic.

> [!IMPORTANT]
> Always verify that the `academicYear` string matches the dropdown values in the mobile UI (e.g., "2023/2024") to avoid filtering errors.

You can now use this as a reference for your `http` or `dio` service calls in the Flutter app.