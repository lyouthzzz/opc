#!/usr/bin/env bash
#
# install-skills.sh — 将本仓库 skills/ 与 commands/ 安装到 AI Agent 的对应目录。
#
# 用法:
#   ./scripts/install-skills.sh [选项] [DEST_DIR]
#
# 选项:
#   -t, --target <name>   预设目标 agent，可选: claude | codex | cursor | agents | all
#   -l, --link            使用软链接（symlink）而非复制（随仓库更新自动生效）
#   -f, --force           覆盖已存在的同名 skill / command（--link 时默认开启）
#       --no-force        软链接模式下仍跳过已存在项（覆盖 --link 的默认覆盖行为）
#   -n, --dry-run         只打印将要执行的操作，不实际改动
#       --no-commands     只装 skills，不装 /command 斜杠命令
#       --commands-only   只装 /command 斜杠命令，不装 skills
#   -h, --help            显示帮助
#
# DEST_DIR: 自定义目标 skills 目录（仅安装 skills；命令目录因 Agent 而异，故自定义目录不装 command）
#
# 各 Agent 目录:
#   claude → skills: ~/.claude/skills/        commands: ~/.claude/commands/
#   codex  → skills: ~/.codex/skills/         commands: ~/.codex/prompts/
#   cursor → skills: ~/.cursor/skills-cursor/ commands: ~/.cursor/commands/
#   agents → skills: ~/.agents/skills/        commands: ~/.agents/commands/
#
# 示例:
#   ./scripts/install-skills.sh --target claude          # skills+commands 复制到 Claude
#   ./scripts/install-skills.sh --target all --link      # 软链接到全部已知 agent 目录
#   ./scripts/install-skills.sh --target cursor --commands-only
#   ./scripts/install-skills.sh ~/my/skills              # 仅把 skills 复制到自定义目录

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILLS_SRC="$REPO_ROOT/skills"
CMDS_SRC="$REPO_ROOT/commands"

TARGET=""; DEST_DIR=""; USE_LINK=0; FORCE=0; NO_FORCE=0; DRY_RUN=0; DO_SKILLS=1; DO_COMMANDS=1

usage() { sed -n '2,40p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    -t|--target) TARGET="${2:-}"; shift 2 ;;
    -l|--link)   USE_LINK=1; shift ;;
    -f|--force)  FORCE=1; shift ;;
    --no-force)  NO_FORCE=1; shift ;;
    -n|--dry-run) DRY_RUN=1; shift ;;
    --no-commands) DO_COMMANDS=0; shift ;;
    --commands-only) DO_SKILLS=0; shift ;;
    -h|--help)   usage; exit 0 ;;
    -*)          echo "未知选项: $1" >&2; usage; exit 1 ;;
    *)           DEST_DIR="$1"; shift ;;
  esac
done

# 软链接用于开发迭代，默认覆盖已存在项（复制模式仍默认跳过）
if [[ "$USE_LINK" == "1" && "$NO_FORCE" != "1" ]]; then
  FORCE=1
fi

# 目标列表，元素格式: "标签|skills目录|commands目录"（commands 目录为空表示不装命令）
TARGETS=()
if [[ -n "$DEST_DIR" ]]; then
  TARGETS+=("custom|$DEST_DIR|")
elif [[ -n "$TARGET" ]]; then
  case "$TARGET" in
    claude) TARGETS+=("claude|$HOME/.claude/skills|$HOME/.claude/commands") ;;
    codex)  TARGETS+=("codex|$HOME/.codex/skills|$HOME/.codex/prompts") ;;
    cursor) TARGETS+=("cursor|$HOME/.cursor/skills-cursor|$HOME/.cursor/commands") ;;
    agents) TARGETS+=("agents|$HOME/.agents/skills|$HOME/.agents/commands") ;;
    all)
      TARGETS+=("claude|$HOME/.claude/skills|$HOME/.claude/commands")
      TARGETS+=("codex|$HOME/.codex/skills|$HOME/.codex/prompts")
      TARGETS+=("cursor|$HOME/.cursor/skills-cursor|$HOME/.cursor/commands")
      TARGETS+=("agents|$HOME/.agents/skills|$HOME/.agents/commands") ;;
    *) echo "未知 target: $TARGET（可选 claude|codex|cursor|agents|all）" >&2; exit 1 ;;
  esac
else
  echo "请用 --target <claude|codex|cursor|agents|all> 或提供 DEST_DIR。见 --help。" >&2
  exit 1
fi

run() { if [[ "$DRY_RUN" == "1" ]]; then printf '[dry-run]'; printf ' %q' "$@"; printf '\n'; else "$@"; fi }

# install_one <源目录或文件> <目标路径> <显示名>
install_one() {
  local src="$1" target_path="$2" name="$3"
  if [[ -e "$target_path" || -L "$target_path" ]]; then
    if [[ "$FORCE" == "1" ]]; then run rm -rf "$target_path"
    else echo "    跳过（已存在）: $name  —— 用 --force 覆盖"; SKIPPED=$((SKIPPED+1)); return; fi
  fi
  if [[ "$USE_LINK" == "1" ]]; then run ln -s "$src" "$target_path"
  else run cp -R "$src" "$target_path"; fi
  echo "    安装: $name"; INSTALLED=$((INSTALLED+1))
}

echo "仓库: $REPO_ROOT"
echo "内容: $([[ $DO_SKILLS == 1 ]] && echo -n 'skills ')$([[ $DO_COMMANDS == 1 ]] && echo -n 'commands')"
echo "模式: $([[ $USE_LINK == 1 ]] && echo 软链接 || echo 复制)$([[ $FORCE == 1 ]] && echo ' + 覆盖')$([[ $DRY_RUN == 1 ]] && echo ' (dry-run)')"
echo

INSTALLED=0; SKIPPED=0
for entry in "${TARGETS[@]}"; do
  IFS='|' read -r label skills_dest cmds_dest <<< "$entry"
  echo "==> [$label]"

  if [[ "$DO_SKILLS" == "1" && -d "$SKILLS_SRC" ]]; then
    echo "  skills → $skills_dest"
    run mkdir -p "$skills_dest"
    for p in "$SKILLS_SRC"/*/; do
      [[ -f "$p/SKILL.md" ]] || continue
      local_src="${p%/}"
      install_one "$local_src" "$skills_dest/$(basename "$local_src")" "$(basename "$local_src")"
    done
  fi

  if [[ "$DO_COMMANDS" == "1" && -d "$CMDS_SRC" ]]; then
    if [[ -z "$cmds_dest" ]]; then
      echo "  commands → (自定义目录不安装命令，请用 --target 指定 Agent)"
    else
      echo "  commands → $cmds_dest"
      run mkdir -p "$cmds_dest"
      for f in "$CMDS_SRC"/*.md; do
        [[ -f "$f" ]] || continue
        install_one "$f" "$cmds_dest/$(basename "$f")" "$(basename "$f")"
      done
    fi
  fi
  echo
done

echo "完成：安装 $INSTALLED 个，跳过 $SKIPPED 个。"
