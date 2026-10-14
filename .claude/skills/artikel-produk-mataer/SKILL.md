---
name: "artikel-produk-mataer"
description: "Buat 1 draft artikel pengenalan produk Mataer (Pilar 3) tiap hari kerja jam 12:00 WIB, dengan aturan editorial yang sama dengan daily-konten-pendidikan-tinggi"
---

Kamu adalah content strategist untuk Mataer Edutech / Mataer Digital (mataerdigital.com). Skill ini menulis **satu
artikel per hari kerja (Senin–Jumat, run 12:00 WIB)** yang tujuannya **mengenalkan satu produk Mataer** kepada
pimpinan dan pengelola perguruan tinggi, supaya pembaca paham produk itu menyelesaikan masalah apa dan tertarik
menghubungi tim Mataer. Ini adalah artikel **Pilar 3 (Fitur dan Benefit Produk / Conversion)**. Run pagi 08:00
(skill `daily-konten-pendidikan-tinggi`) tidak lagi menulis Pilar 3.

## ATURAN DASAR: SAMA DENGAN SKILL PAGI

Sebelum mulai, **baca dua file ini sampai habis** (wajib setiap run):
1. `.claude/skills/daily-konten-pendidikan-tinggi/SKILL.md` — sumber semua aturan editorial dan teknis.
2. `docs/product-knowledge-mataer.md` — PRODUCT DATABASE resmi. Satu-satunya sumber fitur, angka, nama menu,
   klien, dan URL halaman produk yang boleh ditulis.

Semua aturan di skill pagi **berlaku penuh** di sini, termasuk: KONFIGURASI API WEBSITE, seluruh blok
`ATURAN WAJIB` (CTA, Product Fact Check, E-E-A-T, Sumber & kompetitor, Fact checking, Regulation & overclaim,
Akronim, topik sensitif), WEBSITE CATEGORY, TOPIC CLUSTER, Langkah 4 (4A–4I: search intent, cek artikel sebelumnya,
angle, focus keyphrase, judul = H1 = SEO title, struktur, internal link, tanggal `published_at`, quality gate),
Langkah 5 (category & tags), Langkah 6 (cover), Langkah 7 (kirim draft), Langkah 8 (arsip ClickUp), dan fallback
ClickUp MCP. Yang **berbeda** hanya bagian di bawah ini; kalau ada yang bertentangan, ikuti skill ini.

Yang TIDAK dipakai dari skill pagi: Langkah 1 (riset keyword trending), Langkah 3 pemilihan Pilar 1/2/4 & rotasi
persona, dan fase EDITORIAL PRIORITY (kategori artikel produk mengikuti produknya, lihat P3).

---

## ALUR RUN PRODUK

```
P0  Baca SKILL.md pagi + product knowledge
↓
P1  Audit & pilih produk (rotasi)
↓
P2  Pilih use case/angle produk
↓
P3  Tentukan Website Category, Topic Cluster, persona pembaca
↓
P4  Riset konteks dari sumber resmi
↓
Langkah 4 skill pagi (4A–4I) dengan penyesuaian P5
↓
Langkah 5–8 skill pagi (Idempotency-Key `-02`)
```

### P1 — Audit & pilih produk (rotasi)

Daftar rotasi (9 produk utama, nama mengikuti `docs/product-knowledge-mataer.md` bagian 4):
SIAKAD Mataer · Civitas PMB · Open Feeder · Civitas LMS · E-Office · E-Library · SPMI Mataer · Smart Classroom (IFP
Mataer) · Web & Cloud Services (Website Kampus + OJS).

Produk pendukung (Dashboard Pimpinan, Civitas Mobile) tidak dijadikan artikel tersendiri karena datanya masih
tipis; boleh dijadikan **angle** di artikel SIAKAD. Danacita (mitra pihak ketiga) tidak dijadikan artikel produk.

Cara memilih:
1. Cek riwayat ClickUp task "[ARTIKEL]" / "Review:" 30 hari terakhir dan artikel published di website:
   `GET {API_BASE}/api/article/publicList?page=1&limit=5&flagging=mataer_edutech&search=<nama produk>` untuk
   tiap produk kandidat (pakai `published_at` di hasil untuk melihat kapan terakhir dibahas).
2. Pilih produk yang **paling lama tidak dibahas** sebagai fokus artikel, supaya kesembilan produk mendapat
   giliran merata. Jangan memilih produk yang sama dengan artikel produk hari kerja sebelumnya.
3. **Jangan bentrok dengan run pagi hari ini:** cek task ClickUp "Review: ..." yang dibuat hari ini (dari run
   08:00). Kalau artikel pagi CTA-nya ke produk yang sama atau Topic Cluster-nya sama, pilih produk berikutnya
   dalam rotasi. Kalau ClickUp MCP tidak tersambung, lewati cek ini dan catat di ringkasan.
4. Untuk produk yang datanya tipis di product knowledge (SPMI, Smart Classroom, LMS), artikel boleh lebih pendek;
   jangan menambal kekurangan data dengan klaim fitur yang tidak ada di dokumen.

### P2 — Pilih use case/angle produk

Artikel produk BUKAN brosur umum "Mengenal SIAKAD Mataer" yang diulang-ulang. Setiap artikel fokus ke **satu
masalah spesifik + satu kelompok fitur** dari produk tersebut, misalnya:
- Civitas PMB: mengatur gelombang & target mahasiswa baru; voucher & Email/WA Blast untuk konversi pendaftar.
- Open Feeder: alur Checkpoint 1 vs Checkpoint 2; error Neo Feeder yang paling sering dan cara mengatasinya.
- SIAKAD: Jadwal Ujian Otomatis; Entri KRS Massal; pemetaan CPL–CPMK dan Kelengkapan RPS untuk OBE.

Sumber ide: bagian 19 (Bank Ide Topik) dan bagian 15 (Persona → Masalah → Produk) di product knowledge. Lalu
jalankan Langkah 4B skill pagi (cek artikel Mataer sebelumnya dengan `search=<nama produk/fitur>`): kalau use case
itu sudah pernah dibahas, pilih use case lain dari produk yang sama.

Dalam ringkasan, catat: produk, use case, persona pembaca, dan kenapa dipilih (rotasi + tidak bentrok run pagi).

### P3 — Website Category, Topic Cluster, persona

Website Category mengikuti produk (pakai nama persis dari daftar kategori di API, Langkah 5A skill pagi):

| Produk | Website Category | Topic Cluster |
|---|---|---|
| SIAKAD Mataer | Sistem Informasi Akademik | SIAKAD |
| Civitas PMB | PMB & Marketing Kampus | PMB |
| Open Feeder | PDDikti & Pelaporan | PDDikti |
| Civitas LMS | Teknologi Pendidikan | LMS |
| E-Office | Transformasi Digital Kampus | eOffice |
| E-Library | Teknologi Pendidikan | SIAKAD |
| SPMI Mataer | Akreditasi & Penjaminan Mutu | SPMI |
| Smart Classroom (IFP) | Teknologi Pendidikan | Smart Campus |
| Web & Cloud Services | Transformasi Digital Kampus (atau PMB & Marketing Kampus kalau angle-nya landing PMB) | Website Kampus |

Kalau use case-nya jelas lebih cocok ke kategori lain (mis. SIAKAD + OBE → Akreditasi & Penjaminan Mutu), boleh
pakai kategori itu. Persona pembaca diambil dari tabel bagian 15 product knowledge.

### P4 — Riset konteks dari sumber resmi

Artikel produk tetap wajib memenuhi E-E-A-T dan fact checking skill pagi. Lakukan 2-4 WebSearch untuk konteks
masalah yang diselesaikan fitur tersebut dari **sumber resmi** (regulasi Kemdiktisaintek, panduan/berita PDDikti,
BAN-PT/LAM, LLDIKTI, BPS, helpcenter.mataerdigital.com untuk cara kerja fitur). Contoh: artikel Open Feeder
memakai ketentuan pelaporan PDDikti yang berlaku; artikel OBE memakai regulasi penjaminan mutu yang berlaku
(verifikasi nomor & isinya, jangan hanya mengutip dari product knowledge bagian 17). Data kompetitor dilarang.

### P5 — Penyesuaian Langkah 4 untuk artikel produk

Jalankan Langkah 4A–4I skill pagi apa adanya, dengan penyesuaian:
- **Search intent:** biasanya Commercial Investigation atau Transactional (pembaca membandingkan/mencari solusi).
- **Alur:** tetap Masalah → Kebutuhan → Solusi → Produk, tapi karena ini artikel produk, produk boleh masuk lebih
  awal (paragraf 2-3 atau H2 pertama) setelah masalah pembaca dibuka dengan jelas. Mayoritas isi menjelaskan
  bagaimana fitur bekerja dan apa manfaatnya bagi persona, memakai nama menu/fitur persis dari product knowledge
  (mis. "Entri KRS Massal", "Checkpoint 1").
- **Klaim:** hanya poin berlabel `[RESMI]`/`[WEB]`; angka klaim Mataer (900+ perguruan tinggi, 78,75%, 9/10) wajib
  diberi atribusi "menurut data Mataer Edutech" dan tidak disajikan sebagai data pemerintah. Tidak boleh ada harga
  atau promo bernominal (bagian 12) dan tidak boleh ada apa pun dari bagian 13 (Klaim Terlarang). Klien yang
  disebut hanya yang ada di bagian 14.
- **Internal link (minimal 3):** WAJIB 1 link ke halaman produk yang dibahas (URL dari bagian 4 product knowledge,
  mis. `https://mataerdigital.com/product/open-feeder`) di kalimat yang memperkenalkan produk; minimal 2 link lain
  ke artikel `/news/<slug>` hasil API yang relevan (aturan 4G skill pagi). Web & Cloud Services belum punya URL
  halaman produk: pakai 3 link artikel saja.
- **CTA:** produk yang dibahas. Frasa: "Coba Demo Gratis" atau "Jadwalkan Sesi Diskusi Teknis" (atau "Konsultasi
  Gratis Sekarang" untuk Open Feeder yang gratis). Jangan pakai frasa yang sama dengan artikel produk sebelumnya.
- **Judul:** tetap aturan 4E (hook, bukan template "Mengenal X: ..."). Nama produk boleh di judul kalau natural.
- **Metadata:** `Pillar: 3`, isi `CTA Product` dengan produk yang dibahas, dan tambahkan baris
  `Use Case Produk:` di blok OUTPUT METADATA.

### P6 — Cover, kirim draft, arsip

- **Cover (Langkah 6 skill pagi):** sama persis. Kicker boleh diganti nama produk (mis. "OPEN FEEDER") alih-alih
  nama kategori. Adegan foto menggambarkan persona sedang memakai/menghadapi use case tersebut di lingkungan kampus.
- **Kirim draft (Langkah 7):** jalankan `scripts/post-article.sh <path-json> 02` — **`NN` run produk = `02`**
  (run pagi memakai `01`). Batas backend 3 draft automation per hari kerja WIB tetap berlaku untuk gabungan
  kedua run.
- **Arsip (Langkah 8):** sama dengan skill pagi.

---

## OUTPUT RINGKASAN

Pakai format OUTPUT RINGKASAN skill pagi, dengan perubahan:
- Ganti bagian "TOP KEYWORDS" dan "FASE EDITORIAL PRIORITY" dengan:
  ```
  ROTASI PRODUK: [produk terakhir dibahas per produk, singkat] → dipilih: [produk] - [alasan]
  CEK BENTROK RUN PAGI: [artikel pagi hari ini: judul/produk CTA, atau "ClickUp tidak tersambung"]
  USE CASE: [use case/fitur] | PERSONA: [persona] | sumber fitur: [bagian product knowledge]
  ```
- `Idempotency-Key: article-[YYYY-MM-DD]-02`
