#!/usr/bin/env bash
# Smoke test kontrak Automation API terhadap backend DEV (bukan production).
#
# Usage:
#   scripts/test-dev-api.sh                      # hanya endpoint publik + cek auth
#   AUTOMATION_API_KEY=<key dev> scripts/test-dev-api.sh   # + upload cover + POST draft + idempotency
#
# Env opsional:
#   DEV_API_BASE_URL  default https://api-dev.mataerdigital.com
#   TEST_SEQ          NN Idempotency-Key untuk uji (default 09, supaya tidak bentrok dengan 01/02 run terjadwal)

set -uo pipefail

base="${DEV_API_BASE_URL:-https://api-dev.mataerdigital.com}"
base="${base%/}"
seq="${TEST_SEQ:-09}"
repo_root="$(cd "$(dirname "$0")/.." && pwd)"

if [[ "$base" == *"://api.mataerdigital.com"* ]]; then
  echo "Menolak jalan: $base adalah production. Script ini hanya untuk API dev." >&2
  exit 1
fi

py=$(command -v python3 || command -v python) || { echo "python3 dibutuhkan untuk parse JSON" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

pass=0; fail=0; skip=0
ok()   { echo "  PASS  $*"; pass=$((pass+1)); }
ko()   { echo "  FAIL  $*"; fail=$((fail+1)); }
sk()   { echo "  SKIP  $*"; skip=$((skip+1)); }

# get <url> <outfile> -> prints http code
get() { curl -sS -m 60 -o "$2" -w '%{http_code}' "$1"; }

# jq-lite: run python expression `expr` on JSON file (variable d)
pj() { "$py" -c "import json,sys; d=json.load(open(sys.argv[1],encoding='utf-8')); print($2)" "$1" 2>/dev/null; }

echo "== Target: $base"

echo "== 1. Kategori (publik)"
code=$(get "$base/api/category/listPublic?type=article&limit=100" "$tmp/cat.json")
if [[ "$code" == 200 ]]; then
  ok "GET category/listPublic -> 200"
  missing=$(pj "$tmp/cat.json" "', '.join(n for n in ['Regulasi Pendidikan Tinggi','Sistem Informasi Akademik','PDDikti & Pelaporan','Akreditasi & Penjaminan Mutu','PMB & Marketing Kampus','Transformasi Digital Kampus','Teknologi Pendidikan','Spotlight Kampus','Insight Pendidikan Tinggi'] if n.lower() not in [c['name'].lower() for c in d['data']])")
  if [[ -z "$missing" ]]; then ok "9 Website Category skill ada di DB (case-insensitive)"; else ko "Website Category tidak ada di DB: $missing"; fi
  category_id=$(pj "$tmp/cat.json" "next(c['id'] for c in d['data'] if c['name'].lower()=='teknologi pendidikan')")
else
  ko "GET category/listPublic -> $code"
fi

echo "== 2. Tags (publik)"
code=$(get "$base/api/tags/listPublic?type=article&limit=100" "$tmp/tags.json")
if [[ "$code" == 200 ]]; then
  # data bisa berupa list atau objek paginasi {data: [...], total, ...}
  tags_expr="(d['data'] if isinstance(d['data'],list) else d['data'].get('data',[]))"
  ok "GET tags/listPublic -> 200 ($(pj "$tmp/tags.json" "len($tags_expr)") tag)"
  tag_id=$(pj "$tmp/tags.json" "next((t['id'] for t in $tags_expr if t['name'].lower() in ('pddikti','siakad','pmb')), '')")
else
  ko "GET tags/listPublic -> $code"
fi

echo "== 3. Artikel published untuk internal link (publik)"
code=$(get "$base/api/article/publicList?page=1&limit=5&flagging=mataer_edutech&search=PMB" "$tmp/list.json")
if [[ "$code" == 200 ]]; then
  ok "GET article/publicList?search=PMB -> 200"
  n=$(pj "$tmp/list.json" "len(d['data'] if isinstance(d['data'],list) else d['data'].get('data',[]))")
  if [[ "${n:-0}" -ge 3 ]]; then ok "minimal 3 hasil untuk internal link ($n)"; else ko "hasil search < 3 ($n)"; fi
  fields=$(pj "$tmp/list.json" "all(k in a for a in (d['data'] if isinstance(d['data'],list) else d['data'].get('data',[])) for k in ('title','slug','published_at'))")
  [[ "$fields" == True ]] && ok "tiap hasil punya title, slug, published_at" || ko "field title/slug/published_at tidak lengkap"
  links=$(pj "$tmp/list.json" "[a['slug'] for a in (d['data'] if isinstance(d['data'],list) else d['data'].get('data',[]))][:3]")
else
  ko "GET article/publicList -> $code"
fi

echo "== 4. Auth endpoint automation"
code=$(curl -sS -m 60 -o "$tmp/noauth.json" -w '%{http_code}' -X POST "$base/api/automations/articles" \
  -H 'Content-Type: application/json' -d '{}')
[[ "$code" == 401 || "$code" == 403 ]] && ok "POST tanpa X-API-Key ditolak ($code)" || ko "POST tanpa X-API-Key -> $code (harusnya 401/403)"

if [[ -z "${AUTOMATION_API_KEY:-}" ]]; then
  sk "upload cover, POST draft, published_at, idempotency (set AUTOMATION_API_KEY dev untuk menjalankan)"
  echo "== Hasil: $pass pass, $fail fail, $skip skip"
  exit $(( fail > 0 ))
fi

echo "== 5. Upload cover"
# relative path: curl.exe native di Windows tidak paham path MSYS (/d/...)
code=$(cd "$repo_root/.claude/skills/daily-konten-pendidikan-tinggi/assets" && \
  curl -sS -m 120 -o "$tmp/file.json" -w '%{http_code}' -X POST "$base/api/automations/files" \
  -H "X-API-Key: ${AUTOMATION_API_KEY}" -F "file=@cover-template.png;type=image/png")
if [[ "$code" == 201 || "$code" == 200 ]]; then
  thumbnail_id=$(pj "$tmp/file.json" "d['data']['id']")
  ok "POST automations/files -> $code (thumbnail_id=$thumbnail_id)"
else
  ko "POST automations/files -> $code: $(head -c 300 "$tmp/file.json" 2>/dev/null)"
fi

echo "== 6. POST draft (via scripts/post-article.sh)"
published_at=$(TZ="WIB-7" date +%Y-%m-%dT%H:%M:%S+07:00)
"$py" - "$tmp/article.json" "$published_at" "${thumbnail_id:-}" "${category_id:-}" "${tag_id:-}" "${links:-[]}" <<'PY'
import json, sys, ast
out, published_at, thumb, cat, tag, links = sys.argv[1:7]
slugs = ast.literal_eval(links) if links.startswith('[') else []
link_html = "".join(f'<li><a href="https://mataerdigital.com/news/{s}">{s}</a></li>' for s in slugs)
title = "[TEST] Uji Kontrak Automation API Dev"
body = {
    "title": title,
    "seo_title": title,
    "content": "<p>Draft uji otomatis dari scripts/test-dev-api.sh. Abaikan / hapus.</p>"
               "<h2>Internal link</h2><ul>" + link_html + "</ul>",
    "excerpt": "Draft uji otomatis kontrak Automation API di environment dev.",
    "meta_description": "Draft uji otomatis untuk memastikan kontrak Automation API dev menerima title, seo_title, published_at, thumbnail, kategori, dan tag dengan benar.",
    "focus_keyphrase": "uji API",
    "published_at": published_at,
    "cover_brief": "TEST — draft uji otomatis, tidak perlu cover.",
}
if thumb: body["thumbnail_id"] = thumb
if cat: body["category_ids"] = [cat]
if tag: body["tag_ids"] = [tag]
json.dump(body, open(out, "w", encoding="utf-8"), ensure_ascii=False)
PY

AUTOMATION_API_BASE_URL="$base" bash "$repo_root/scripts/post-article.sh" "$tmp/article.json" "$seq" > "$tmp/post.json" 2> "$tmp/post.err"
rc=$?
if [[ $rc -eq 0 ]]; then
  ok "POST automations/articles sukses (Idempotency-Key article-$(TZ="WIB-7" date +%Y-%m-%d)-$seq)"
  echo "        response: $(head -c 600 "$tmp/post.json")"
  dup=$(pj "$tmp/post.json" "d['data'].get('duplicated')")
  [[ "$dup" == True ]] && echo "        (catatan: key ini sudah dipakai hari ini -> duplicated:true)"
  has_pa=$(pj "$tmp/post.json" "'published_at' in d['data']")
  if [[ "$has_pa" == True ]]; then
    stored=$(pj "$tmp/post.json" "d['data']['published_at']")
    ok "response memuat published_at=$stored (dikirim $published_at)"
  else
    sk "response tidak memuat published_at — cek manual di admin dev apakah tanggal tersimpan"
  fi
else
  ko "POST automations/articles gagal: $(cat "$tmp/post.err") $(head -c 600 "$tmp/post.json")"
fi

echo "== 7. Idempotency (POST ulang key yang sama)"
if [[ $rc -eq 0 ]]; then
  AUTOMATION_API_BASE_URL="$base" bash "$repo_root/scripts/post-article.sh" "$tmp/article.json" "$seq" > "$tmp/post2.json" 2>/dev/null
  dup=$(pj "$tmp/post2.json" "d['data'].get('duplicated')")
  same=$(pj "$tmp/post2.json" "d['data']['id']")
  first=$(pj "$tmp/post.json" "d['data']['id']")
  [[ "$dup" == True && "$same" == "$first" ]] && ok "POST ulang -> duplicated:true, id sama" || ko "POST ulang tidak idempotent: $(head -c 300 "$tmp/post2.json")"
else
  sk "idempotency (POST pertama gagal)"
fi

echo "== Hasil: $pass pass, $fail fail, $skip skip"
exit $(( fail > 0 ))
