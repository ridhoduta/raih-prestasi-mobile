# 🚀 Flutter Performance Optimization Guide

## 🎯 Tujuan

* Mengurangi waktu loading screen
* Meningkatkan performa saat data besar
* Menghindari lag saat scrolling
* Memberikan UX yang smooth & responsif

---

## 🧠 Akar Masalah Umum

* Fetch data setiap buka screen
* Tidak ada caching
* Load semua data sekaligus
* Parsing JSON di main thread
* UI menunggu data selesai sebelum render

---

## 🟢 STEP 1 — Gunakan `http.Client`

### ❌ Sebelum

```dart
await http.get(uri);
```

### ✅ Setelah

```dart
class ApiService {
  final http.Client client = http.Client();

  Future<PaginatedResponse<Achievement>> getAchievements(...) async {
    final response = await client.get(uri);

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      return PaginatedResponse.fromJson(
        body,
        (json) => Achievement.fromJson(json),
      );
    } else {
      throw Exception('Error');
    }
  }
}
```

---

## 🟢 STEP 2 — Tambahkan Cache Sederhana

```dart
final Map<String, dynamic> _cache = {};
```

```dart
Future<PaginatedResponse<Achievement>> getAchievements(
  String studentId,
) async {
  final key = "achievements_$studentId";

  if (_cache.containsKey(key)) {
    return _cache[key];
  }

  final response = await client.get(uri);

  if (response.statusCode == 200) {
    final body = json.decode(response.body);
    final data = PaginatedResponse.fromJson(
      body,
      (json) => Achievement.fromJson(json),
    );

    _cache[key] = data;
    return data;
  } else {
    throw Exception('Error');
  }
}
```

---

## 🟡 STEP 3 — Gunakan `ListView.builder`

### ❌ Salah

```dart
ListView(
  children: achievements.map(...).toList(),
)
```

### ✅ Benar

```dart
ListView.builder(
  itemCount: achievements.length,
  itemBuilder: (context, index) {
    return AchievementItem(achievements[index]);
  },
)
```

---

## 🟡 STEP 4 — Gunakan Pagination

Contoh:

```dart
GET /achievement?limit=20&cursor=xxx
```

Implementasi:

* Load 20 data pertama
* Scroll → load berikutnya
* Gabungkan ke list

---

## 🟡 STEP 5 — Gunakan Loading Skeleton

* Hindari blank screen
* Gunakan shimmer / skeleton loader

---

## 🟠 STEP 6 — Parsing di Background (Isolate)

```dart
return compute(parseAchievements, response.body);
```

```dart
PaginatedResponse<Achievement> parseAchievements(String body) {
  final Map<String, dynamic> jsonData = json.decode(body);
  return PaginatedResponse.fromJson(
    jsonData,
    (json) => Achievement.fromJson(json),
  );
}
```

---

## 🧩 STEP 7 — Pisahkan List & Detail

* List → data ringan
* Detail → fetch saat dibuka

---

## 🧠 STEP 8 — Preload Data

* Fetch data sebelum user masuk screen
* Membuat navigasi terasa instan

---

## 🔴 STEP 9 — Gunakan State Management

Struktur ideal:

```
UI
 ↓
State (Provider / Riverpod)
 ↓
Repository
 ↓
API Service
 ↓
Cache
```

---

## ⚠️ Hindari

* Fetch di `build()`
* Tidak pakai cache
* Load semua data sekaligus
* Parsing di main thread
* List tanpa builder

---

## 🚀 Prioritas Implementasi

| Step | Task             | Impact |
| ---- | ---------------- | ------ |
| 1    | http.Client      | ⭐⭐     |
| 2    | Cache            | ⭐⭐⭐⭐⭐  |
| 3    | ListView.builder | ⭐⭐⭐⭐   |
| 4    | Pagination       | ⭐⭐⭐⭐   |
| 5    | Skeleton         | ⭐⭐⭐    |
| 6    | compute()        | ⭐⭐⭐⭐   |
| 7    | State Mgmt       | ⭐⭐⭐⭐⭐  |

---

## 💡 Strategi Paling Efektif

Fokus utama:

* Cache
* Lazy loading (ListView.builder)

Hasil:

* Performa meningkat 50–80%

---

## 🔥 Flow Optimal

1. User buka screen
2. Data muncul dari cache ⚡
3. Background refresh 🔄
4. UI update otomatis

---

## 📌 Kesimpulan

Optimasi performa bukan hanya di Flutter, tapi:

* Cara fetch data
* Cara render UI
* Strategi caching

Dengan implementasi sederhana, aplikasi sudah bisa mencapai level production 🚀
