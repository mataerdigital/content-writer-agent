# Scheduled Routine: Draft Artikel Harian

Ada **dua routine** terjadwal, masing-masing Trigger terpisah:

| Routine | Jadwal | Cron (UTC) | Skill | Idempotency `NN` |
|---|---|---|---|---|
| Artikel pagi (Pilar 1/2/4) | Sen–Jum 08:00 WIB | `0 1 * * 1-5` | `daily-konten-pendidikan-tinggi` | `01` |
| Artikel produk (Pilar 3) | Sen–Jum 12:00 WIB | `0 5 * * 1-5` | `artikel-produk-mataer` | `02` |

Keduanya memakai aturan editorial yang sama, product knowledge yang sama (`docs/product-knowledge-mataer.md`), dan
batas backend yang sama (maks 3 draft automation per hari kerja WIB untuk gabungan semua run). Bagian di bawah ini
menjelaskan routine pagi; routine produk ada di bagian **Routine 2** di akhir dokumen.

Jadwal routine pagi: **Senin–Jumat, 08:00 WIB (01:00 UTC)**. Cron (UTC): `0 1 * * 1-5`.

## Yang dijalankan tiap fire

1. Jalankan skill `daily-konten-pendidikan-tinggi` (`.claude/skills/daily-konten-pendidikan-tinggi/SKILL.md`)
   sampai selesai **Langkah 0–6**: audit riwayat ClickUp, riset keyword, penentuan pilar/kategori/persona,
   penulisan draft, ambil category & tags (Langkah 5), dan pembuatan cover (Langkah 6 — AI Gateway +
   kompositing lokal Pillow, TANPA Canva).
2. Susun payload JSON sesuai kontrak `docs/automation-article-spec.md` Bagian 6 (`title`, `content`, `excerpt`,
   `seo_title` (= `title`), `published_at`, `thumbnail_id`, `cover_brief`, dan opsional `category_ids`, `tag_ids`,
   `meta_description`, `focus_keyphrase`). Kalau `published_at` tidak ada, `scripts/post-article.sh` mengisinya
   otomatis dengan waktu WIB saat run.
3. Jalankan `scripts/post-article.sh <path-json> [NN]` (**Langkah 7**) untuk POST ke
   `${AUTOMATION_API_BASE_URL}/api/automations/articles`. Script mengirim header `X-API-Key` (dari env
   `AUTOMATION_API_KEY`) dan `Idempotency-Key: article-<tanggal WIB YYYY-MM-DD>-<NN>` secara otomatis (`NN`
   opsional, default `01`; naikkan ke `02`, `03` dst kalau perlu submit ulang di hari yang sama, mis. untuk uji
   coba — maksimal 3 draft automation per hari kerja WIB, lihat `SKILL.md`).
4. **Setelah** Langkah 7 berhasil (bukan sebelumnya), arsipkan ke ClickUp Doc (**Langkah 8**).
5. Laporkan hasil: status HTTP, response body (`id`, `slug`, `status`, `review_url`, `clickup_task_id`), dan
   link ClickUp Doc/Task.

Endpoint ini idempotent per hari kerja (key `article-YYYY-MM-DD-NN` WIB) — jangan retry otomatis lebih dari
sekali kalau POST gagal; laporkan errornya.

## Env var yang wajib ada di environment yang menjalankan routine ini

| Env | Keterangan |
|---|---|
| `AUTOMATION_API_KEY` | API key untuk header `X-API-Key` |
| `AUTOMATION_API_BASE_URL` | Base URL backend, mis. `https://api.mataerdigital.com` (production; tanpa trailing slash atau path; jangan pakai tunnel lokal developer) |
| `AI_GATEWAY_API_KEY` | Auth ke Vercel AI Gateway untuk generate foto cover (Langkah 6) |

## Catatan gap

- Skill menghasilkan nama Website Category / Topic Cluster, bukan `category_ids`/`tag_ids` numerik. Selama
  backend belum expose lookup id-by-name, field itu boleh dikosongkan (opsional di spec) sampai mapping tersedia.
- **ClickUp MCP tidak tersedia → tidak fatal.** Kalau tools ClickUp (`clickup_search`, `clickup_create_document`,
  dst.) tidak tersambung di environment yang menjalankan routine ini, Langkah 0 (audit) dan Langkah 8 (arsip)
  di-skip dengan catatan di ringkasan (lihat fallback di `SKILL.md` Langkah 0) — routine tetap lanjut ke Langkah
  1-7 dan draft tetap terkirim ke website, karena Langkah 7 tidak bergantung pada ClickUp MCP sama sekali.

## Prompt untuk trigger

Gunakan teks berikut sebagai prompt Routine/Trigger (Sen–Jum 08:00 WIB / `0 1 * * 1-5` UTC):

```
Jalankan skill daily-konten-pendidikan-tinggi untuk menghasilkan satu draft artikel
harian sesuai framework 4 pilar (lihat .claude/skills/daily-konten-pendidikan-tinggi/SKILL.md).
Ikuti seluruh Langkah 0-6: audit riwayat ClickUp (skip dengan catatan kalau ClickUp MCP
tidak tersambung, JANGAN berhenti di sini), riset keyword, penentuan pilar/kategori/persona,
penulisan draft, ambil category & tags, dan pembuatan cover (AI Gateway + kompositing lokal
Pillow, TANPA Canva). Penulisan draft wajib mengikuti alur Langkah 4 (Keyword → Search
Intent → Kebutuhan Pembaca → Angle → Judul → Struktur → Artikel) dan lolos Quality Gate
Langkah 4I (judul = H1 = SEO title, fact check, overclaim, product fact check, repetisi,
akronim, minimal 3 internal link di dalam kalimat, tanpa sumber kompetitor).

Setelah Langkah 6 selesai, lanjutkan:
1. Susun payload JSON sesuai docs/automation-article-spec.md Bagian 6: title, content,
   excerpt, seo_title (sama persis dengan title), published_at (Langkah 4H), thumbnail_id,
   cover_brief, dan jika relevan category_ids, tag_ids, meta_description, focus_keyphrase.
   Simpan ke file JSON sementara.
2. Jalankan scripts/post-article.sh <path-json> dari root repo content-writer-agent
   (Langkah 7) untuk POST ke ${AUTOMATION_API_BASE_URL}/api/automations/articles (script ini
   otomatis mengirim X-API-Key dari env AUTOMATION_API_KEY dan Idempotency-Key
   article-<tanggal WIB YYYY-MM-DD>-01; kalau perlu submit ulang di hari sama, jalankan
   dengan argumen kedua NN, mis. scripts/post-article.sh <path-json> 02).
3. SETELAH Langkah 7 berhasil, arsipkan ke ClickUp Doc (Langkah 8) kalau ClickUp MCP
   tersambung — skip dengan catatan kalau tidak tersambung, jangan gagalkan run karena ini.
4. Laporkan status HTTP, response body (id, slug, status, review_url, clickup_task_id),
   dan link ClickUp Doc/Task dari Langkah 8 (kalau berhasil dibuat).

Jika POST Langkah 7 gagal, laporkan error dengan jelas. Jangan retry otomatis lebih dari
sekali - endpoint idempotent per hari kerja berdasarkan Idempotency-Key.
```

## Cara mengaktifkan permanen

Sesi chat ini hanya bisa membuat cron **sementara** (maks 7 hari, hanya jalan saat sesi idle). Untuk jadwal
permanen Sen–Jum selamanya, buat **Trigger** (scheduled) untuk repo ini melalui dashboard Claude Code on the web
(atau lewat `create_trigger`/`update_trigger` dari sesi chat):

1. Pilih repo `mataerdigital/content-writer-agent`, branch `main`.
2. Buat/update Trigger dengan cron `0 1 * * 1-5` (UTC) dan prompt di atas.
3. Pastikan environment Trigger punya `AUTOMATION_API_KEY`, `AUTOMATION_API_BASE_URL` (production), dan
   `AI_GATEWAY_API_KEY`. Koneksi ClickUp MCP tidak wajib (ada fallback), tapi disarankan supaya Langkah 0/8
   berjalan penuh.

Detail fitur Trigger: https://code.claude.com/docs/en/claude-code-on-the-web

---

## Routine 2: Artikel Produk (12:00 WIB)

Jadwal: **Senin–Jumat, 12:00 WIB (05:00 UTC)**. Cron (UTC): `0 5 * * 1-5`. Repo, branch, dan env var sama dengan
routine pagi (`AUTOMATION_API_KEY`, `AUTOMATION_API_BASE_URL` production, `AI_GATEWAY_API_KEY`). Buat sebagai
**Trigger terpisah**, jangan digabung ke Trigger pagi.

Prompt untuk trigger:

```
Jalankan skill artikel-produk-mataer (.claude/skills/artikel-produk-mataer/SKILL.md) untuk
menghasilkan satu draft artikel pengenalan produk Mataer (Pilar 3). Baca dulu
.claude/skills/daily-konten-pendidikan-tinggi/SKILL.md (semua aturan editorial & teknis berlaku)
dan docs/product-knowledge-mataer.md (satu-satunya sumber fitur/klaim produk).

Ikuti alur P0-P6: pilih produk lewat rotasi (jangan bentrok dengan artikel run pagi hari ini;
skip cek ClickUp dengan catatan kalau ClickUp MCP tidak tersambung, JANGAN berhenti), pilih
use case spesifik, riset konteks dari sumber resmi, tulis artikel mengikuti Langkah 4 skill
pagi (4A-4I) dengan penyesuaian P5, lolos Quality Gate 4I, lalu Langkah 5-6 (category/tags,
cover).

Setelah itu:
1. Susun payload JSON sesuai docs/automation-article-spec.md Bagian 6 (title, content,
   excerpt, seo_title = title, published_at, thumbnail_id, cover_brief, dan jika relevan
   category_ids, tag_ids, meta_description, focus_keyphrase). Simpan ke file JSON sementara.
2. Jalankan scripts/post-article.sh <path-json> 02 dari root repo (NN run produk = 02).
3. SETELAH POST berhasil, arsipkan ke ClickUp Doc kalau ClickUp MCP tersambung.
4. Laporkan status HTTP, response body (id, slug, status, review_url, clickup_task_id),
   dan link ClickUp Doc.

Jika POST gagal, laporkan error dengan jelas. Jangan retry otomatis lebih dari sekali.
```

## Uji ke API dev

Sebelum mengaktifkan/mengubah routine, uji kontrak API ke backend dev (bukan production):

```bash
AUTOMATION_API_KEY=<key dev> scripts/test-dev-api.sh
```

Script ini memakai `https://api-dev.mataerdigital.com` secara default (override dengan `DEV_API_BASE_URL`), dan
menolak jalan kalau base URL-nya production. Tanpa `AUTOMATION_API_KEY` hanya endpoint publik + cek auth yang diuji.
