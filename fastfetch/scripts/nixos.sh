nixos_latest() {
  local current_version major major_next major_year major_month
  local channel_url final_url channel_version
  local html hydra_version ago

  # --- Current version ---
  current_version=$(nixos-version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9a-f]+' | head -1)
  [[ -z "$current_version" ]] && \
    current_version=$(nixos-version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
  [[ -z "$current_version" ]] && \
    current_version=$(nixos-version | head -1)

  major=$(echo "$current_version" | grep -oE '^[0-9]+\.[0-9]+' | head -1)

  # --- Next major version ---
  major_year=$(echo "$major" | cut -d. -f1)
  major_month=$(echo "$major" | cut -d. -f2)
  if [[ "$major_month" == "05" ]]; then
    major_next="${major_year}.11"
  else
    major_next="$(( major_year + 1 )).05"
  fi

  local chan hyd ago next_version=""


    # --- Hydra tested build ---
    html=$(curl -sf --max-time 8 "https://hydra.nixos.org/job/nixos/release-${major}/tested")
    hydra_version=""
    ago=""
    if [[ -n "$html" ]]; then
      hydra_version=$(echo "$html" | grep -oE "nixos-${major//./\\.}\.[0-9]+\.[0-9a-f]+" | head -1)
      ago=$(echo "$html" | grep -o 'class="date is-relative">[^<]*' | head -1 \
        | sed 's/class="date is-relative">//; s/ ago//')
    fi

    # --- Channel version ---
    channel_url="https://channels.nixos.org/nixos-${major}/git-revision"
    final_url=$(curl -Ls -o /dev/null -w '%{url_effective}' "$channel_url")
    channel_version=""
    if [[ "$final_url" =~ (nixos-${major//./\\.}\.[0-9]+\.[0-9a-f]+) ]]; then
      channel_version="${BASH_REMATCH[1]}"
    elif [[ "$final_url" =~ (nixos-${major//./\\.}\.[0-9]+) ]]; then
      channel_version="${BASH_REMATCH[1]}"
    fi

    # --- Next release channel ---
    local next_url="https://channels.nixos.org/nixos-${major_next}/git-revision"
    local next_final_url
    next_final_url=$(curl -Ls -o /dev/null -w '%{url_effective}' "$next_url")
    next_version=""
    if [[ "$next_final_url" =~ (nixos-${major_next//./\\.}\.[0-9]+\.[0-9a-f]+) ]]; then
      next_version="${BASH_REMATCH[1]#nixos-}"
    elif [[ "$next_final_url" =~ (nixos-${major_next//./\\.}\.[0-9]+) ]]; then
      next_version="${BASH_REMATCH[1]#nixos-}"
    fi

    chan="${channel_version#nixos-}"
    hyd="${hydra_version#nixos-}"


  local cur="${current_version}"

  # --- Colors ---
  local c1=$'\e[38;2;81;188;254m\e[1m'
  local c2=$'\e[38;2;105;181;254m\e[1m'
  local c3=$'\e[38;2;130;173;253m\e[1m'
  local c4=$'\e[38;2;154;166;253m\e[1m'
  local c5=$'\e[38;2;169;160;253m\e[1m'
  local c6=$'\e[38;2;179;154;253m\e[1m'
  local c7=$'\e[38;2;186;153;253m\e[1m'
  local c8=$'\e[38;2;192;163;253m\e[1m'
  local c9=$'\e[38;2;198;167;253m\e[1m'
  local c10=$'\e[38;2;205;173;252m\e[1m'
  local reset=$'\e[0m'
  local dim=$'\e[2;37m'

  # --- Top border ---
  printf '%s ┌──────%s───────%s───────%s───────%s───────%s───────%s───────%s───────%s───────%s──────┐%s %sNixOS Upgrade\n' \
     "$c1" "$c2" "$c3" "$c4" "$c5" "$c6" "$c7" "$c8" "$c9" "$c10" "$c10"

      # --- Next release ---
  if [[ -n "$next_version" ]]; then
    printf '%s ├ 󱓞  Released %s  %s   %sNixOS %s %s\n' \
       "$c1" "$reset" "$next_version" $'\e[1;38;2;171;255;74m' "$major_next" "$reset"
  fi

  # --- Current version ---
  printf '%s ├ 󱄅  Current  %s  %s\n' "$c2" "$reset" "$cur"

  # --- Channel ---
  if [[ -n "$chan" ]]; then
    if [[ "$cur" == "$chan" ]]; then
      printf '%s ├ 󰓦  Channel  %s  %s  %sin sync%s\n' \
         "$c4" "$reset" "$chan" "$c4" "$reset"
    else
      printf '%s ├ 󰓦  Channel  %s  %s  %supgrade available!%s\n' \
         "$c4" "$reset" "$chan" $'\e[1;38;2;171;255;74m' "$reset"
    fi
  else
    printf '%s ├ 󰓦  Channel  %s  %s(unavailable)%s\n' \
       "$c4" "$reset" "$dim" "$reset"
  fi

  # --- Hydra ---

  if [[ -n "$hyd" ]]; then
    local ago_str=""
    [[ -n "$ago" ]] && ago_str=$'\e[2;37m'"(${ago} ago)"$'\e[0m'
    if [[ "$hyd" == "$chan" ]]; then
      printf '%s%s └ 󰄉  Hydra    %s  %s  %sin sync%s  %s\n' \
         "$c6" "$hydra_corner" "$reset" "$hyd" "$c6" "$reset" "$ago_str"
    else
      printf '%s%s └ 󰄉  Hydra    %s  %s  %snewer%s  %s\n' \
         "$c6" "$hydra_corner" "$reset" "$hyd" $'\e[1;38;2;171;255;74m' "$reset" "$ago_str"
    fi
  else
    printf '%s%s └ 󰄉  Hydra    %s  %s(unavailable)%s\n' \
       "$c6" "$hydra_corner" "$reset" "$dim" "$reset"
  fi


}

nixos_latest
