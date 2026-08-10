# Scheduled Routine: Draft Artikel Harian

Jadwal: **Senin–Jumat, 08:00 WIB (01:00 UTC)**. Cron (UTC): `0 1 * * 1-5`.

## Yang dijalankan tiap fire

1. Jalankan skill `daily-konten-pendidikan-tinggi` (`.claude/skills/daily-konten-pendidikan-tinggi/SKILL.md`)
   sampai selesai **Langkah 0–6**: audit riwayat ClickUp, riset keyword, penentuan pilar/kategori/persona,
   penulisan draft, ambil category & tags (Langkah 5), dan pembuatan cover (Langkah 6 — AI Gateway +
   kompositing lokal Pillow, TANPA Canva).
2. Susun payload JSON sesuai kontrak `docs/automation-article-spec.md` Bagian 6 (`title`, `content`, `excerpt`,
   `thumbnail_id`, `cover_brief`, dan opsional `category_ids`, `tag_ids`, `seo_title`, `meta_description`,
   `focus_keyphrase`).
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
Pillow, TANPA Canva).

Setelah Langkah 6 selesai, lanjutkan:
1. Susun payload JSON sesuai docs/automation-article-spec.md Bagian 6: title, content,
   excerpt, thumbnail_id, cover_brief, dan jika relevan category_ids, tag_ids, seo_title,
   meta_description, focus_keyphrase. Simpan ke file JSON sementara.
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
