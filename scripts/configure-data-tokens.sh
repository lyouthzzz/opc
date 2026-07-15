#!/usr/bin/env bash
# 面向普通用户的数据 Token 配置向导。
# macOS 使用系统隐藏输入框；其他系统在可用时使用不回显的终端输入。

set -euo pipefail

MODE="all"
PROFILE="${OPC_SHELL_PROFILE:-}"
SKIP_SENTINEL="__OPC_SKIP__"
CANCELLED=0

usage() {
  printf '用法: %s [--tdx-only|--iwencai-only] [--profile <path>]\n' "$0"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tdx-only) MODE="tdx"; shift ;;
    --iwencai-only) MODE="iwencai"; shift ;;
    --profile) PROFILE="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) printf '无法识别的选项: %s\n' "$1" >&2; usage; exit 1 ;;
  esac
done

if [[ -z "$PROFILE" ]]; then
  case "${SHELL:-}" in
    */zsh) PROFILE="${ZDOTDIR:-$HOME}/.zshrc" ;;
    */bash) PROFILE="$HOME/.bash_profile" ;;
    *) PROFILE="$HOME/.profile" ;;
  esac
fi

mkdir -p "$(dirname "$PROFILE")"
touch "$PROFILE"

BACKUP=""
backup_profile_once() {
  if [[ -z "$BACKUP" ]]; then
    BACKUP="${PROFILE}.bak-opc-$(date +%Y%m%d%H%M%S)"
    cp -p "$PROFILE" "$BACKUP"
  fi
}

profile_has_export() {
  local name="$1"
  grep -Eq "^[[:space:]]*export[[:space:]]+${name}=.+" "$PROFILE"
}

write_export() {
  local name="$1" value="$2" escaped tmp mode
  [[ "$value" != *$'\n'* && "$value" != *$'\r'* ]] || {
    printf '%s 包含无效换行，未保存。\n' "$name" >&2
    return 1
  }

  backup_profile_once
  escaped=$(printf '%s' "$value" | sed "s/'/'\\\\''/g")
  tmp=$(mktemp "${PROFILE}.tmp.XXXXXX")
  awk -v name="$name" '
    $0 !~ "^[[:space:]]*export[[:space:]]+" name "=" { print }
  ' "$PROFILE" > "$tmp"
  printf "\nexport %s='%s'\n" "$name" "$escaped" >> "$tmp"

  if mode=$(stat -f '%Lp' "$PROFILE" 2>/dev/null); then
    chmod "$mode" "$tmp"
  else
    chmod 600 "$tmp"
  fi
  mv "$tmp" "$PROFILE"
}

prompt_secret() {
  local title="$1" message="$2" url="$3" value=""

  if [[ "$(uname -s)" == "Darwin" ]] && command -v osascript >/dev/null 2>&1; then
    if ! value=$(/usr/bin/osascript - "$title" "$message" "$url" <<'APPLESCRIPT'
on run argv
  tell application "System Events"
    activate
    set choiceDialog to display dialog (item 2 of argv) with title (item 1 of argv) buttons {"取消", "跳过", "继续配置"} default button "继续配置" cancel button "取消"
    if button returned of choiceDialog is "跳过" then return "__OPC_SKIP__"
  end tell
  open location (item 3 of argv)
  tell application "System Events"
    activate
    set resultDialog to display dialog "获取后请把 Token 粘贴到这里。输入内容会被隐藏。" with title (item 1 of argv) default answer "" with hidden answer buttons {"取消", "安全保存"} default button "安全保存" cancel button "取消"
    return text returned of resultDialog
  end tell
end run
APPLESCRIPT
    ); then
      printf '已取消配置。\n' >&2
      return 2
    fi
  elif [[ -r /dev/tty && -w /dev/tty ]]; then
    printf '%s（输入内容不会显示，直接按回车可跳过）: ' "$title" > /dev/tty
    IFS= read -r -s value < /dev/tty
    printf '\n' > /dev/tty
    if [[ -z "$value" ]]; then
      value="$SKIP_SENTINEL"
    fi
  else
    printf '当前环境没有安全输入窗口，请改用支持隐藏输入的本地安装器。\n' >&2
    return 2
  fi

  printf '%s' "$value"
}

configure_tdx() {
  local token="${TDX_API_KEY:-}"
  if profile_has_export TDX_API_KEY; then
    printf '通达信 Token：已配置\n'
    return
  fi

  if [[ -z "$token" ]]; then
    if ! token=$(prompt_secret \
        "配置通达信" \
        "已为你打开通达信官网。请按“AI平台 → 通达信MCP → 我的订单 → API Key管理”获取 Key，然后粘贴到这里。暂时不需要该数据源时可点“跳过”。" \
        "https://www.tdx.com.cn"); then
      CANCELLED=1
      printf '通达信 Token：已取消\n'
      return
    fi
  fi
  if [[ "$token" == "$SKIP_SENTINEL" ]]; then
    printf '通达信 Token：已跳过（将使用模型默认数据与可用检索）\n'
    return
  fi
  write_export TDX_API_KEY "$token"
  token=""
  printf '通达信 Token：已安全保存\n'
}

configure_iwencai() {
  local token="${IWENCAI_API_KEY:-}"

  if profile_has_export IWENCAI_API_KEY; then
    if [[ "${IWENCAI_BASE_URL:-}" != "https://openapi.iwencai.com" ]] || ! profile_has_export IWENCAI_BASE_URL; then
      write_export IWENCAI_BASE_URL "https://openapi.iwencai.com"
    fi
    printf '问财 Token：已配置\n'
    return
  fi

  if [[ -z "$token" ]]; then
    if ! token=$(prompt_secret \
        "配置同花顺问财" \
        "已为你打开问财 SkillHub。登录后点击任意技能，在安装提示的“Agent用户”部分复制 API Key，然后粘贴到这里。暂时不需要该数据源时可点“跳过”。" \
        "https://www.iwencai.com/skillhub"); then
      CANCELLED=1
      printf '问财 Token：已取消\n'
      return
    fi
  fi
  if [[ "$token" == "$SKIP_SENTINEL" ]]; then
    printf '问财 Token：已跳过（不会安装问财依赖，将使用模型默认数据与可用检索）\n'
    return
  fi
  write_export IWENCAI_BASE_URL "https://openapi.iwencai.com"
  write_export IWENCAI_API_KEY "$token"
  token=""
  printf '问财 Token：已安全保存\n'
}

case "$MODE" in
  all) configure_tdx; configure_iwencai ;;
  tdx) configure_tdx ;;
  iwencai) configure_iwencai ;;
esac

if [[ -n "$BACKUP" ]]; then
  printf '原配置已备份。\n'
fi
if [[ "$CANCELLED" == "1" ]]; then
  printf '配置尚未完成；可重新运行向导，或明确选择“跳过”。\n' >&2
  exit 2
fi
printf '选择已保存。已配置的数据源会在重启 Agent 后生效；跳过的数据源不会影响 skills 使用。\n'
