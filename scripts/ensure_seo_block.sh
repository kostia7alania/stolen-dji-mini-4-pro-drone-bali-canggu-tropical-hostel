#!/usr/bin/env bash
set -euo pipefail

FILE="${1:-README.md}"

# Required env (provided by workflow)
: "${DRONE_SN:?Missing DRONE_SN}"
: "${REMOTE_SN:?Missing REMOTE_SN}"
: "${BAT1_SN:?Missing BAT1_SN}"
: "${BAT2_SN:?Missing BAT2_SN}"
: "${BAT3_SN:?Missing BAT3_SN}"
: "${HUB_SN:?Missing HUB_SN}"

if [ ! -f "$FILE" ]; then
  echo "File not found: $FILE"
  exit 0
fi

# --- Helpers ---
has_block() {
  grep -q "## 🔑 Serial Numbers" "$FILE" || grep -q "## Серийные номера" "$FILE" || grep -q "## Nomor Seri" "$FILE"
}

# Canonical SEO block (multilingual, compact). We regenerate it every run.
read -r -d '' SEO_BLOCK <<'EOF'
<!-- seo:begin -->
## 🔑 Serial Numbers (SN) / Серийные номера / Nomor Seri

**DJI Mini 4 Pro Combo**  
- Drone SN: __DRONE_SN__
- Remote Controller SN: __REMOTE_SN__
- Battery 1 SN: __BAT1_SN__
- Battery 2 SN: __BAT2_SN__
- Battery 3 SN: __BAT3_SN__
- Battery Charging Hub SN: __HUB_SN__

## 🔎 SEO Keywords

stolen dji mini 4 pro combo bali, stolen drone bali canggu hostel, canggu tropical hostel theft, dji mini 4 pro serial __DRONE_SN__, drone hilang bali, украли дрон бали чангу, controller __REMOTE_SN__, battery __BAT1_SN__ __BAT2_SN__ __BAT3_SN__, charging hub __HUB_SN__, bali police report, hostel theft, tourist safety indonesia
<!-- seo:end -->
EOF

# Replace placeholders with actual serials
SEO_BLOCK="${SEO_BLOCK//__DRONE_SN__/$DRONE_SN}"
SEO_BLOCK="${SEO_BLOCK//__REMOTE_SN__/$REMOTE_SN}"
SEO_BLOCK="${SEO_BLOCK//__BAT1_SN__/$BAT1_SN}"
SEO_BLOCK="${SEO_BLOCK//__BAT2_SN__/$BAT2_SN}"
SEO_BLOCK="${SEO_BLOCK//__BAT3_SN__/$BAT3_SN}"
SEO_BLOCK="${SEO_BLOCK//__HUB_SN__/$HUB_SN}"

# If block exists, replace from <!-- seo:begin --> to <!-- seo:end -->
if grep -q "<!-- seo:begin -->" "$FILE"; then
  awk -v repl="$SEO_BLOCK" '
    BEGIN{inblk=0}
    /<!-- seo:begin -->/ {print repl; inblk=1; next}
    /<!-- seo:end -->/ {inblk=0; next}
    { if (!inblk) print }
  ' "$FILE" > "${FILE}.tmp" && mv "${FILE}.tmp" "$FILE"
else
  # Append block near the top (after first H1/H2 if they exist), else at EOF
  if grep -qE '^# ' "$FILE"; then
    # Insert after first H1
    awk -v repl="$SEO_BLOCK" '
      BEGIN{done=0}
      {
        print
        if (!done && $0 ~ /^# /) { getline; print; print repl; done=1; }
      }
    ' "$FILE" > "${FILE}.tmp" || true
    # If that failed (awk getline nuance), fallback to append
    if [ ! -s "${FILE}.tmp" ]; then
      cat "$FILE" > "${FILE}.tmp"
      printf "\n%s\n" "$SEO_BLOCK" >> "${FILE}.tmp"
    fi
    mv "${FILE}.tmp" "$FILE"
  else
    printf "\n%s\n" "$SEO_BLOCK" >> "$FILE"
  fi
fi

# Normalize trailing newline
printf "\n" >> "$FILE"
