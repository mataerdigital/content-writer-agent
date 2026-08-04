

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <article.json>" >&2
  exit 1
fi

article_file="$1"

: "${AUTOMATION_API_KEY:?AUTOMATION_API_KEY env var is required}"
: "${AUTOMATION_API_BASE_URL:?AUTOMATION_API_BASE_URL env var is required}"

if [[ ! -f "$article_file" ]]; then
  echo "Article file not found: $article_file" >&2
  exit 1
fi

wib_date=$(TZ="Asia/Jakarta" date +%Y-%m-%d)
idempotency_key="article-${wib_date}"
endpoint="${AUTOMATION_API_BASE_URL%/}/api/automations/articles"

response=$(curl -sS -w '\n%{http_code}' -X POST "$endpoint" \
  -H "Content-Type: application/json" \
  -H "X-API-Key: ${AUTOMATION_API_KEY}" \
  -H "Idempotency-Key: ${idempotency_key}" \
  --data-binary "@${article_file}")

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')

echo "$body"

if (( http_code < 200 || http_code >= 300 )); then
  echo "POST failed with HTTP ${http_code} (Idempotency-Key: ${idempotency_key})" >&2
  exit 1
fi
