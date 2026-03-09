# Walkthrough: Optimasi Endpoint API

Dokumentasi ini merangkum perubahan dan optimasi yang telah dilakukan pada beberapa endpoint API utama untuk meningkatkan performa, skalabilitas, dan pengalaman pengguna.

## Ringkasan Perubahan Utama

Berdasarkan [API Optimization Rules](file:///c:/PROJECT/raih-prestasi-web/api_optimization_rules.md), perubahan berikut telah diterapkan pada sebagian besar endpoint:

1.  **Cursor-Based Pagination**: Menggantikan offset pagination untuk performa yang stabil pada dataset besar.
2.  **Field Selection (Rule 2)**: Menggunakan Prisma `select` untuk hanya mengambil data yang diperlukan dari database, mengurangi beban network.
3.  **Server-Side Search**: Menambahkan parameter `search` untuk pencarian yang efisien di query database.
4.  **Standardized Response**: Semua API sekarang mengembalikan format konsisten: `{ success, data, nextCursor }`.

---

## Detail Perubahan per Endpoint

### 1. Guru Registration
- **Endpoint**: `GET /api/guru/registrations`
- **File**: [route.ts](file:///c:/PROJECT/raih-prestasi-web/src/app/api/guru/registrations/route.ts)
- **Perubahan**:
    - Implementasi **Cursor Pagination** menggunakan `id`.
    - Integrasi **Server-Side Search** pada nama siswa dan judul kompetisi.
    - Penggunaan **registrationSelect** untuk efisiensi pengambilan data nested (student, competition, answers).

### 2. Guru Announcement
- **Endpoint**: `/api/guru/announcement`
- **File**: [route.ts](file:///c:/PROJECT/raih-prestasi-web/src/app/api/guru/announcement/route.ts)
- **Perubahan (GET)**:
    - Cursor pagination dan filter search pada judul pengumuman.
    - Parameter `all=true` untuk menampilkan semua pengumuman (admin/guru).
- **Perubahan (POST)**:
    - Validasi input ketat (Rule 7).
    - Pengecekan keberadaan guru sebelum pembuatan data (Rule 8).

### 3. Guru Competitions
- **Endpoint**: `GET /api/guru/competitions`
- **File**: [route.ts](file:///c:/PROJECT/raih-prestasi-web/src/app/api/guru/competitions/route.ts)
- **Perubahan**:
    - Optimasi loading data kompetisi dengan cursor pagination.
    - Pencarian judul kompetisi langsung di database.
    - Pengunaan `competitionListSelect` untuk membatasi field yang dikirim ke client.

### 4. Admin News
- **Endpoint**: `GET /api/admin/news`
- **File**: [route.ts](file:///c:/PROJECT/raih-prestasi-web/src/app/api/admin/news/route.ts)
- **Perubahan**:
    - Full optimization: Cursor pagination, select fields, dan server-side search.
    - Standarisasi error handling untuk mencegah eksposur data database mentah ke client.

### 5. Student Endpoints
- **Independent Submissions**: [route.ts](file:///c:/PROJECT/raih-prestasi-web/src/app/api/student/independent-submissions/route.ts)
    - Masih menggunakan filter dasar berdasarkan `studentId`.
    - Mendukung [POST](file:///c:/PROJECT/raih-prestasi-web/src/app/api/guru/competitions/route.ts#82-145) untuk pengajuan lomba mandiri dengan status default "MENUNGGU".
- **Achievement Details**: [route.ts](file:///c:/PROJECT/raih-prestasi-web/src/app/api/student/achievement/%5BstudentId%5D/%5Bid%5D/route.ts)
    - Mengambil detail prestasi berdasarkan ID siswa dan ID prestasi.
    - Menyertakan data guru pemverifikasi dalam response menggunakan `include`.

---

## Cara Menggunakan API Hasil Optimasi

Untuk endpoint yang mendukung pagination, gunakan parameter berikut:
- `limit`: Jumlah data per batch (default: 20, max: 100).
- `cursor`: ID terakhir dari data sebelumnya untuk mengambil batch selanjutnya.
- `search`: Kata kunci pencarian (opsional).

**Contoh Request:**
`GET /api/guru/registrations?limit=10&search=Ridho&cursor=clx...`

**Contoh Response:**
```json
{
  "success": true,
  "data": [...],
  "nextCursor": "clx_id_berikutnya"
}
```
