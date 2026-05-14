#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
GH="$ROOT/.github"
META="$SCRIPT_DIR/readme-meta.json"

warn_count=0
warn() { echo "WARN: $*" >&2; ((warn_count++)); }

# ---------------------------------------------------------------------------
# Frontmatter parser — extracts a single-line key from YAML front matter
# ---------------------------------------------------------------------------
get_fm() {
  local file="$1" key="$2"
  awk -v key="$key" '
    /^---[[:space:]]*$/ { fm++; next }
    fm == 1 {
      pat = "^" key ":"
      if ($0 ~ pat) {
        val = $0
        sub("^" key ":[[:space:]]*", "", val)
        gsub(/^'\''|'\''$/, "", val)
        gsub(/^"|"$/, "", val)
        print val
        exit
      }
    }
    fm >= 2 { exit }
  ' "$file"
}

# ---------------------------------------------------------------------------
# Meta helpers (jq)
# ---------------------------------------------------------------------------
meta_val()  { jq -r "$1 // empty" "$META"; }
meta_arr()  { jq -r "$1[]"        "$META"; }

# ---------------------------------------------------------------------------
# Section replacer — swaps content between <!-- BEGIN:TAG --> / <!-- END:TAG -->
# ---------------------------------------------------------------------------
replace_section() {
  local file="$1" tag="$2" content="$3"
  local begin="<!-- BEGIN:${tag} -->"
  local end="<!-- END:${tag} -->"

  if ! grep -qF "$begin" "$file"; then
    warn "Marker $begin not found in $file"
    return
  fi

  local tmpbody
  tmpbody=$(mktemp)
  printf '%s\n' "$content" > "$tmpbody"

  awk -v begin="$begin" -v end="$end" -v bodyfile="$tmpbody" '
    $0 ~ begin { print; while ((getline line < bodyfile) > 0) print line; skip=1; next }
    $0 ~ end   { skip=0 }
    !skip       { print }
  ' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"

  rm -f "$tmpbody"
}

# ===================================================================
#  AGENTS TABLE
# ===================================================================
gen_agents_table() {
  local lang="$1" buf=""
  if [[ "$lang" == "en" ]]; then
    buf+="|   | Agent | Model | Description |"$'\n'
    buf+="|:-:|-------|-------|-------------|"$'\n'
  else
    buf+="|   | Agent | 模型 | 說明 |"$'\n'
    buf+="|:-:|-------|------|------|"$'\n'
  fi

  while IFS= read -r name; do
    local file="$GH/agents/${name}.agent.md"
    if [[ ! -f "$file" ]]; then
      warn "Agent '$name' listed in meta but file missing: $file"
      continue
    fi
    local model icon summary
    model=$(get_fm "$file" "model")
    icon=$(meta_val ".agents[\"$name\"].icon")
    if [[ "$lang" == "en" ]]; then
      summary=$(meta_val ".agents[\"$name\"].summary")
    else
      summary=$(meta_val ".agents[\"$name\"].summary_zh")
    fi
    buf+="| ${icon} | \`@${name}\` | ${model} | ${summary} |"$'\n'
  done < <(meta_arr '.order.agents')

  # Check for agents on disk but missing from meta
  for f in "$GH"/agents/*.agent.md; do
    [[ -f "$f" ]] || continue
    local aname
    aname=$(basename "$f" .agent.md)
    if ! jq -e ".agents[\"$aname\"]" "$META" > /dev/null 2>&1; then
      warn "Agent file '$aname' exists but has no entry in readme-meta.json"
    fi
  done

  printf '%s' "$buf"
}

# ===================================================================
#  SKILLS TABLE
# ===================================================================
gen_skills_table() {
  local lang="$1" buf=""
  if [[ "$lang" == "en" ]]; then
    buf+="|   | Skill | Trigger | Description |"$'\n'
    buf+="|:-:|-------|---------|-------------|"$'\n'
  else
    buf+="|   | Skill | 觸發方式 | 說明 |"$'\n'
    buf+="|:-:|-------|----------|------|"$'\n'
  fi

  while IFS= read -r name; do
    local dir="$GH/skills/${name}/SKILL.md"
    if [[ ! -f "$dir" ]]; then
      warn "Skill '$name' listed in meta but file missing: $dir"
      continue
    fi
    local icon trigger_raw trigger_display summary
    icon=$(meta_val ".skills[\"$name\"].icon")
    trigger_raw=$(meta_val ".skills[\"$name\"].trigger")

    if [[ "$lang" == "en" ]]; then
      summary=$(meta_val ".skills[\"$name\"].summary")
      if [[ "$trigger_raw" == "manual" ]]; then
        trigger_display="**Manual only**"
      else
        trigger_display="Auto + Manual"
      fi
    else
      summary=$(meta_val ".skills[\"$name\"].summary_zh")
      if [[ "$trigger_raw" == "manual" ]]; then
        trigger_display="**僅手動**"
      else
        trigger_display="自動 + 手動"
      fi
    fi
    buf+="| ${icon} | \`${name}\` | ${trigger_display} | ${summary} |"$'\n'
  done < <(meta_arr '.order.skills')

  for d in "$GH"/skills/*/SKILL.md; do
    [[ -f "$d" ]] || continue
    local sname
    sname=$(basename "$(dirname "$d")")
    if ! jq -e ".skills[\"$sname\"]" "$META" > /dev/null 2>&1; then
      warn "Skill '$sname' exists but has no entry in readme-meta.json"
    fi
  done

  printf '%s' "$buf"
}

# ===================================================================
#  INSTRUCTIONS TABLE
# ===================================================================
gen_instructions_table() {
  local lang="$1" buf=""
  if [[ "$lang" == "en" ]]; then
    buf+="| File | applyTo | Description |"$'\n'
    buf+="|------|---------|-------------|"$'\n'
  else
    buf+="| 檔案 | applyTo | 說明 |"$'\n'
    buf+="|------|---------|------|"$'\n'
  fi

  while IFS= read -r name; do
    local file="$GH/instructions/${name}.instructions.md"
    if [[ ! -f "$file" ]]; then
      warn "Instruction '$name' listed in meta but file missing: $file"
      continue
    fi
    local apply_to desc
    apply_to=$(get_fm "$file" "applyTo")
    if [[ "$lang" == "en" ]]; then
      desc=$(get_fm "$file" "description")
    else
      desc=$(meta_val ".instructions[\"$name\"].summary_zh")
    fi
    buf+="| \`${name}\` | \`${apply_to}\` | ${desc} |"$'\n'
  done < <(meta_arr '.order.instructions')

  for f in "$GH"/instructions/*.instructions.md; do
    [[ -f "$f" ]] || continue
    local iname
    iname=$(basename "$f" .instructions.md)
    if ! jq -e ".instructions[\"$iname\"]" "$META" > /dev/null 2>&1; then
      warn "Instruction '$iname' exists but has no entry in readme-meta.json"
    fi
  done

  printf '%s' "$buf"
}

# ===================================================================
#  PROMPTS TABLE
# ===================================================================
gen_prompts_table() {
  local lang="$1" buf=""
  if [[ "$lang" == "en" ]]; then
    buf+="| Prompt | Paired skill | Purpose |"$'\n'
    buf+="|--------|-------------|---------|"$'\n'
  else
    buf+="| Prompt | 配對 skill | 用途 |"$'\n'
    buf+="|--------|-----------|------|"$'\n'
  fi

  while IFS= read -r name; do
    local file="$GH/prompts/${name}.prompt.md"
    if [[ ! -f "$file" ]]; then
      warn "Prompt '$name' listed in meta but file missing: $file"
      continue
    fi
    local paired summary
    paired=$(meta_val ".prompts[\"$name\"].paired_skill")
    if [[ "$lang" == "en" ]]; then
      summary=$(meta_val ".prompts[\"$name\"].summary")
    else
      summary=$(meta_val ".prompts[\"$name\"].summary_zh")
    fi
    buf+="| \`${name}\` | \`${paired}\` | ${summary} |"$'\n'
  done < <(meta_arr '.order.prompts')

  for f in "$GH"/prompts/*.prompt.md; do
    [[ -f "$f" ]] || continue
    local pname
    pname=$(basename "$f" .prompt.md)
    if ! jq -e ".prompts[\"$pname\"]" "$META" > /dev/null 2>&1; then
      warn "Prompt '$pname' exists but has no entry in readme-meta.json"
    fi
  done

  printf '%s' "$buf"
}

# ===================================================================
#  DIRECTORY TREE
# ===================================================================
gen_directory_tree() {
  local lang="$1" buf=""
  local lbl_key="en"
  [[ "$lang" == "zh" ]] && lbl_key="zh"

  label() { meta_val ".directory_labels[\"$1\"].$lbl_key"; }

  buf+='```'$'\n'
  buf+="~/.github/"$'\n'

  # copilot-instructions.md
  buf+="├── copilot-instructions.md                ← $(label 'copilot-instructions.md')"$'\n'
  buf+="│"$'\n'

  # instructions/
  buf+="├── instructions/                          ← $(label 'instructions/')"$'\n'
  local instr_files=()
  while IFS= read -r name; do
    instr_files+=("$name")
  done < <(meta_arr '.order.instructions')
  for ((i=0; i<${#instr_files[@]}; i++)); do
    if ((i == ${#instr_files[@]} - 1)); then
      buf+="│   └── ${instr_files[$i]}"$'\n'
    else
      buf+="│   ├── ${instr_files[$i]}"$'\n'
    fi
  done
  buf+="│"$'\n'

  # agents/
  buf+="├── agents/                                ← $(label 'agents/')"$'\n'
  local agent_names=()
  while IFS= read -r name; do
    agent_names+=("$name")
  done < <(meta_arr '.order.agents')
  for ((i=0; i<${#agent_names[@]}; i++)); do
    local aname="${agent_names[$i]}"
    local afile="$GH/agents/${aname}.agent.md"
    local model_str=""
    if [[ -f "$afile" ]]; then
      model_str=$(get_fm "$afile" "model")
    fi
    local padding=""
    local name_len=${#aname}
    local pad_count=$((21 - name_len))
    ((pad_count < 1)) && pad_count=1
    padding=$(printf '%*s' "$pad_count" '')

    local prefix="├──"
    ((i == ${#agent_names[@]} - 1)) && prefix="└──"
    buf+="│   ${prefix} ${aname}${padding}(${model_str})"$'\n'
  done
  buf+="│"$'\n'

  # hooks/
  buf+="├── hooks/                                 ← $(label 'hooks/')"$'\n'
  # Scan hooks directory dynamically
  if [[ -d "$GH/hooks" ]]; then
    local hook_entries=()
    while IFS= read -r entry; do
      hook_entries+=("$entry")
    done < <(cd "$GH/hooks" && find . -not -path '.' -not -name '.DS_Store' | sed 's|^\./||' | sort)

    local top_files=()
    for entry in "${hook_entries[@]}"; do
      if [[ "$entry" != */* ]] && [[ -f "$GH/hooks/$entry" ]]; then
        top_files+=("$entry")
      fi
    done
    # Detect subdirectories
    local has_scripts=false
    [[ -d "$GH/hooks/scripts" ]] && has_scripts=true

    for ((i=0; i<${#top_files[@]}; i++)); do
      local f="${top_files[$i]}"
      if [[ "$has_scripts" == "false" ]] && ((i == ${#top_files[@]} - 1)); then
        buf+="│   └── ${f}"$'\n'
      else
        buf+="│   ├── ${f}"$'\n'
      fi
    done

    if [[ "$has_scripts" == "true" ]]; then
      buf+="│   └── scripts/"$'\n'
      local script_files=()
      while IFS= read -r sf; do
        script_files+=("$(basename "$sf")")
      done < <(find "$GH/hooks/scripts" -type f -not -name '.DS_Store' | sort)
      for ((i=0; i<${#script_files[@]}; i++)); do
        local prefix="├──"
        ((i == ${#script_files[@]} - 1)) && prefix="└──"
        buf+="│       ${prefix} ${script_files[$i]}"$'\n'
      done
    fi
  fi
  buf+="│"$'\n'

  # prompts/
  buf+="├── prompts/                               ← $(label 'prompts/')"$'\n'
  local prompt_names=()
  while IFS= read -r name; do
    prompt_names+=("$name")
  done < <(meta_arr '.order.prompts')
  for ((i=0; i<${#prompt_names[@]}; i++)); do
    local prefix="├──"
    ((i == ${#prompt_names[@]} - 1)) && prefix="└──"
    buf+="│   ${prefix} ${prompt_names[$i]}"$'\n'
  done
  buf+="│"$'\n'

  # skills/
  buf+="└── skills/                                ← $(label 'skills/')"$'\n'
  local skill_names=()
  while IFS= read -r name; do
    skill_names+=("$name")
  done < <(meta_arr '.order.skills')
  for ((i=0; i<${#skill_names[@]}; i++)); do
    local prefix="├──"
    ((i == ${#skill_names[@]} - 1)) && prefix="└──"
    buf+="    ${prefix} ${skill_names[$i]}/"$'\n'
  done

  buf+='```'

  printf '%s' "$buf"
}

# ===================================================================
#  MAIN
# ===================================================================

if [[ ! -f "$META" ]]; then
  echo "ERROR: readme-meta.json not found at $META" >&2
  exit 1
fi

if ! command -v jq &> /dev/null; then
  echo "ERROR: jq is required. Install via: brew install jq" >&2
  exit 1
fi

echo "Syncing README tables from frontmatter + readme-meta.json ..."

for readme in "$ROOT/README.md" "$ROOT/README.zh-TW.md"; do
  [[ -f "$readme" ]] || continue
  lang="en"
  [[ "$readme" == *zh-TW* ]] && lang="zh"
  echo "  → $(basename "$readme") ($lang)"

  replace_section "$readme" "AGENTS_TABLE"       "$(gen_agents_table "$lang")"
  replace_section "$readme" "SKILLS_TABLE"       "$(gen_skills_table "$lang")"
  replace_section "$readme" "INSTRUCTIONS_TABLE" "$(gen_instructions_table "$lang")"
  replace_section "$readme" "PROMPTS_TABLE"      "$(gen_prompts_table "$lang")"
  replace_section "$readme" "DIRECTORY_TREE"     "$(gen_directory_tree "$lang")"
done

if ((warn_count > 0)); then
  echo ""
  echo "Completed with $warn_count warning(s). Check above for details."
  exit 1
else
  echo "Done. All tables and directory tree updated."
fi
