# opc — Agent Skills 仓库

本仓库收录可复用的 **Agent Skill**（基于 `SKILL.md` 的技能包）与配套的 **`/command` 斜杠命令**，供 Cursor、Claude Code、Codex、WorkBuddy 等支持 skill 的 AI Agent 加载使用。

## 已收录 Skills

| Skill | 说明 | 外部依赖 |
|-------|------|----------|
| [`价值投资`](skills/价值投资/SKILL.md) | 基于段永平/巴菲特理念的企业价值分析模型（right business/people/price 三要素 + 五维度 + 四种好运），并通过同花顺问财补充市场现状（股价/估值/财报口径/行业板块/资金流） | 通达信官方 MCP + 问财 `announcement-search` / `hithink-*` skills；需要双 Token |
| [`股票魔法师`](skills/股票魔法师/SKILL.md) | 基于 SEPA / Mark Minervini 方法的中短线交易分析，判断趋势模板、VCP、中枢点、止损、仓位与卖出信号 | 通达信官方 MCP + 问财 skills；需要双 Token |
| [`股票比较`](skills/股票比较/SKILL.md) | 综合 `价值投资` 与 `股票魔法师`，对多只股票做机会成本排序，并输出买入、持有、减仓、卖出或换仓计划 | 同上 |
| [`行业分析`](skills/行业分析/SKILL.md) | A 股行业/板块机会挖掘：行业轮动、宏观到行业映射、产业链解读、近30天催化梳理与行业内个股筛选 | 通达信官方 MCP + 问财 `announcement-search` / 行业板块 skills；需要双 Token |

## 斜杠命令 /command

除自动触发外，安装后可用 `/command` 主动唤起 skill。**命令名与 skill 中文名一致**（如 `/价值投资` 对应 `skills/价值投资/`，命令文件为 `commands/价值投资.md`）。

| 命令 | 作用 | 用法示例 |
|------|------|----------|
| `/价值投资` | 触发 `价值投资` skill，对指定公司做七步价值分析 | `/价值投资 泡泡玛特 09992.HK` |
| `/股票魔法师` | 触发 `股票魔法师` skill，按 SEPA / VCP 规则分析买点、卖点、止损和仓位 | `/股票魔法师 600519.SH` |
| `/股票比较` | 触发 `股票比较` skill，对多只股票做机会成本比较和买卖/换仓计划 | `/股票比较 600519.SH 09992.HK AAPL` |
| `/行业分析` | 触发 `行业分析` skill，对行业轮动、产业链、催化剂和行业内选股做分析 | `/行业分析 未来6到12个月哪些行业有机会` |

命令定义在 [`commands/`](commands/)，一份文件跨 Claude / Cursor / Codex 通用。安装位置：Claude/Cursor 放入各自 `commands/`，Codex 放入 `prompts/`（脚本已自动处理）。

## 目录结构

```
opc/
├── README.md
├── scripts/
│   └── install-skills.sh        # 脚本安装 skills + commands（可选）
├── commands/                    # /command 斜杠命令（与 skill 同名，如 /价值投资）
│   ├── 价值投资.md
│   ├── 行业分析.md
│   ├── 股票魔法师.md
│   └── 股票比较.md
└── skills/
    ├── 行业分析/
    │   └── SKILL.md
    ├── 股票比较/
    │   └── SKILL.md
    ├── 股票魔法师/
    │   ├── SKILL.md
    │   └── references/
    └── 价值投资/
        ├── SKILL.md
        └── references/          # 方法论、市场数据手册、公司知识库等
```

> 每个 skill 是一个自包含目录：`SKILL.md`（技能主文件，含 YAML frontmatter）+ `references/`（按需加载的参考资料）。**安装即把整个目录放入 Agent 的 skills 目录；命令则放入 Agent 的 commands/prompts 目录。**

---

## 安装方式一：Prompt 安装（推荐）

**无需 clone 本仓库。** 在 Cursor、Claude Code、Codex、WorkBuddy 等任意 Agent 会话中，直接复制下面整段 prompt 发送即可；Agent 会从 GitHub 拉取 [`lyouthzzz/opc`](https://github.com/lyouthzzz/opc) 并完成安装（含 skills 与 `/command` 命令）。适合不想记命令、想让 Agent 处理拉取、冲突与校验的场景。

```text
你是负责安装 Agent Skill、/command 命令及其数据前置的助手。请从 GitHub 仓库 https://github.com/lyouthzzz/opc 安装 skills/ 与 commands/ 到我的 Agent 目录，并交互配置通达信与同花顺问财，按以下步骤执行：

0. 获取源码（任选其一，优先 A）：
   A. 浅克隆到临时目录后安装，装完可删：
      git clone --depth 1 https://github.com/lyouthzzz/opc.git /tmp/opc-install
      源码根目录 = /tmp/opc-install
   B. 若当前工作区已是该仓库（含 skills/ 与 commands/），可直接用当前目录，跳过克隆。
   C. 若无 git，用 GitHub 归档下载并解压：
      curl -sL https://github.com/lyouthzzz/opc/archive/refs/heads/main.tar.gz | tar -xz -C /tmp
      源码根目录 = /tmp/opc-main（若默认分支为 master，则路径为 /tmp/opc-master）

1. 确认目标 Agent（可多选；不确定就先问我）及其目录：
   - Claude Code → skills: ~/.claude/skills/        commands: ~/.claude/commands/
   - Codex      → skills: ~/.codex/skills/          commands: ~/.codex/prompts/
   - Cursor     → skills: ~/.cursor/skills-cursor/   commands: ~/.cursor/commands/
   - WorkBuddy  → skills: ~/.workbuddy/skills/      commands: ~/.workbuddy/commands/
   - 通用/其它   → skills: ~/.agents/skills/          commands: ~/.agents/commands/

2. 交互配置数据前置（必须执行，不可静默跳过）：

   安全规则：只检查环境变量是否存在，不输出变量值；不要让我把 Token 粘贴到聊天中。优先让我在本地交互终端中以不回显方式输入，并把变量幂等写入 shell profile；修改 profile 或 MCP 配置前先备份。若当前 Agent 不能安全接收本地输入，给我明确的本地操作步骤并暂停等待，不要把真实 Token 写进项目文件、安装报告、日志或命令历史。

   A. 通达信（官方 MCP）：
   - 检查 shell profile 中是否已有 `TDX_API_KEY`，并检查目标 Agent 是否已连接官方通达信 MCP。不要把无需 API Key、连接公开行情服务器的第三方 `tdx-mcp` 当成官方 MCP。
   - 若没有 Key，提示我按此路径获取：`https://www.tdx.com.cn` → `AI平台` → `通达信MCP` → 购买后进入 `我的订单` → `会员中心` → `API Key管理` → `创建API Key` → `详情`。
   - 将 Key 以本仓库约定的 `TDX_API_KEY` 写入 shell profile。官方服务地址为 `https://mcp.tdx.com.cn:3001/mcp`，鉴权请求头为 `tdx-api-key`；MCP 配置应从 `TDX_API_KEY` 读取请求头，不要在配置里硬编码 Key。
   - Codex 配置核心为：`url = "https://mcp.tdx.com.cn:3001/mcp"`，`env_http_headers = { "tdx-api-key" = "TDX_API_KEY" }`。Claude Code / Cursor 等 JSON MCP 配置核心为：`"url": "https://mcp.tdx.com.cn:3001/mcp"`，`"headers": { "tdx-api-key": "${TDX_API_KEY}" }`。按目标 Agent 的原生格式合并配置；若已有同名但不同来源的 MCP，先展示差异并询问，不能直接覆盖。

   B. 同花顺问财：
   - 先用 `command -v iwencai-skillhub-cli` 检查是否已安装 Iwencai SkillHub CLI。
   - 若未安装，仅使用官方入口 `https://www.iwencai.com/skillhub/static/0.0.4/download_and_install.sh`：下载到临时目录、先审阅再执行，只安装 CLI。若该下载器报内部安装脚本文件名不匹配，只能从下载器声明的同一问财官方 ZIP 下载包，审阅后执行包内 `iwencai-install.sh`；不要改用第三方来源。
   - 若已安装，跳过 CLI 安装。随后对每个目标 skills 目录执行：`iwencai-skillhub-cli --dir <目标skills目录> install announcement-search`；已存在时先比较，确认后升级或覆盖。
   - 提示我到 `https://www.iwencai.com/skillhub` 登录，点击任意技能，在安装提示的 `Agent用户` 部分复制 `IWENCAI_API_KEY`。
   - 确保 shell profile 中幂等存在：`IWENCAI_BASE_URL=https://openapi.iwencai.com` 与 `IWENCAI_API_KEY=<本地安全输入的Token>`。

   C. 预检：重新加载 profile 后，只报告 `TDX_API_KEY`、`IWENCAI_BASE_URL`、`IWENCAI_API_KEY` 的“已配置/缺失”状态；验证官方通达信 MCP 可连接，且 `<目标skills目录>/announcement-search/SKILL.md` 存在。不得显示任何 Token 内容。

3. 安装本仓库 skills：遍历 <源码根目录>/skills/*/，把每个含 SKILL.md 的目录（连同 references/ 全部文件）复制到目标 skills 目录，保持目录名与结构不变。

4. 安装 commands：把 <源码根目录>/commands/*.md 复制到目标 Agent 的命令目录（Claude/Cursor 用 commands/，Codex 用 prompts/）。

5. 冲突处理：目标已存在同名项时，先告诉我差异，确认后再覆盖，或备份为 <name>.bak 再装。

6. 校验：读取每个已安装 SKILL.md 与命令文件的 frontmatter，确认 name / description 存在；确认 references/ 已一并复制；与 GitHub 上仓库列出的 skill 名一致（价值投资、股票魔法师、股票比较、行业分析）；确认四个 skill 都包含“双 Token 预检”。

7. 输出安装报告：源码来源（clone 路径或当前仓库）、装了哪些 skill 与命令、`announcement-search` 安装状态、官方通达信 MCP 状态、三个环境变量的“已配置/缺失”状态、装到哪些目录、有无跳过/覆盖/备份。禁止输出 Token 值。

要求：本仓库内容只做复制安装，不修改 skill/command 内容；外部改动仅限上述 CLI、`announcement-search`、shell profile 与官方通达信 MCP 配置。任一 Token 或依赖未完成时，不要宣称安装已完整完成。若用了临时目录，安装完成后询问是否删除。
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
./scripts/install-skills.sh --target workbuddy

# 覆盖已存在项 / 安装到自定义目录（自定义目录仅装 skills）
./scripts/install-skills.sh --target cursor --force
./scripts/install-skills.sh ~/some/skills

# 先预览将要执行的操作（不实际改动）
./scripts/install-skills.sh --target all --dry-run
```

选项：

| 选项 | 说明 |
|------|------|
| `-t, --target <name>` | 预设目标：`claude` / `codex` / `cursor` / `workbuddy` / `agents` / `all` |
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
| WorkBuddy | `~/.workbuddy/skills/` | `~/.workbuddy/commands/` |
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

## 数据前置：通达信 + 同花顺问财（两项必需）

四个 skill 启动时都会先做双 Token 预检。只检查是否已配置，不应显示 Token 值；修改 shell profile 或 MCP 配置后，需要重启 / 重新加载 Agent。

### 1. 通达信官方 MCP

通达信 API Key 获取路径：

1. 打开[通达信官网](https://www.tdx.com.cn)，进入 `AI平台` → `通达信MCP`。
2. 购买后进入 `我的订单`。
3. 在会员中心进入 `API Key管理` → `创建API Key`。
4. 创建后点 `详情` 复制 Key。

本仓库统一把 Key 存为 `TDX_API_KEY`；这是本仓库的环境变量命名约定。官方 MCP 实际使用 `tdx-api-key` 请求头：

```bash
export TDX_API_KEY="你的_通达信_API_KEY"
```

官方 MCP 地址与鉴权核心配置：

```text
URL: https://mcp.tdx.com.cn:3001/mcp
Header: tdx-api-key: <TDX_API_KEY>
```

Codex 可在 `~/.codex/config.toml` 中使用环境变量请求头，避免硬编码：

```toml
[mcp_servers.tdxOfficial]
url = "https://mcp.tdx.com.cn:3001/mcp"
env_http_headers = { "tdx-api-key" = "TDX_API_KEY" }
```

Claude Code / Cursor 等使用 JSON MCP 配置时，采用其支持的环境变量插值语法；常见核心形式为：

```json
{
  "mcpServers": {
    "tdxOfficial": {
      "url": "https://mcp.tdx.com.cn:3001/mcp",
      "headers": {
        "tdx-api-key": "${TDX_API_KEY}"
      }
    }
  }
}
```

> 不要把本地连接公开行情服务器、无需 API Key 的第三方 `tdx-mcp` 误当成这里的官方通达信 MCP。

### 2. 同花顺问财 CLI、公告搜索与 Token

先检查 Iwencai SkillHub CLI：

```bash
command -v iwencai-skillhub-cli
```

若未安装，使用问财官方安装入口 [`download_and_install.sh`](https://www.iwencai.com/skillhub/static/0.0.4/download_and_install.sh)，仅安装 CLI。建议先下载到临时目录并审阅后执行；若 `0.0.4` 下载器出现内部安装脚本文件名不匹配，只从它声明的同一问财官方 ZIP 取包，审阅并执行包内 `iwencai-install.sh`，不要切换到第三方来源。

CLI 就绪后，为目标 Agent 安装公告搜索 skill，例如 Codex：

```bash
iwencai-skillhub-cli --dir ~/.codex/skills install announcement-search
```

到[同花顺问财 SkillHub](https://www.iwencai.com/skillhub)登录，点击任意技能，在安装提示的 `Agent用户` 部分复制 API Key。随后在 shell profile 中配置：

```bash
export IWENCAI_BASE_URL="https://openapi.iwencai.com"
export IWENCAI_API_KEY="你的_IWENCAI_API_KEY"
```

### 3. 其他问财数据 Skills

推荐组合：

| Skill | 用途 | 结论 |
|-----|------|------|
| `hithink-market-query` | 个股 / ETF / 指数行情、涨跌幅、成交量、资金流、技术指标 | 个股与指数默认入口 |
| `hithink-industry-query` | 行业估值、盈利、财务、行情、排名 | 行业层数据默认入口 |
| `hithink-sector-selector` | 板块筛选、资金流、涨跌幅、估值 | 板块和主题环境默认入口 |
| `hithink-hkstock-selector` | 港股筛选、港股行情与财务类条件组合 | 港股默认入口 |

按需继续安装以上 skills。例如在 Codex：

```bash
iwencai-skillhub-cli --dir ~/.codex/skills install hithink-market-query
iwencai-skillhub-cli --dir ~/.codex/skills install hithink-industry-query
iwencai-skillhub-cli --dir ~/.codex/skills install hithink-sector-selector
iwencai-skillhub-cli --dir ~/.codex/skills install hithink-hkstock-selector
```

工具清单、问句改写规则与数据时效校验见 [`market-data-guide.md`](skills/价值投资/references/market-data-guide.md)。
