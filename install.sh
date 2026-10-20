#!/bin/bash
set -euo pipefail
project_dir="$(cd -- "$(dirname -- "$0")" && pwd -P)"
config_dir="$HOME/Library/Application Support/com.mitchellh.ghostty"
mkdir -p "$config_dir"
generated_config="$config_dir/matrix-power.generated"
temporary_config="$generated_config.tmp"
while IFS= read -r line || [[ -n $line ]]; do
  printf '%s\n' "${line//@PROJECT_DIR@/$project_dir}"
done < "$project_dir/config" > "$temporary_config"
mv "$temporary_config" "$generated_config"
target="$config_dir/config.ghostty"
if [[ ! -f "$target" && -f "$config_dir/config" ]]; then
  target="$config_dir/config"
fi
include="config-file = $generated_config"
legacy_include="config-file = $project_dir/config"
if [[ -f "$target" ]] && /usr/bin/grep -Fqx "$include" "$target" && ! /usr/bin/grep -Fqx "$legacy_include" "$target"; then
  printf 'Matrix Power is already configured. Open a new Ghostty window.\n'
  exit 0
fi
if [[ -f "$target" ]]; then
  cp -p "$target" "$target.backup-$(date +%Y%m%d-%H%M%S)"
  temporary_target="$(mktemp "$target.XXXXXX")"
  awk -v old="$legacy_include" -v new="$include" '
    $0 == old || $0 == new {
      if (!replaced) print new
      replaced = 1
      next
    }
    { print }
    END { if (!replaced) print new }
  ' "$target" > "$temporary_target"
  cat "$temporary_target" > "$target"
  rm -f "$temporary_target"
else
  printf '# Matrix Power (remove the next line to uninstall)\n%s\n' "$include" > "$target"
fi
printf 'Matrix Power installed. Reload Ghostty config (Cmd+Shift+,), then open a new window.\n'
