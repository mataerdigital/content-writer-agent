# Scheduled Routine: Draft Artikel Harian

Jadwal: **Senin–Jumat, 08:00 WIB (01:00 UTC)**. Cron (UTC): `0 1 * * 1-5`.

## Yang dijalankan tiap fire

1. Jalankan skill `daily-konten-pendidikan-tinggi` (`.claude/skills/daily-konten-pendidikan-tinggi/SKILL.md`) sampai selesai Langkah 0–6, termasuk simpan ke ClickUp (ClickUp Doc + ClickUp Task, Langkah 6).
2. Susun payload JSON sesuai kontrak `docs/automation-article-spec.md` Bagian 6 (`title`, `content`, `excerpt`, dan opsional `category_ids`, `tag_ids`, `seo_title`, `meta_description`, `focus_keyphrase`).
3. Jalankan `scripts/post-article.sh <path-json>` untuk POST ke `${AUTOMATION_API_BASE_URL}/api/automations/articles`. Script mengirim header `X-API-Key` (dari env `AUTOMATION_API_KEY`) dan `Idempotency-Key: article-<tanggal WIB YYYY-MM-DD>` secara otomatis.
4. Laporkan hasil: status HTTP, response body (`id`, `slug`, `status`, `review_url`, `clickup_task_id`), dan link ClickUp Doc/Task dari Langkah 6.

Endpoint ini idempotent per hari kerja (key `article-YYYY-MM-DD` WIB) — jangan retry otomatis lebih dari sekali kalau POST gagal; laporkan errornya.

## Env var yang wajib ada di environment yang menjalankan routine ini

| Env | Keterangan |
|---|---|
| `AUTOMATION_API_KEY` | API key untuk header `X-API-Key` |
| `AUTOMATION_API_BASE_URL` | Base URL backend, mis. `https://dev.mataerdigital.com` (tanpa trailing slash atau path) |

## Catatan gap

- Skill menghasilkan nama Website Category / Topic Cluster, bukan `category_ids`/`tag_ids` numerik. Selama backend belum expose lookup id-by-name, field itu boleh dikosongkan (opsional di spec) sampai mapping tersedia.
- ClickUp MCP tools (`clickup_create_document`, dst.) harus tersedia/terhubung di environment yang menjalankan routine ini agar Langkah 6 berhasil.

## Prompt untuk trigger

Gunakan teks berikut sebagai prompt Routine/Trigger (Sen–Jum 08:00 WIB / `0 1 * * 1-5` UTC):

```
Jalankan skill daily-konten-pendidikan-tinggi untuk menghasilkan satu draft artikel
harian sesuai framework 4 pilar (lihat .claude/skills/daily-konten-pendidikan-tinggi/SKILL.md).
Ikuti seluruh Langkah 0-6, termasuk audit riwayat ClickUp, riset keyword, penentuan
pilar/kategori/persona, penulisan draft, arahan cover, dan penyimpanan ke ClickUp
(Langkah 6: ClickUp Doc + ClickUp Task).

Setelah Langkah 6 selesai, lanjutkan:
1. Susun payload JSON sesuai docs/automation-article-spec.md Bagian 6: title, content,
   excerpt, dan jika relevan category_ids, tag_ids, seo_title, meta_description,
   focus_keyphrase. Simpan ke file JSON sementara.
2. Jalankan scripts/post-article.sh <path-json> dari root repo content-writer-agent
   untuk POST ke ${AUTOMATION_API_BASE_URL}/api/automations/articles (script ini
   otomatis mengirim X-API-Key dari env AUTOMATION_API_KEY dan Idempotency-Key
   article-<tanggal WIB YYYY-MM-DD>).
3. Laporkan status HTTP, response body (id, slug, status, review_url, clickup_task_id),
   dan link ClickUp Doc/Task dari Langkah 6.

Jika POST gagal, laporkan error dengan jelas. Jangan retry otomatis lebih dari
sekali - endpoint idempotent per hari kerja berdasarkan Idempotency-Key.
```

## Cara mengaktifkan permanen

Sesi chat ini hanya bisa membuat cron **sementara** (maks 7 hari, hanya jalan saat sesi idle). Untuk jadwal permanen Sen–Jum selamanya, buat **Trigger** (scheduled) untuk repo ini melalui dashboard Claude Code on the web:

1. Pilih repo `mataerdigital/content-writer-agent`, branch target (mis. `main` setelah PR ini di-merge).
2. Buat Trigger baru dengan cron `0 1 * * 1-5` (UTC) dan prompt di atas.
3. Pastikan environment Trigger punya `AUTOMATION_API_KEY`, `AUTOMATION_API_BASE_URL`, dan koneksi ClickUp MCP terpasang.

Detail fitur Trigger: https://code.claude.com/docs/en/claude-code-on-the-web
