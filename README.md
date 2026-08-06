# content-writer-agent

Automation harian yang membuat 1 draft artikel SEO (riset → tulis → cover → kirim ke website Mataer Digital)
setiap hari kerja jam 08:00 WIB, lalu mengarsipkannya ke ClickUp. Admin sosmed tinggal review dan publish.

## Struktur repo

```
.claude/skills/daily-konten-pendidikan-tinggi/
  SKILL.md              # "otak" automation: framework konten, rotasi, aturan, dan langkah cover
  assets/cover-template.png  # aset brand baku (logo, tagline, dekorasi, pill URL) untuk cover artikel
docs/
  scheduled-routine.md  # cara kerja jadwal harian + cara bikin/ubah Trigger
  automation-article-spec.md  # kontrak API antara automation ini dan backend website
scripts/
  post-article.sh       # kirim draft artikel ke backend (dipanggil di akhir tiap run)
```

## Cara kerja automation (ringkas)

1. Trigger terjadwal (Senin–Jumat, 08:00 WIB) menjalankan skill `daily-konten-pendidikan-tinggi`.
2. Skill riset keyword trending, audit riwayat ClickUp, tentukan pilar/kategori/persona/produk, lalu menulis
   artikel lengkap sesuai aturan di `SKILL.md`.
3. Skill generate cover artikel (foto via AI Gateway + kompositing lokal dengan `assets/cover-template.png`).
4. Skill menjalankan `scripts/post-article.sh` untuk POST draft ke backend website.
5. Backend otomatis membuat task ClickUp untuk admin sosmed + kirim email; skill mengarsipkan draft lengkap
   ke ClickUp Doc.
6. Admin sosmed review draft di website, lalu publish manual. Automation ini **tidak pernah publish sendiri**.

## Env var yang wajib ada di environment yang menjalankan automation

| Env | Untuk apa |
|---|---|
| `AUTOMATION_API_KEY` | Auth ke endpoint `POST /api/automations/*` di backend website |
| `AUTOMATION_API_BASE_URL` | Base URL backend, mis. `https://api-dev.mataerdigital.com` |
| `AI_GATEWAY_API_KEY` | Auth ke Vercel AI Gateway untuk generate foto cover |

Tanpa `AI_GATEWAY_API_KEY`, artikel tetap terkirim tapi tanpa cover (lihat bagian Fallback di `SKILL.md`
Langkah 6). Tanpa dua env pertama, `scripts/post-article.sh` langsung gagal dengan pesan jelas.

---

## Kalau suatu saat mau mengubah sesuatu

Automation ini tidak punya "kode" yang dijalankan seperti aplikasi biasa — yang membaca `SKILL.md` dan file
di `docs/` setiap kali jalan adalah Claude sendiri (lewat Trigger). Jadi cara mengubah perilakunya adalah
**mengedit dokumen yang relevan**, commit ke `main`, dan Trigger otomatis memakai versi terbaru di run
berikutnya (tidak perlu "deploy" apa pun).

### 1. Ubah jam / hari jadwal posting

**Bukan di file** — jadwal (cron) tersimpan di **Trigger** milik Claude Code on the web, bukan di repo ini.
Ada dua cara ubahnya:

- **Lewat percakapan dengan Claude**: minta "ubah jadwal Trigger content-writer-agent jadi jam X" — Claude bisa
  langsung memanggil `update_trigger` dengan cron baru. Perlu tahu `trigger_id`-nya (bisa dicari lewat
  `list_triggers` kalau lupa).
- **Lewat dashboard Claude Code on the web**: buka repo ini → tab Triggers → edit cron expression.

Cron pakai **UTC**, bukan WIB (WIB = UTC+7). Jadwal saat ini `0 1 * * 1-5` = 08:00 WIB Senin–Jumat.
Contoh: mau jadi jam 10:00 WIB → `0 3 * * 1-5`. Mau nambah Sabtu → `0 1 * * 1-6`.

Dokumentasi & prompt Trigger yang harus dipakai ada di **`docs/scheduled-routine.md`** — kalau ubah jadwal,
tidak perlu ubah file ini kecuali kamu juga mengubah *isi* prompt-nya (lihat poin di bawah).

### 2. Ubah rasio pilar / rotasi kategori / rotasi persona / rotasi produk

Edit **`.claude/skills/daily-konten-pendidikan-tinggi/SKILL.md`**, bagian:

| Yang mau diubah | Bagian di SKILL.md |
|---|---|
| Rasio 4 pilar konten (saat ini 30/30/20/20) | `## FRAMEWORK 4 PILAR KONTEN` |
| Prioritas kategori website (fase-fase) | `## EDITORIAL PRIORITY` |
| Urutan rotasi persona Pilar 4 | `## FRAMEWORK 4 PILAR KONTEN` → "Rotasi persona (wajib)" |
| Urutan rotasi produk Pilar 3 | `## FRAMEWORK 4 PILAR KONTEN` → "Rotasi produk Pilar 3" |
| Daftar Website Category / Topic Cluster | `## WEBSITE CATEGORY` / `## TOPIC CLUSTER` |
| Batas jumlah draft per hari | dikontrol backend, bukan di sini — lihat catatan di bagian bawah `SKILL.md` |

Tidak perlu ubah apa pun di `docs/` atau di Trigger untuk perubahan jenis ini — begitu di-commit ke `main`,
run berikutnya otomatis pakai aturan baru.

### 3. Tambah skill baru (mis. automation lain di luar artikel harian)

1. Buat folder baru: `.claude/skills/<nama-skill-baru>/SKILL.md`, ikuti format frontmatter yang sama
   (`name`, `description`) seperti `daily-konten-pendidikan-tinggi/SKILL.md`.
2. Kalau skill baru itu perlu jalan terjadwal juga, buat **Trigger baru** yang terpisah (jangan digabung ke
   Trigger yang sudah ada) dengan prompt yang menyebut nama skill barunya secara eksplisit — lihat contoh
   format prompt di `docs/scheduled-routine.md` bagian "Prompt untuk trigger".
3. Kalau skill baru itu perlu dijalankan **sebagai bagian dari** alur artikel harian yang sudah ada (bukan
   terpisah), tambahkan langkahnya ke `SKILL.md` yang sudah ada dan sebutkan di prompt Trigger yang sama
   (`docs/scheduled-routine.md`) supaya tidak terlewat.

### 4. Ubah desain / elemen brand di cover artikel

- Elemen baku (logo, tagline, dekorasi, pill URL): ganti file `.claude/skills/daily-konten-pendidikan-tinggi/assets/cover-template.png`
  dengan PNG baru berukuran sama (1920x1080, transparan di luar elemen brand).
- Posisi/warna teks judul, ukuran font, prompt foto AI: edit `SKILL.md` Langkah 6.

### 5. Ubah endpoint / kontrak API backend

Edit `docs/automation-article-spec.md` (dokumentasi kontrak) **dan** `SKILL.md` bagian
`## KONFIGURASI API WEBSITE` (yang benar-benar dibaca & dieksekusi saat run) supaya keduanya tetap sinkron —
`automation-article-spec.md` adalah dokumentasi acuan, `SKILL.md` adalah instruksi yang benar-benar dijalankan.

---

## Supaya automation tetap jalan setelah kamu ubah sesuatu

- **Selalu commit ke `main`** (lewat PR) — Trigger menjalankan skill dari branch yang di-set di konfigurasi
  Trigger (biasanya `main`), jadi perubahan di branch lain tidak akan otomatis dipakai run terjadwal.
- **Jangan ganti nama file/folder skill** (`daily-konten-pendidikan-tinggi`) kecuali kamu juga update nama itu
  di prompt Trigger — prompt Trigger secara eksplisit menyebut path skill ini.
- **Tes manual dulu sebelum mengandalkan jadwal**: jalankan skill langsung lewat chat ("jalankan skill
  daily-konten-pendidikan-tinggi") setelah perubahan besar (ganti pilar, ganti kontrak API, ganti cover),
  supaya kalau ada yang salah, ketahuan sebelum jadwal jalan sendiri jam 8 pagi. Kalau perlu submit ulang
  di hari yang sama untuk tes, pakai `scripts/post-article.sh <file.json> <NN>` (naikkan `NN` tiap percobaan,
  mis. `02`, `03` — backend membatasi maksimal 3 draft automation per hari kerja WIB, lihat `SKILL.md`).
- **Jangan hapus/ubah env var** (`AUTOMATION_API_KEY`, `AUTOMATION_API_BASE_URL`, `AI_GATEWAY_API_KEY`) di
  environment Trigger tanpa mengganti nilainya dengan yang baru — automation akan gagal total tanpa ini.
- Setelah ubah jadwal/skill, cek `list_triggers` (atau dashboard) untuk pastikan Trigger masih `enabled` dan
  `next_run_at` sesuai ekspektasi.
