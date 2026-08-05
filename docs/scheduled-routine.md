# Scheduled Routine: Draft Artikel Harian

Jadwal: **Senin–Jumat, 08:00 WIB (01:00 UTC)**. Cron (UTC): `0 1 * * 1-5`.

## Yang dijalankan tiap fire

1. Jalankan skill `daily-konten-pendidikan-tinggi` (`.claude/skills/daily-konten-pendidikan-tinggi/SKILL.md`) sampai selesai Langkah 0–8, termasuk simpan ke ClickUp (ClickUp Doc, Langkah 8).
2. Susun payload JSON sesuai kontrak `docs/automation-article-spec.md` Bagian 6 (`title`, `content`, `excerpt`, dan opsional `category_ids`, `tag_ids`, `seo_title`, `meta_description`, `focus_keyphrase`, `thumbnail_id`, `cover_brief`).
3. Jalankan `scripts/post-article.sh <path-json> [NN]` untuk POST ke `${AUTOMATION_API_BASE_URL}/api/automations/articles`. Script mengirim header `X-API-Key` (dari env `AUTOMATION_API_KEY`) dan `Idempotency-Key: article-<tanggal WIB YYYY-MM-DD>-<NN>` secara otomatis (`NN` opsional, default `01`; lihat aturan Idempotency-Key di SKILL.md).
4. Laporkan hasil: status HTTP, response body (`id`, `slug`, `status`, `review_url`, `clickup_task_id`), dan link ClickUp Doc dari Langkah 8.

Endpoint ini idempotent per key `article-YYYY-MM-DD-NN` (WIB) — kalau perlu retry di run yang sama, pakai `NN` yang sama (bukan bikin baru); baru naikkan `NN` kalau memang sengaja submit ulang di hari yang sama (mis. untuk testing). Jangan retry otomatis lebih dari sekali kalau POST gagal; laporkan errornya.

## Env var yang wajib ada di environment yang menjalankan routine ini

| Env | Keterangan |
|---|---|
| `AUTOMATION_API_KEY` | API key untuk header `X-API-Key` |
| `AUTOMATION_API_BASE_URL` | Base URL backend, mis. `https://dev.mataerdigital.com` (tanpa trailing slash atau path) |

## Connector yang wajib tersambung di environment/Trigger yang menjalankan routine ini

| Connector | Dipakai untuk |
|---|---|
| ClickUp | Langkah 0 (audit riwayat) & Langkah 8 (arsip ClickUp Doc) |
| Canva | Langkah 6B (generate & export cover artikel) |

**Penting:** kalau routine ini dibuat lewat `create_trigger`, connector TIDAK otomatis ikut terbawa ke sesi yang di-fire kecuali parameter `connectors: ["ClickUp", "Canva"]` diisi eksplisit saat membuat Trigger-nya — connector hanya bisa dioper dari yang dipegang sesi pembuat Trigger saat itu. Kalau connector tidak tersambung saat fire, skill tetap harus lanjut jalan dengan fallback (audit dari histori percakapan / kirim draft tanpa thumbnail), bukan gagal total.

## Catatan gap

- Kategori backend test (`pc-fajar.campusupdate.co.id`) baru punya sebagian kecil dari 9 Website Category yang didefinisikan skill (per Agustus 2026 baru ada 5 kategori, 2 di antaranya cocok). Selama kategori yang dipilih skill belum ada di `GET /api/category/listPublic`, field `category_ids` boleh dikosongkan (opsional di spec) sesuai aturan Langkah 5A.
- Endpoint tag publik ada di `GET /api/tags/listPublic?type=article&limit=100` (bukan `/api/tag/listPublic`). Hanya pakai tag yang memang ada & relevan (Langkah 5B); jangan menebak/membuat tag baru.

## Prompt untuk trigger

Gunakan teks berikut sebagai prompt Routine/Trigger (Sen–Jum 08:00 WIB / `0 1 * * 1-5` UTC):

```
Jalankan skill daily-konten-pendidikan-tinggi untuk menghasilkan satu draft artikel
harian sesuai framework 4 pilar (lihat .claude/skills/daily-konten-pendidikan-tinggi/SKILL.md).
Ikuti seluruh Langkah 0-8: audit riwayat ClickUp, riset keyword, penentuan
pilar/kategori/persona, penulisan draft, ambil category & tags (Langkah 5), buat &
upload cover via Canva MCP (Langkah 6), kirim draft (Langkah 7), dan arsip ke
ClickUp Doc (Langkah 8).

Setelah draft selesai ditulis, lanjutkan:
1. Susun payload JSON sesuai docs/automation-article-spec.md Bagian 6: title, content,
   excerpt, dan jika relevan category_ids, tag_ids, seo_title, meta_description,
   focus_keyphrase, thumbnail_id, cover_brief. Simpan ke file JSON sementara.
2. Jalankan scripts/post-article.sh <path-json> dari root repo content-writer-agent
   untuk POST ke ${AUTOMATION_API_BASE_URL}/api/automations/articles (script ini
   otomatis mengirim X-API-Key dari env AUTOMATION_API_KEY dan Idempotency-Key
   article-<tanggal WIB YYYY-MM-DD>-01).
3. Laporkan status HTTP, response body (id, slug, status, review_url, clickup_task_id),
   dan link ClickUp Doc dari Langkah 8.

Jika POST gagal, laporkan error dengan jelas. Jangan retry otomatis lebih dari
sekali dengan Idempotency-Key yang sama - endpoint idempotent per key
article-YYYY-MM-DD-NN (WIB).
```

## Cara mengaktifkan permanen

Sesi chat ini hanya bisa membuat cron **sementara** (maks 7 hari, hanya jalan saat sesi idle). Untuk jadwal permanen Sen–Jum selamanya, buat **Trigger/Routine** (`create_trigger`) untuk repo ini:

1. Pilih repo `mataerdigital/content-writer-agent`, branch target `main` (setelah PR ini di-merge).
2. Buat Trigger baru dengan cron `0 1 * * 1-5` (UTC) dan prompt di atas.
3. **Wajib isi parameter `connectors: ["ClickUp", "Canva"]`** saat membuat Trigger — kalau tidak diisi, sesi yang di-fire Trigger TIDAK akan punya akses ke connector ClickUp/Canva sama sekali (sudah terverifikasi lewat testing: Trigger tanpa `connectors` eksplisit membuat Langkah 0, 6, dan 8 gagal karena connector tidak tersambung).
4. Pastikan environment Trigger punya `AUTOMATION_API_KEY` dan `AUTOMATION_API_BASE_URL` sebagai env var.

Detail fitur Trigger: https://code.claude.com/docs/en/claude-code-on-the-web
