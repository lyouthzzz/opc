# opc — Agent Skills 仓库

本仓库收录可复用的 **Agent Skill**（基于 `SKILL.md` 的技能包）与配套的 **`/command` 斜杠命令**，供 Cursor、Claude Code、Codex 等支持 skill 的 AI Agent 加载使用。

## 已收录 Skills

| Skill | 说明 | 外部依赖 |
|-------|------|----------|
| [`价值投资`](skills/价值投资/SKILL.md) | 基于段永平/巴菲特理念的企业价值分析模型（right business/people/price 三要素 + 五维度 + 四种好运），并通过同花顺问财补充市场现状（股价/估值/财报口径/行业板块/资金流） | 统一使用 `iwencai` / `hithink-*` skills——见 [`mcp-tool-guide.md`](skills/价值投资/references/mcp-tool-guide.md) |
| [`股票魔法师`](skills/股票魔法师/SKILL.md) | 基于 SEPA / Mark Minervini 方法的中短线交易分析，判断趋势模板、VCP、中枢点、止损、仓位与卖出信号 | 统一使用 `hithink-market-query` + 行业/板块问财 skills |
| [`股票比较`](skills/股票比较/SKILL.md) | 综合 `价值投资` 与 `股票魔法师`，对多只股票做机会成本排序，并输出买入、持有、减仓、卖出或换仓计划 | 同上 |

## 斜杠命令 /command

除自动触发外，安装后可用 `/command` 主动唤起 skill。**命令名与 skill 中文名一致**（如 `/价值投资` 对应 `skills/价值投资/`，命令文件为 `commands/价值投资.md`）。

| 命令 | 作用 | 用法示例 |
|------|------|----------|
| `/价值投资` | 触发 `价值投资` skill，对指定公司做七步价值分析 | `/价值投资 泡泡玛特 09992.HK` |
| `/股票魔法师` | 触发 `股票魔法师` skill，按 SEPA / VCP 规则分析买点、卖点、止损和仓位 | `/股票魔法师 600519.SH` |
| `/股票比较` | 触发 `股票比较` skill，对多只股票做机会成本比较和买卖/换仓计划 | `/股票比较 600519.SH 09992.HK AAPL` |

命令定义在 [`commands/`](commands/)，一份文件跨 Claude / Cursor / Codex 通用。安装位置：Claude/Cursor 放入各自 `commands/`，Codex 放入 `prompts/`（脚本已自动处理）。

## 目录结构

```
opc/
├── README.md
├── scripts/
│   └── install-skills.sh        # 脚本安装 skills + commands（可选）
├── commands/                    # /command 斜杠命令（与 skill 同名，如 /价值投资）
│   ├── 价值投资.md
│   ├── 股票魔法师.md
│   └── 股票比较.md
└── skills/
    ├── 股票比较/
    │   └── SKILL.md
    ├── 股票魔法师/
    │   ├── SKILL.md
    │   └── references/
    └── 价值投资/
        ├── SKILL.md
        └── references/          # 方法论、MCP 手册、公司知识库等
```

> 每个 skill 是一个自包含目录：`SKILL.md`（技能主文件，含 YAML frontmatter）+ `references/`（按需加载的参考资料）。**安装即把整个目录放入 Agent 的 skills 目录；命令则放入 Agent 的 commands/prompts 目录。**

---

## 安装方式一：Prompt 安装（推荐）

用 AI Agent 在本仓库目录下打开会话，直接把下面这段 prompt 发给它，让 Agent 自动完成安装（含 skills 与 /command 命令）。适合不想记命令、想让 Agent 处理冲突与校验的场景。

```text
你是负责安装 Agent Skill 与 /command 命令的助手。请把「当前仓库」的 skills/ 与 commands/ 安装到我的 Agent 目录，按以下步骤执行：

1. 确认目标 Agent（可多选；不确定就先问我）及其目录：
   - Claude Code → skills: ~/.claude/skills/        commands: ~/.claude/commands/
   - Codex      → skills: ~/.codex/skills/          commands: ~/.codex/prompts/
   - Cursor     → skills: ~/.cursor/skills-cursor/   commands: ~/.cursor/commands/
   - 通用/其它   → skills: ~/.agents/skills/          commands: ~/.agents/commands/

2. 安装 skills：遍历 skills/*/，把每个含 SKILL.md 的目录（连同 references/ 全部文件）复制到目标 skills 目录，保持目录名与结构不变。

3. 安装 commands：把 commands/*.md 复制到目标 Agent 的命令目录（Claude/Cursor 用 commands/，Codex 用 prompts/）。

4. 冲突处理：目标已存在同名项时，先告诉我差异，确认后再覆盖，或备份为 <name>.bak 再装。

5. 校验：读取每个已安装 SKILL.md 与命令文件的 frontmatter，确认 name / description 存在；确认 references/ 已一并复制。

6. 输出安装报告：装了哪些 skill 与命令、装到哪些目录、有无跳过/覆盖/备份。

要求：只做复制安装，不修改任何内容。
```

安装后，重启 / 重新加载 Agent，即可：既能用触发词自动唤起 skill（如「帮我做一次价值投资」），也能用 `/价值投资`、`/股票魔法师` 主动调用。

---

## 安装方式二：脚本安装

若偏好命令行，用仓库自带脚本 [`scripts/install-skills.sh`](scripts/install-skills.sh)（默认同时安装 skills 与 /command 命令，并按 Agent 自动选对命令目录）：

```bash
# 复制到 Claude Code（skills → ~/.claude/skills，commands → ~/.claude/commands）
./scripts/install-skills.sh --target claude

# 软链接到全部已知 Agent 目录（随仓库更新自动生效，便于开发迭代）
./scripts/install-skills.sh --target all --link

# 只装命令 / 只装 skills
./scripts/install-skills.sh --target cursor --commands-only
./scripts/install-skills.sh --target codex --no-commands

# 覆盖已存在项 / 安装到自定义目录（自定义目录仅装 skills）
./scripts/install-skills.sh --target cursor --force
./scripts/install-skills.sh ~/some/skills

# 先预览将要执行的操作（不实际改动）
./scripts/install-skills.sh --target all --dry-run
```

选项：

| 选项 | 说明 |
|------|------|
| `-t, --target <name>` | 预设目标：`claude` / `codex` / `cursor` / `agents` / `all` |
| `-l, --link` | 用软链接代替复制（源仓库更新后免重装） |
| `-f, --force` | 覆盖已存在的同名 skill / command（复制模式默认跳过） |
| `--no-force` | 软链接模式下仍跳过已存在项（覆盖 `--link` 的默认覆盖行为） |
| `-n, --dry-run` | 只打印将要执行的操作 |
| `--no-commands` | 只装 skills，不装 /command |
| `--commands-only` | 只装 /command，不装 skills |
| `DEST_DIR` | 自定义 skills 目录（仅装 skills；命令目录因 Agent 而异，故不装命令） |

**复制 vs 软链接**：日常使用推荐**复制**（稳定、可离线）；若你在持续修改本仓库的 skill/命令，用 `--link` 让改动即时生效（`--link` 默认覆盖已存在项，可用 `--no-force` 改为跳过）。

---

## 各 Agent 目录参考

| Agent | skills 目录 | commands 目录 |
|-------|-------------|---------------|
| Claude Code | `~/.claude/skills/` | `~/.claude/commands/` |
| Codex | `~/.codex/skills/` | `~/.codex/prompts/` |
| Cursor | `~/.cursor/skills-cursor/` | `~/.cursor/commands/` |
| 通用/其它 | `~/.agents/skills/` | `~/.agents/commands/` |

---

## 验证与卸载

- **验证**：确认目标目录下出现 `<skill 名>/SKILL.md` 与 `commands/<命令>.md`，重启 Agent 后用触发词或 `/命令` 测试是否能唤起。
- **卸载**：删除对应的 skill 目录与命令文件即可，例如：

```bash
rm -rf ~/.claude/skills/价值投资
rm -f  ~/.claude/commands/价值投资.md
```

---

## 依赖说明：同花顺问财 Skills

推荐组合：

| Skill | 用途 | 结论 |
|-----|------|------|
| `hithink-market-query` | 个股 / ETF / 指数行情、涨跌幅、成交量、资金流、技术指标 | 个股与指数默认入口 |
| `hithink-industry-query` | 行业估值、盈利、财务、行情、排名 | 行业层数据默认入口 |
| `hithink-sector-selector` | 板块筛选、资金流、涨跌幅、估值 | 板块和主题环境默认入口 |
| `hithink-hkstock-selector` | 港股筛选、港股行情与财务类条件组合 | 港股默认入口 |

推荐先安装 Iwencai SkillHub CLI，再安装以上 skills。例如在 Codex：

```bash
iwencai-skillhub-cli --dir ~/.codex/skills install hithink-market-query
iwencai-skillhub-cli --dir ~/.codex/skills install hithink-industry-query
iwencai-skillhub-cli --dir ~/.codex/skills install hithink-sector-selector
iwencai-skillhub-cli --dir ~/.codex/skills install hithink-hkstock-selector
```

并在 shell profile 中配置：

```bash
export IWENCAI_BASE_URL="https://openapi.iwencai.com"
export IWENCAI_API_KEY="你的_IWENCAI_API_KEY"
```

工具清单、问句改写规则与数据时效校验见 [`mcp-tool-guide.md`](skills/价值投资/references/mcp-tool-guide.md)。
