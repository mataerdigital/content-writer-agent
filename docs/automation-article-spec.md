# Spec: Automation Article (Claude → Draft → Review → Publish)

## 1. Tujuan

Claude (skill author) membuat 1 draft artikel per hari kerja (Sen–Jum, 08:00 WIB) secara otomatis ke web ini. Admin sosmed cukup review lalu klik Publish. Setiap draft otomatis menghasilkan task ClickUp + email ke tim kreatif. Saat artikel dipublish, task ClickUp otomatis ditutup.

## 2. Aktor & Peran

| Aktor | Peran |
|---|---|
| Claude routine (Opsi A) ✅ | Generate konten + push ke API (menjadwalkan sendiri Sen–Jum 08:00 WIB) |
| Backend (web ini) | Terima → simpan draft → bikin task ClickUp + kirim email |
| Author ✅ | Akun `creative@mataerdigital.com` (di-resolve via email) sebagai penulis |
| Reviewer / assignee ✅ | Admin sosmed (orang tertentu) — penerima task ClickUp |
| Penerima email ✅ | `creative@mataerdigital.com` |

## 3. Kebutuhan Fungsional (WAJIB)

- Endpoint ingestion `POST /api/automations/articles` yang dipanggil Claude. ✅
- Artikel dibuat selalu `status = draft` dan `origin = automation`; endpoint ini **tidak bisa** mem-publish. ✅
- Author di-resolve dari email `AUTOMATION_AUTHOR_EMAIL` (default `creative@mataerdigital.com`). Kalau user tak ada → error jelas + log. ✅
- **Idempotency** (anti dobel saat retry): key `article-YYYY-MM-DD-NN` (WIB, `NN` = angka urut 2 digit mulai `01`).
  Key yang sama dua kali → kembalikan artikel yang sudah ada (`duplicated:true`), tidak dibuat dobel.
  - **Dikonfirmasi via test 5 Agustus 2026:** backend membatasi maksimal **3 draft automation per hari kerja WIB**
    independen dari `NN` (429 `"Batas maksimal 3 draft automation per hari sudah tercapai"` pada draft ke-4,
    berapa pun `NN`-nya). Jadi `NN` hanya penanda unik per submission dalam batas 3/hari itu, bukan cara menembus
    limitnya.
- Thumbnail (MVP Opsi A): kosong saat draft; admin isi saat review. ✅
- ClickUp task dibuat saat draft dibuat ✅ — judul `"Review: <title>"`, assignee = admin sosmed, deskripsi berisi review URL, dan simpan `clickup_task_id` di artikel.
- Email dibuat saat draft dibuat ✅ — ke `creative@mataerdigital.com`, membawa `title` + `review_url`.
- Publish tetap lewat endpoint existing `PUT /api/article/:id`. Saat `status` berubah ke `published` dan `origin = automation` dan ada `clickup_task_id` → ClickUp task di-close otomatis. ✅
- Side-effect (ClickUp + email) tidak boleh menggagalkan pembuatan artikel (non-blocking + log). ✅
- Tidak ada in-app notification (cukup ClickUp + email). ✅

## 4. Alur End-to-End

```
Sen–Jum 08:00 WIB → Claude routine generate konten
  → POST /api/automations/articles  (X-API-Key, Idempotency-Key)
      → create Article: draft, origin=automation, author=creative@
      → ClickUp: create task (assignee=admin sosmed) → simpan clickup_task_id
      → Email ke creative@ (title + review_url)
  → Admin sosmed: tambah thumbnail + review → Publish (PUT /article/:id)
      → ClickUp task → complete/closed
```

## 5. Perubahan Data (Prisma)

```prisma
enum ArticleOrigin {
  manual
  automation
}

model Article {
  // ...
  origin          ArticleOrigin @default(manual)
  clickup_task_id String?
  idempotency_key String?       @unique
}
```

Migration kecil, tanpa relasi baru (delete tetap aman).

## 6. Endpoint

**Baru:** `POST /api/automations/articles`
- Auth: `X-API-Key`, rate-limited.
- Body:
  - `title`
  - `content`
  - `excerpt`
  - `category_ids?`
  - `tag_ids?`
  - `seo_title?`
  - `meta_description?`
  - `focus_keyphrase?`
  - `thumbnail_url?` *(opsional, untuk Opsi B nanti)*
- Header: `X-API-Key`, `Idempotency-Key`
- Response:
  ```json
  {
    "id": "...",
    "slug": "...",
    "status": "draft",
    "review_url": "...",
    "clickup_task_id": "..."
  }
  ```

**Diubah (tambah hook):** `PUT /api/article/:id`
- On publish + `origin = automation` → close task ClickUp.

## 7. Integrasi

- **ClickUp (API v2):** create task saat draft, update status saat publish.
- **Email:** reuse infra nodemailer existing (yang dipakai OTP/IPRE) → template baru "review draft".

## 8. Konfigurasi / Env

| Env | Contoh / Catatan |
|---|---|
| `AUTOMATION_API_KEY` | secret acak → dipasang di Claude routine |
| `AUTOMATION_AUTHOR_EMAIL` | `creative@mataerdigital.com` (user ini harus sudah ada, punya `full_name` & `slug`) |
| `CLICKUP_TOKEN` | token API ClickUp ❓ |
| `CLICKUP_LIST_ID` | list tujuan task ❓ |
| `CLICKUP_ASSIGNEE_ID` | user ClickUp admin sosmed ❓ |
| `CLICKUP_DONE_STATUS` | nama status "selesai" di list itu (mis. `complete`) ❓ |
| `REVIEW_URL_BASE` | pola URL admin FE, mis. `https://dev.mataerdigital.com/admin/news/edit` ❓ |
| `REVIEW_EMAIL_TO` | `creative@mataerdigital.com` |

## 9. Non-Fungsional (Best Practice)

- API key: constant-time compare + rate-limit; scope `create-draft-only`.
- Sanitasi HTML konten (pakai `sanitizeHtml` existing); validasi category/tag `type=article`.
- Secret semua di env / GitLab CI vars.
- **Reliability MVP:** fire-and-forget + log.
  **v2:** outbox + retry + dashboard run + alert "hari kerja lewat jam 8 tapi draft belum ada".
- **Audit:** `origin=automation` memudahkan filter draft bikinan bot.

## 10. Scope

- **MVP (v1):** poin 1–10 di atas.
- **Nice-to-have (v2):** Opsi B thumbnail (`thumbnail_url` → fetch → S3), outbox/retry, dashboard automation runs, alert kegagalan, tabel `IntegrationApiKey` (hash+scope).
- **Di luar scope:** auto-publish (publish tetap manual oleh admin).