# opc — Agent Skills 仓库

本仓库收录可复用的 **Agent Skill**（基于 `SKILL.md` 的技能包）与配套的 **`/command` 斜杠命令**，供 Cursor、Claude Code、Codex、WorkBuddy 等支持 skill 的 AI Agent 加载使用。

## 已收录 Skills

| Skill | 说明 | 外部依赖 |
|-------|------|----------|
| [`价值投资`](skills/价值投资/SKILL.md) | 基于段永平/巴菲特理念的企业价值分析模型（right business/people/price 三要素 + 五维度 + 四种好运），并补充市场现状（股价/估值/财报口径/行业板块/资金流） | 通达信与问财均为可选增强；可跳过并使用 Agent 默认数据与检索 |
| [`股票魔法师`](skills/股票魔法师/SKILL.md) | 基于 SEPA / Mark Minervini 方法的中短线交易分析，判断趋势模板、VCP、中枢点、止损、仓位与卖出信号 | 通达信与问财均可跳过；缺少实时字段时降级为“数据不足” |
| [`股票比较`](skills/股票比较/SKILL.md) | 综合 `价值投资` 与 `股票魔法师`，对多只股票做机会成本排序，并输出买入、持有、减仓、卖出或换仓计划 | 同上 |
| [`行业分析`](skills/行业分析/SKILL.md) | A 股行业/板块机会挖掘：行业轮动、宏观到行业映射、产业链解读、近30天催化梳理与行业内个股筛选 | 通达信与问财均为可选增强；默认检索可独立运行 |

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
│   ├── configure-data-tokens.sh  # macOS / Linux Token 安全配置向导
│   ├── configure-data-tokens.ps1 # Windows 原生隐藏输入向导
│   ├── install-iwencai-cli.ps1   # Windows 问财官方 CLI 安装器
│   ├── install-skills.sh         # macOS / Linux 安装 skills + commands
│   └── install-skills.ps1        # Windows 安装 skills + commands
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
你是负责安装 Agent Skill、/command 命令及其可选数据增强的助手。用户是非开发者：整个过程使用普通语言和系统交互界面，不向用户展示终端命令、脚本、配置文件或代码，除非用户明确要求。请从 GitHub 仓库 https://github.com/lyouthzzz/opc 完成安装：

0. 先识别操作系统，再在后台获取源码：
   - 若当前工作区已是该仓库（含 skills/ 与 commands/），直接使用当前目录。
   - 否则优先浅克隆到系统临时目录；Windows 使用当前用户的 TEMP 目录，macOS / Linux 使用 /tmp。若无 git，则只从 GitHub 官方仓库下载归档并用系统原生能力解压。
   - 不要向用户展示下载、解压或删除临时目录的命令；安装结束后用普通语言询问是否清理临时文件。

1. 确认目标 Agent（可多选；不确定就先问我）及其目录：
   - Claude Code → skills: ~/.claude/skills/        commands: ~/.claude/commands/
   - Codex      → skills: ~/.codex/skills/          commands: ~/.codex/prompts/
   - Cursor     → skills: ~/.cursor/skills-cursor/   commands: ~/.cursor/commands/
   - WorkBuddy  → skills: ~/.workbuddy/skills/      commands: ~/.workbuddy/commands/
   - 通用/其它   → skills: ~/.agents/skills/          commands: ~/.agents/commands/
   Windows 中的 `~` 表示当前用户目录（即 `%USERPROFILE%`），不要要求用户手动换算路径。

2. 用普通用户友好的方式询问是否配置数据增强（必须展示选择，但允许分别跳过）：

   - 明确告诉用户：通达信和问财都是可选的，可单独配置、单独跳过或全部跳过；跳过后 skills 仍可使用 Agent 默认数据、网页检索和模型知识。不要用“必需”“不配置就不能用”等措辞施压。
   - Windows：由你在后台运行仓库的 `scripts/configure-data-tokens.ps1`。它会为两项数据源分别显示“安全保存 / Save”“跳过 / Skip”“取消 / Cancel”，并把已输入 Token 保存到当前用户环境变量。不要让用户打开 PowerShell 或执行命令。
   - macOS / Linux：由你在后台运行仓库的 `scripts/configure-data-tokens.sh`。macOS 为两项数据源分别提供系统“跳过”按钮；Linux 可直接按回车跳过。用户只需要选择、复制、粘贴和确认。
   - 若系统不支持该向导，改用当前 Agent / 操作系统提供的密码框、密钥管理页或隐藏输入控件。若没有任何安全输入能力，只用一句普通语言说明当前限制并暂停；不要向非开发者展示替代脚本或配置代码。
   - 只报告“已配置 / 已跳过 / 已取消”，不得输出 Token 值。macOS / Linux 修改 shell profile 前先备份；所有系统修改 MCP 配置前先备份。不得把 Token 写入项目文件、安装报告、日志、命令历史或 MCP 配置。已跳过不是错误，也不应反复提示。
   - 本仓库的 skills / commands 及用户已选择启用的问财 skills 出现同名冲突时，直接用本次安装来源覆盖，不询问、不展示 diff；可在后台自动备份，并在安装报告中说明。只有同名但指向不同服务的 MCP 配置属于例外，必须先确认，避免覆盖其他连接。

   A. 通达信（官方 MCP）：
   - 检查是否已有 `TDX_API_KEY` 及官方通达信 MCP。不要把无需 API Key、连接公开行情服务器的第三方 `tdx-mcp` 当成官方 MCP。
   - 若没有 Key，在向导中说明获取路径：`https://www.tdx.com.cn` → `AI平台` → `通达信MCP` → 购买后进入 `我的订单` → `会员中心` → `API Key管理` → `创建API Key` → `详情`，同时保留“跳过”。
   - 仅当用户选择配置时，才安全保存 `TDX_API_KEY` 并配置官方 MCP。Windows 保存到当前用户环境变量，macOS / Linux 保存到 shell profile。官方服务地址为 `https://mcp.tdx.com.cn:3001/mcp`，鉴权请求头为 `tdx-api-key`；在后台按目标 Agent 的原生格式完成配置，并从环境变量读取请求头。若已有同名但不同来源的 MCP，用普通语言说明后再确认，不能直接覆盖。
   - 若用户选择跳过，不写入占位变量，不新增或修改通达信 MCP，后续校验记为“已跳过”。

   B. 同花顺问财：
   - 先通过向导让用户选择配置或跳过。若选择跳过，不安装或升级 Iwencai SkillHub CLI、`announcement-search` 及其他问财 skills，不写入 `IWENCAI_BASE_URL` 或 `IWENCAI_API_KEY`；后续校验记为“已跳过”。
   - 仅当用户选择配置时，才检查 `iwencai-skillhub-cli` 是否已安装。Windows 若未安装，由你在后台运行仓库的 `scripts/install-iwencai-cli.ps1`；macOS / Linux 若未安装，仅使用官方入口 `https://www.iwencai.com/skillhub/static/0.0.4/download_and_install.sh`。只使用问财官方来源，不向用户展示排错命令。
   - CLI 就绪后，把 `announcement-search` 安装到每个目标 skills 目录；已存在且不同时直接用问财官方版本覆盖，可先自动备份，不再询问。
   - Token 获取路径：`https://www.iwencai.com/skillhub` → 登录 → 点击任意技能 → 安装提示的 `Agent用户` 部分。仅在用户选择配置后安全保存 `IWENCAI_BASE_URL=https://openapi.iwencai.com` 与 `IWENCAI_API_KEY`。

   C. 校验：只报告两项增强各自“已配置 / 已跳过 / 已取消”。只对用户选择配置的项目做连接与文件校验：通达信验证官方 MCP；问财验证环境变量及 `<目标skills目录>/announcement-search/SKILL.md`。不得显示任何 Token 内容。跳过时无需重启 Agent。

3. 安装本仓库 skills：Windows 优先由你在后台调用 `scripts/install-skills.ps1`，macOS / Linux 优先调用 `scripts/install-skills.sh`；两个脚本均按“不同则直接覆盖、相同则保持不动”执行。复制每个含 SKILL.md 的完整目录（包括 references/），保持目录名与结构不变。

4. 安装 commands：使用同一平台安装器复制 commands/*.md（Claude / Cursor 用 commands/，Codex 用 prompts/）。

5. 冲突处理：目标已存在同名 skill 或 command 且内容不同时，直接用仓库版本覆盖，不询问；可自动备份为 <name>.bak-opc-<时间>。内容相同则保持不动。安装报告列出更新与备份情况。

6. 校验：读取每个已安装 SKILL.md 与命令文件的 frontmatter，确认 name / description 存在；确认 references/ 已一并复制；与 GitHub 上仓库列出的 skill 名一致（价值投资、股票魔法师、股票比较、行业分析）；确认四个 skill 都包含“可选数据增强与降级策略”。

7. 输出安装报告：源码来源、装了哪些 skill 与命令、两个数据增强各自“已配置 / 已跳过 / 已取消”、仅在选择问财时报告 `announcement-search` 状态、仅在选择通达信时报告官方 MCP 状态、安装目录及覆盖/备份。禁止输出 Token 值。

要求：本仓库内容只做复制安装，不修改 skill/command 内容；外部改动仅限用户选择启用的数据增强。明确选择“跳过”不影响 skills 与 commands 安装完成，但报告中不能把对应增强写成已配置；选择“取消”则说明配置流程未完成。若用了临时目录，安装完成后询问是否删除。
```

安装后，重启 / 重新加载 Agent，即可：既能用触发词自动唤起 skill（如「帮我做一次价值投资」），也能用 `/价值投资`、`/股票魔法师` 主动调用。

普通用户在 Windows、macOS 和 Linux 上可以直接跳过全部数据增强；若选择配置，也只需要登录获取 Token、在隐藏输入框中粘贴、确认是否更新已有内容。其余步骤由 Agent 在后台完成。Windows 不需要 WSL、Git Bash，也不需要手动打开 PowerShell。

---

## 安装方式二：脚本安装（高级用户）

普通用户无需阅读或执行本节，直接使用上面的 Prompt 安装即可。若偏好命令行，仓库同时提供 macOS / Linux 与 Windows 原生脚本。

macOS / Linux 使用 [`scripts/install-skills.sh`](scripts/install-skills.sh)：

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

Windows 使用 [`scripts/install-skills.ps1`](scripts/install-skills.ps1)，默认采用复制安装，不要求管理员权限或 Windows 开发者模式：

```powershell
# 安装到 Codex
.\scripts\install-skills.ps1 -Target codex

# 安装到所有已知 Agent；冲突时直接覆盖并先备份
.\scripts\install-skills.ps1 -Target all

# 只安装命令 / 只安装 skills / 预览
.\scripts\install-skills.ps1 -Target cursor -CommandsOnly
.\scripts\install-skills.ps1 -Target codex -NoCommands
.\scripts\install-skills.ps1 -Target all -DryRun
```

选项：

| 选项 | 说明 |
|------|------|
| `-t, --target <name>` | 预设目标：`claude` / `codex` / `cursor` / `workbuddy` / `agents` / `all` |
| `-l, --link` | 用软链接代替复制（源仓库更新后免重装） |
| `-f, --force` | 直接覆盖已存在的不同内容（默认行为，保留用于兼容旧用法） |
| `--no-force` | 已存在且不同时跳过，不执行默认覆盖 |
| `-n, --dry-run` | 只打印将要执行的操作 |
| `--no-commands` | 只装 skills，不装 /command |
| `--commands-only` | 只装 /command，不装 skills |
| `DEST_DIR` | 自定义 skills 目录（仅装 skills；命令目录因 Agent 而异，故不装命令） |

**复制 vs 软链接**：日常使用推荐**复制**（稳定、可离线）；两种模式默认都会直接覆盖不同版本，相同内容保持不动。若你在持续修改本仓库的 skill/命令，可用 `--link` 让改动即时生效；用 `--no-force` 才会在冲突时跳过。

Windows 脚本对应参数为 `-Target`、`-Force`、`-NoForce`、`-DryRun`、`-NoCommands`、`-CommandsOnly`、`-Destination`。Windows 版本固定使用复制安装；冲突时默认直接覆盖并先备份原内容，不显示确认窗口。

---

## 各 Agent 目录参考

| Agent | skills 目录 | commands 目录 |
|-------|-------------|---------------|
| Claude Code | `~/.claude/skills/` | `~/.claude/commands/` |
| Codex | `~/.codex/skills/` | `~/.codex/prompts/` |
| Cursor | `~/.cursor/skills-cursor/` | `~/.cursor/commands/` |
| WorkBuddy | `~/.workbuddy/skills/` | `~/.workbuddy/commands/` |
| 通用/其它 | `~/.agents/skills/` | `~/.agents/commands/` |

Windows 上 `~` 就是 `%USERPROFILE%`。例如 Codex skills 默认位于 `%USERPROFILE%\.codex\skills\`。

---

## 验证与卸载

- **验证**：确认目标目录下出现 `<skill 名>/SKILL.md` 与 `commands/<命令>.md`，重启 Agent 后用触发词或 `/命令` 测试是否能唤起。
- **卸载**：删除对应的 skill 目录与命令文件即可，例如：

```bash
rm -rf ~/.claude/skills/价值投资
rm -f  ~/.claude/commands/价值投资.md
```

---

## 可选数据增强：通达信 + 同花顺问财

四个 skill 不要求 Token。已配置时优先使用通达信或问财的结构化数据；跳过时使用 Agent 可用的网页检索、用户提供的数据与模型已有知识。涉及无法核验的当前股价、财报或技术指标时会明确标注“未实时核验”或“数据不足”，不会编造精确数据。

普通用户应直接使用“安装方式一”，由 Agent 打开隐藏输入向导并按需选择“跳过”。Windows 向导只在选择配置时把变量保存到当前用户环境；macOS / Linux 向导也只在选择配置时备份并更新 shell profile。以下命令与配置仅供主动启用数据增强的高级用户排错。

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

macOS / Linux 可这样检查 Iwencai SkillHub CLI：

```bash
command -v iwencai-skillhub-cli
```

若未安装，使用问财官方安装入口 [`download_and_install.sh`](https://www.iwencai.com/skillhub/static/0.0.4/download_and_install.sh)，仅安装 CLI。建议先下载到临时目录并审阅后执行；若 `0.0.4` 下载器出现内部安装脚本文件名不匹配，只从它声明的同一问财官方 ZIP 取包，审阅并执行包内 `iwencai-install.sh`，不要切换到第三方来源。

Windows 若未安装，使用仓库的 [`scripts/install-iwencai-cli.ps1`](scripts/install-iwencai-cli.ps1)。它只访问问财官方 ZIP，安装前检查压缩包路径，不执行包内的 `.sh` 文件，并把启动器加入当前用户 PATH。需要 Python 3.8 或更高版本；不需要 WSL 或 Git Bash。

CLI 就绪后，为目标 Agent 安装公告搜索 skill，例如 Codex：

```bash
iwencai-skillhub-cli --dir ~/.codex/skills install announcement-search
```

Windows 的目标目录使用 `%USERPROFILE%\.codex\skills`；推荐仍让 Agent 在后台完成，不需要用户手动输入路径。

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
