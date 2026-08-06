#!/bin/bash
# Scans the current git diff for hardcoded secrets.
# Usage: git-security-scan.sh [<git-diff-args>]
# Default: scans staged changes (git diff --cached HEAD).
# Exit code 1 if any matches found, 0 if clean.
set -euo pipefail

diff_args="${*:---cached HEAD}"

# Check for staged sensitive config files before scanning content
staged_secret_files=$(git diff --cached --name-only | grep -E '(^|/)(\.env(\.|$)|google-services\.json|GoogleService-Info\.plist)' || true)
if [[ -n "$staged_secret_files" ]]; then
  echo "SECRETS SCAN: sensitive config file(s) staged for commit:"
  echo "$staged_secret_files" | sed 's/^/  /'
  exit 1
fi

# Parse diff into file+line context so output is navigable
current_file=""
current_line=0
found=0

while IFS= read -r line; do
  # Track current file
  if [[ "$line" =~ ^\+\+\+\ b/(.+)$ ]]; then
    current_file="${BASH_REMATCH[1]}"
    continue
  fi
  # Track line numbers from hunk headers: @@ -a,b +c,d @@
  if [[ "$line" =~ ^\@\@\ [^+]*\+([0-9]+) ]]; then
    current_line="${BASH_REMATCH[1]}"
    continue
  fi
  # Count lines in the new file
  if [[ "$line" =~ ^\+ ]]; then
    ((current_line++)) || true
  elif [[ "$line" =~ ^[^-] ]]; then
    ((current_line++)) || true
  fi

  # Only check added lines
  [[ "$line" =~ ^\+ ]] || continue
  [[ "$line" =~ ^\+\+\+ ]] && continue

  content="${line:1}"  # strip leading +

  matched=""

  # 1. Keyword = value patterns
  if echo "$content" | grep -iqE "(password|secret|token|api_key|apikey|private_key|access_key|auth_key)[[:space:]]*[=:][[:space:]]*[\"']?[A-Za-z0-9+/._@!#\$%^&*-]{8,}"; then
    # Suppress known safe patterns
    if ! echo "$content" | grep -iqE '(example|placeholder|your_|<[a-z]|>|xxx|redacted|process\.env\b|os\.environ\b|config\.|getenv\(|parseStringEnv\(|parseNumberEnv\(|headers\.authorization|secretsmanager|secretName|secretArn|secretRef|keyName|keyId|tokenName|\.env\b|:[[:space:]]*[A-Z][A-Za-z]|=[[:space:]]*[a-z][a-z0-9_]*\.)'; then
      matched="keyword-match"
    fi
  fi

  # 2. Known token prefixes
  if [[ -z "$matched" ]] && echo "$content" | grep -qE '(ghp_|ghs_|gho_|AKIA|ASIA|sk_live_|rk_live_|xoxb-|xoxp-|xoxa-|sq0atp-|sq0csp-|AIzaSy|ya29\.|GOCSPX-)[A-Za-z0-9+/._-]{8,}'; then
    matched="token-prefix"
  fi

  # 3. JWT tokens (ey... base64.base64.base64)
  if [[ -z "$matched" ]] && echo "$content" | grep -qE '\bey[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}'; then
    matched="jwt"
  fi

  # 4. Private key blocks
  if [[ -z "$matched" ]] && echo "$content" | grep -qE -e '-----BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----'; then
    matched="private-key"
  fi

  # 5. Credentialed URLs
  if [[ -z "$matched" ]] && echo "$content" | grep -qE 'https?://[^/\s:]+:[^/\s@]{3,}@'; then
    if ! echo "$content" | grep -iqE '(example|placeholder|<|>|xxx|user:password)'; then
      matched="credentialed-url"
    fi
  fi

  if [[ -n "$matched" ]]; then
    echo "  [$matched] $current_file:$current_line: $content"
    found=1
  fi

done < <(git diff $diff_args)

if [[ "$found" -eq 1 ]]; then
  echo "SECRETS SCAN: potential hardcoded credentials found (see above)"
  exit 1
fi

echo "SECRETS SCAN: clean"
exit 0
