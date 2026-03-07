# API Documentation - Raih Prestasi

Dokumentasi API untuk project Raih Prestasi Web.

## Admin API
| Method | Route | Response |
| :--- | :--- | :--- |
| GET | `/api/admin/competition-categories` | `{ success: boolean, data: Category[] }` |
| POST | `/api/admin/competition-categories` | `{ success: boolean, data: Category }` |
| GET | `/api/admin/competition-categories/:id` | `{ success: boolean, data: Category }` |
| PUT | `/api/admin/competition-categories/:id` | `{ success: boolean, data: Category }` |
| DELETE | `/api/admin/competition-categories/:id` | `{ success: boolean, message: string }` (Soft delete) |
| GET | `/api/admin/competition-levels` | `{ success: boolean, data: Level[] }` |
| POST | `/api/admin/competition-levels` | `{ success: boolean, data: Level }` |
| GET | `/api/admin/competition-levels/:id` | `{ success: boolean, data: Level }` |
| PUT | `/api/admin/competition-levels/:id` | `{ success: boolean, data: Level }` |
| DELETE | `/api/admin/competition-levels/:id` | `{ success: boolean, message: string }` (Soft delete) |
| GET | `/api/admin/dashboard` | `{ success: boolean, data: { totalGuru, totalSiswa, activeCompetitions, totalPrestasi, recentActivities } }` |
| GET | `/api/admin/guru` | `{ success: boolean, data: Guru[] }` |
| POST | `/api/admin/guru` | `{ success: boolean, message: string, data: Guru }` |
| GET | `/api/admin/guru/:id` | `{ success: boolean, data: Guru }` |
| PUT | `/api/admin/guru/:id` | `{ success: boolean, message: string, data: Guru }` |
| DELETE | `/api/admin/guru/:id` | `{ success: boolean, message: string }` (Deactivate) |
| GET | `/api/admin/news` | `{ success: boolean, data: News[] }` |
| POST | `/api/admin/news` | `{ success: boolean, message: string, data: News }` |
| GET | `/api/admin/news/:id` | `{ success: boolean, data: News }` |
| PUT | `/api/admin/news/:id` | `{ success: boolean, message: string, data: News }` |
| DELETE | `/api/admin/news/:id` | `{ success: boolean, message: string }` |
| GET | `/api/admin/students` | `{ success: boolean, data: Student[] }` |
| POST | `/api/admin/students` | `{ success: boolean, data: Student }` |

## Auth API
| Method | Route | Response |
| :--- | :--- | :--- |
| POST | `/api/auth/login` | `{ message: string, user: { id, name, email, nisn, role } }` |
| POST | `/api/auth/logout` | `{ message: string }` |

## Guru API
| Method | Route | Response |
| :--- | :--- | :--- |
| GET | `/api/guru/achievement` | `{ success: boolean, data: Achievement[] }` |
| GET | `/api/guru/achievement/:id` | `{ success: boolean, message: string, data: Achievement }` |
| PUT | `/api/guru/achievement/:id` | `{ success: boolean, message: string, data: Achievement }` |
| DELETE | `/api/guru/achievement/:id` | `{ success: boolean, message: string, data: Achievement }` |
| GET | `/api/guru/announcement` | `{ success: boolean, data: Announcement[] }` |
| POST | `/api/guru/announcement` | `{ success: boolean, message: string, data: Announcement }` |
| GET | `/api/guru/announcement/:id` | `{ success: boolean, data: Announcement }` |
| PUT | `/api/guru/announcement/:id` | `{ success: boolean, message: string, data: Announcement }` |
| DELETE | `/api/guru/announcement/:id` | `{ success: boolean, message: string }` |
| GET | `/api/guru/competitions` | `{ success: boolean, data: Competition[] }` |
| POST | `/api/guru/competitions` | `{ success: boolean, data: Competition }` |
| GET | `/api/guru/competitions/:id` | `{ success: boolean, data: Competition }` |
| PUT | `/api/guru/competitions/:id` | `{ success: boolean, message: string, data: Competition }` |
| DELETE | `/api/guru/competitions/:id` | `{ success: boolean, message: string }` |
| POST | `/api/guru/competitions/:id/form-fields` | `{ success: boolean, message: string, insertedCount: number }` |
| GET | `/api/guru/competitions/:id/form-fields` | `{ success: boolean, data: FormField[] }` |
| PUT | `/api/guru/competitions/:id/form-fields` | `{ success: boolean, message: string, data: FormField }` |
| DELETE | `/api/guru/competitions/:id/form-fields` | `{ success: boolean, message: string }` |
| GET | `/api/guru/competitions/:id/registrations` | `{ success: boolean, data: Registration[] }` |
| GET | `/api/guru/competitions/:id/registrations/:registrationId` | `{ success: boolean, data: RegistrationDetail }` |
| PATCH | `/api/guru/competitions/:id/registrations/:registrationId/verify` | `{ success: boolean, message: string, data: Registration }` |
| GET | `/api/guru/independent-submissions` | `{ success: boolean, data: Submission[] }` |
| GET | `/api/guru/independent-submissions/:id` | `{ success: boolean, data: Submission[] }` |
| PUT | `/api/guru/independent-submissions/:id` | `{ success: boolean, message: string, data: Submission }` |
| DELETE | `/api/guru/independent-submissions/:id` | `{ success: boolean, message: string }` |
| GET | `/api/guru/registrations` | `{ success: boolean, data: Registration[] }` |
| GET | `/api/guru/registrations/:id` | `{ success: boolean, data: RegistrationDetail }` |
| PUT | `/api/guru/registrations/:id` | `{ success: boolean, message: string, data: Registration }` |

## Student API
| Method | Route | Response |
| :--- | :--- | :--- |
| POST | `/api/student/achievement` | `{ success: boolean, message: string, data: { achievement } }` |
| GET | `/api/student/achievement/:studentId` | `{ success: boolean, message: string, data: { data } }` |
| GET | `/api/student/achievement/:studentId/:id` | `{ success: boolean, message: string, data: { data } }` |
| POST | `/api/student/competitions/:id/register` | `{ success: boolean, message: string, data: { registrationId } }` |
| GET | `/api/student/independent-submissions` | `{ success: boolean, data: Submission[] }` |
| POST | `/api/student/independent-submissions` | `{ success: boolean, data: Submission }` |
| GET | `/api/student/independent-submissions/:id` | `{ success: boolean, data: Submission }` |
| PUT | `/api/student/independent-submissions/:id` | `{ success: boolean, message: string, data: Submission }` |
| DELETE | `/api/student/independent-submissions/:id` | `{ success: boolean, message: string }` |

## Upload API
| Method | Route | Response |
| :--- | :--- | :--- |
| POST | `/api/upload` | `{ success: boolean, url: { publicUrl: string } }` |
