generator client {
  provider = "prisma-client-js"
  output   = "../src/generated/prisma"
}

datasource db {
  provider = "postgresql"
}

// ==========================
// ENUM
// ==========================
enum UserRole {
  ADMIN
  GURU
}
enum RegistrationStatus {
  MENUNGGU
  DITERIMA
  DITOLAK
}
enum FieldType {
  TEXT
  TEXTAREA
  NUMBER
  FILE
  SELECT
  CHECKBOX
  RADIO
  DATE
}
enum SubmissionStatus {
  MENUNGGU
  DITERIMA
  DITOLAK
}
enum AchievementStatus {
  MENUNGGU
  TERVERIFIKASI
  DITOLAK
}


// ==========================
// USERS (Admin & Guru)
// ==========================
model User {
  id         String   @id @default(uuid())
  name       String
  email      String   @unique
  password   String
  role       UserRole
  isActive   Boolean  @default(true)

  // Relations
  news                  News[]        @relation("AdminNews")
  competitions           Competition[] // guru create competition
  reviewedSubmissions    IndependentCompetitionSubmission[]
  announcements          Announcement[]
  verifiedAchievements   Achievement[]

  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  @@map("users")
}

// ==========================
// STUDENTS
// ==========================
model Student {
  id        String   @id @default(uuid())
  nisn      String   @unique
  password  String
  name      String
  kelas     String
  angkatan  Int
  isActive  Boolean  @default(true)

  registrations   CompetitionRegistration[]
  submissions     IndependentCompetitionSubmission[]
  achievements    Achievement[]
  academicScores  AcademicScore[]

  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  @@map("students")
}

// ==========================
// COMPETITION CATEGORIES
// ==========================
model CompetitionCategory {
  id        String   @id @default(uuid())
  name      String
  isActive  Boolean  @default(true)

  competitions Competition[]

  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  @@map("competition_categories")
}

// ==========================
// COMPETITION LEVELS
// ==========================
model CompetitionLevel {
  id        String   @id @default(uuid())
  name      String
  order     Int
  isActive  Boolean  @default(true)

  competitions Competition[]

  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  @@map("competition_levels")
}

// ==========================
// NEWS
// ==========================
model News {
  id          String   @id @default(uuid())
  title       String
  content     String
  thumbnail   String?
  isPublished Boolean  @default(false)

  createdBy   String
  admin       User     @relation("AdminNews", fields: [createdBy], references: [id])

  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt

  @@map("news")
}

// ==========================
// COMPETITIONS (Guru)
// ==========================
model Competition {
  id          String   @id @default(uuid())
  title       String
  description String?
  thumbnail   String?
  isActive    Boolean  @default(true)
  startDate   DateTime
  endDate     DateTime

  categoryId  String
  category    CompetitionCategory @relation(fields: [categoryId], references: [id])

  levelId     String
  level       CompetitionLevel @relation(fields: [levelId], references: [id])

  createdBy   String
  guru        User     @relation(fields: [createdBy], references: [id])

  registrations CompetitionRegistration[]
  CompetitionFormField CompetitionFormField[]

  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt

  @@map("competitions")
}

// ==========================
// REGISTRATIONS
// ==========================


model CompetitionRegistration {
  id            String   @id @default(uuid())

  competitionId String
  competition   Competition @relation(fields: [competitionId], references: [id])

  studentId     String
  student       Student @relation(fields: [studentId], references: [id])

  status        RegistrationStatus @default(MENUNGGU)
  note          String?

  answers       RegistrationAnswer[] // ⭐ BARU

  createdAt     DateTime @default(now())
  updatedAt     DateTime @updatedAt
}

model CompetitionFormField {
  id            String   @id @default(uuid())

  competitionId String
  competition   Competition @relation(fields: [competitionId], references: [id])

  label         String
  fieldType     FieldType
  isRequired    Boolean @default(false)
  options       Json?
  order         Int
  registrationAnswer RegistrationAnswer[]

  createdAt     DateTime @default(now())
}

model RegistrationAnswer {
  id              String   @id @default(uuid())

  registrationId  String
  registration    CompetitionRegistration @relation(fields: [registrationId], references: [id])

  fieldId         String
  field           CompetitionFormField @relation(fields: [fieldId], references: [id])

  value           Json

  createdAt       DateTime @default(now())
}



// ==========================
// INDEPENDENT SUBMISSIONS
// ==========================


model IndependentCompetitionSubmission {
  id            String   @id @default(uuid())

  studentId     String
  student       Student @relation(fields: [studentId], references: [id])

  title         String
  description   String?
  documentUrl   String

  status        SubmissionStatus @default(MENUNGGU)
  rejectionNote String?
  recommendationLetter String?

  reviewedBy    String?
  guru          User?    @relation(fields: [reviewedBy], references: [id])

  createdAt     DateTime @default(now())
  updatedAt     DateTime @updatedAt

  @@map("independent_competition_submissions")
}

// ==========================
// ANNOUNCEMENTS
// ==========================
model Announcement {
  id          String   @id @default(uuid())
  title       String
  content     String
  isPublished Boolean  @default(true)

  createdBy   String
  guru        User     @relation(fields: [createdBy], references: [id])

  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt

  @@map("announcements")
}

// ==========================
// ACHIEVEMENTS
// ==========================


model Achievement {
  id          String   @id @default(uuid())

  studentId   String
  student     Student @relation(fields: [studentId], references: [id])

  competitionName String
  result      String
  certificate String?

  status      AchievementStatus @default(MENUNGGU)
  verifiedBy  String?
  guru        User?   @relation(fields: [verifiedBy], references: [id])

  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt

  @@map("achievements")
}

// ==========================
// ACADEMIC SCORES
// ==========================
model AcademicScore {
  id        String   @id @default(uuid())

  studentId String
  student   Student @relation(fields: [studentId], references: [id])

  subject   String
  score     Float
  semester  String
  year      Int

  createdAt DateTime @default(now())

  @@map("academic_scores")
}
