

set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 <article.json> [NN]" >&2
  echo "  NN: 2-digit daily sequence number for the Idempotency-Key (default: 01)" >&2
  exit 1
fi

article_file="$1"
seq="${2:-01}"

: "${AUTOMATION_API_KEY:?AUTOMATION_API_KEY env var is required}"
: "${AUTOMATION_API_BASE_URL:?AUTOMATION_API_BASE_URL env var is required}"

if [[ ! -f "$article_file" ]]; then
  echo "Article file not found: $article_file" >&2
  exit 1
fi

if [[ ! "$seq" =~ ^[0-9]{1,2}$ ]]; then
  echo "Invalid sequence number: $seq (expected 1-2 digits, e.g. 01, 02)" >&2
  exit 1
fi
seq=$(printf '%02d' "$((10#$seq))")

wib_date=$(TZ="WIB-7" date +%Y-%m-%d)
idempotency_key="article-${wib_date}-${seq}"
endpoint="${AUTOMATION_API_BASE_URL%/}/api/automations/articles"

# Auto-fill published_at (WIB, ISO 8601) when the payload doesn't set one, so the
# article date is generated at creation time and carried through to publish.
payload_file="$article_file"
if ! grep -q '"published_at"' "$article_file"; then
  published_at=$(TZ="WIB-7" date +%Y-%m-%dT%H:%M:%S+07:00)
  if command -v python3 >/dev/null 2>&1; then
    payload_file=$(mktemp)
    trap 'rm -f "$payload_file"' EXIT
    python3 - "$article_file" "$payload_file" "$published_at" <<'PY'
import json, sys
src, dst, published_at = sys.argv[1:4]
with open(src, encoding="utf-8") as f:
    data = json.load(f)
data["published_at"] = published_at
with open(dst, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False)
PY
    echo "published_at not set in payload; using ${published_at}" >&2
  else
    echo "Warning: published_at not set and python3 unavailable; sending payload without it" >&2
  fi
fi

response=$(curl -sS -w '\n%{http_code}' -X POST "$endpoint" \
  -H "Content-Type: application/json" \
  -H "X-API-Key: ${AUTOMATION_API_KEY}" \
  -H "Idempotency-Key: ${idempotency_key}" \
  --data-binary "@${payload_file}")

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')

echo "$body"

if (( http_code < 200 || http_code >= 300 )); then
  echo "POST failed with HTTP ${http_code} (Idempotency-Key: ${idempotency_key})" >&2
  exit 1
fi
