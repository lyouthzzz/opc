# 金融数据 MCP 工具使用手册（Tushare + 通达信）

本手册记录「市场现状分析」环节所使用的金融数据 MCP。价值投资 skill 在完成生意本质、五维度定性分析后，用这些工具补充**实时市场数据**（最近股价、K 线、年报/财报三大表、财务指标、估值、分红、股东、公告/研报、资金流、宏观与国债收益率），使 right price 判断落到可验证的数据上。

默认选择：优先用 `tdx` 取通达信数据；`tdx` 没有、失败、权限不足或字段不够时，再用 `tushareMcp` 补充。不要为了单个工具错误阻塞完整分析。

---

## 一、MCP 连接与前置说明

### 1.1 选型

| MCP | 适合数据 | 不适合数据 | 使用策略 |
|-----|----------|------------|----------|
| `tdx` | A 股当前价、盘口、竞价、板块、技术指标、可用 F10/财务数据 | 港美股财报、宏观、完整公告、部分长期估值序列 | 默认优先；先查它 |
| `tushareMcp` | 日线、估值、财报三大表、财务指标、公告、研报、宏观 | 高频盘口、实时竞价 | 补充源；`tdx` 不足时使用 |
| 通达信官方 / OpenClaw 插件 | 官方 Token 下的 F10、智能选股、更多通达信数据 | 无 Token 的通用部署 | 有官方授权时再接 |

免费 `tdx` MCP 推荐配置：

```json
{
  "mcpServers": {
    "tdx": {
      "command": "uvx",
      "args": ["--from", "tdx-mcp", "tdx-mcp"]
    }
  }
}
```

`tdx` 常用约定：沪市 `market=1`，深市 `market=0`，北交所通常为 `market=2`；代码用纯数字，如 `600519`，不是 `600519.SH`。

### 1.2 Tushare MCP

- **MCP 名称**：`tushareMcp`
- **底层实现**：Tushare 兼容远程 MCP Server（HTTP / SSE，token 在 URL 中）
- **Cursor 配置**（`~/.cursor/mcp.json`）：

```json
{
  "mcpServers": {
    "tushareMcp": {
      "url": "https://ts.gyzcloud.top/mcp/token=你的_Tushare_Token"
    }
  }
}
```

- **远程服务**：无需本地安装/进程，配置后重启 Cursor 即可用。
- **Token**：已内置于 URL；到期或套餐变化时更新 Token。

### 1.3 Tushare 通用调用约定

- **每个工具 = 一个 Tushare 接口**，参数、字段与 [Tushare 官方文档](https://tushare.pro/document/2) 完全一致。
- **常用参数**：
  - `ts_code`：证券代码（A 股 `600519.SH`/`000001.SZ`；港股 `00700.HK`；美股见 `us_basic`）
  - `period`：报告期 `YYYYMMDD`——年报 `20241231`、半年报 `20240630`、一季报 `20240331`、三季报 `20240930`
  - `start_date` / `end_date` / `trade_date`：日期，`YYYYMMDD`（**例外**：`news` 用 `YYYY-MM-DD HH:MM:SS`）
  - `fields`：字符串数组，指定返回字段以精简输出（不传返回默认字段）
- **权限门槛（重要）**：部分接口可能受套餐/权限限制，此时降级跳过并显式标注。
  - **基础常用**：`daily`（行情）、`daily_basic`（PE/PB/市值/股息率）、`stock_basic`、`dividend`（分红）、`index_daily`（指数）等。
  - **可能受限**：`income`/`balancesheet`/`cashflow`/`fina_indicator`（**财报三大表与财务指标**）、`top10_holders`（股东）、`anns_d`（公告）、`hk_income` 等**港股/美股财报**、`yc_cb`（国债收益率）等。
- **本 MCP 无「名称→代码」模糊搜索工具**：先用 `stock_basic`（A 股，可传 `name`）/ `hk_basic` / `us_basic` 确定 `ts_code`，或使用已知代码。

---

## 二、数据时效性校验（必做，先于一切拉数）

价值投资 skill 依赖**当前**市场与财报事实。以下流程对应 SKILL 的「第零步」，必须在调用行情/财报接口之前完成。

### 2.1 确立三个时间锚点

```
分析基准日 = 本次分析执行的日历日（如 20260703）

最近交易日 = trade_cal(
  exchange="SSE",
  start_date=分析基准日往前 10 日,
  end_date=分析基准日,
  is_open=1
) → 取 cal_date 最大值

最新报告期 = 按优先级：
  1. disclosure_date(ts_code, end_date=分析基准日) → 取已披露的最大报告期 end_date
  2. 若无：fina_indicator(ts_code) 或 income(ts_code) → 取返回中最大 period/end_date
  3. 若有 express/forecast 且 period 新于上一步 → 以快报/预告 period 为准（标注「未经审计」）
```

**禁止**：在未执行上述查询前，假设「最新年报 = 20241231」或复用历史对话/知识库中的股价与财务数字。

### 2.2 按数据类型的时效要求

| 数据类型 | 关键时间字段 | 合格标准 | 不合格时 |
|----------|--------------|----------|----------|
| 日线行情 | `trade_date` | = 最近交易日 | 将 `end_date` 设为最近交易日重查；仍滞后则标注「行情数据源滞后」 |
| 每日估值 | `trade_date` | = 最近交易日 | 同左 |
| 财务指标/三大表 | `period` / `end_date` | = 最新报告期 | 查 `express`/`forecast`/`anns_d`；仅旧报告期则标注「待披露新报告期」 |
| 公告 | `ann_date` | 近 90 天内重大公告 | 扩大 `start_date` 或说明「近期无重大公告」 |
| 研报/一致预期 | `report_date` | 取最新一条并注明日期 | 过期研报标注「预期可能已失效」 |
| 指数/宏观 | `trade_date`/`date` | 不晚于最近交易日超过 5 日 | 用最近可用日并注明 |

### 2.3 单次 MCP 返回后的校验清单

每次工具返回后，在脑中（或草稿中）核对：

- [ ] 返回行中最大 `trade_date`/`period`/`ann_date` 是否符合 2.2 合格标准？
- [ ] 若接口返回多行，是否误用了非最新一行？
- [ ] 若 `fields` 裁剪导致无日期字段，是否补查日期或换带日期的接口？

### 2.4 标准锚点查询示例

```
# 1. 最近交易日（A 股以上交所日历为准）
trade_cal exchange="SSE" start_date="20260620" end_date="20260703" is_open="1"

# 2. 最新报告期（以 600519.SH 为例）
disclosure_date ts_code="600519.SH" end_date="20260703"
# 备选：fina_indicator ts_code="600519.SH" → 看最大 end_date

# 3. 用锚点拉行情（禁止省略 end_date/trade_date）
daily         ts_code="600519.SH" start_date="20260601" end_date="<最近交易日>"
daily_basic   ts_code="600519.SH" trade_date="<最近交易日>"
income        ts_code="600519.SH" period="<最新报告期>"
```

### 2.5 数据时效声明（写入市场现状快照开头）

```
数据时效：分析基准日 YYYY-MM-DD | 行情截止 YYYYMMDD | 财报报告期 YYYYMMDD | MCP 拉取 YYYY-MM-DD HH:MM
```

知识库 `references/companies/` 中的定性理解**不能**替代本节实时数据；加载知识库时对比其 `数据截止` 字段与最新报告期，滞后则提示用户。

---

## 三、基础与代码

| 工具 | 用途 | 关键参数 |
|------|------|----------|
| `stock_basic` | A 股列表/基本信息（定 `ts_code`、行业、上市日期） | `name`、`market`、`exchange`、`list_status`（默认 L） |
| `hk_basic` | 港股列表 | — |
| `us_basic` | 美股列表 | — |
| `namechange` | 股票曾用名 | `ts_code` |
| `trade_cal` | 交易日历（定最近交易日） | `exchange`、`start_date`、`end_date` |
| `disclosure_date` | 财报披露计划日期 | `ts_code`、`end_date` |
| `stock_company` | 上市公司基本信息 | `ts_code`、`exchange` |

---

## 四、行情与估值（股价现状）

| 工具 | 用途 | 关键参数 |
|------|------|----------|
| ⭐`daily` | A 股日线行情 | `ts_code`、`trade_date`、`start_date`、`end_date` |
| `weekly` / `monthly` | A 股周/月线（判断股价历史位置） | `ts_code`、`start_date`、`end_date` |
| ⭐`daily_basic` | A 股每日指标：**PE、PB、换手率、总市值、股息率** | `ts_code`（或 `trade_date`）、`start_date`、`end_date` |
| `adj_factor` | 复权因子（计算前/后复权行情） | `ts_code`、`trade_date` |
| `hk_daily` / `hk_daily_adj` | 港股日线 / 复权行情 | `ts_code`、`start_date`、`end_date` |
| `us_daily` / `us_daily_adj` | 美股日线 / 复权行情 | `ts_code`、`start_date`、`end_date` |
| `index_daily` | 指数日线（大盘环境） | `ts_code`（如 `000001.SH`）、`start_date`、`end_date` |
| ⭐`index_dailybasic` | 大盘指数每日指标（指数 PE/PB） | `ts_code`、`trade_date`、`start_date`、`end_date` |
| `index_basic` | 指数基本信息 | `market`、`ts_code` |

> 最新价：取最近交易日的 `daily`/`hk_daily`/`us_daily`（可先用 `trade_cal` 定最近交易日）。

---

## 五、A 股财务（年报/财报，核心 ⭐）

| 工具 | 内容 | 关键参数 |
|------|------|----------|
| ⭐`income` | 利润表（营收/成本/毛利/净利/EPS） | `ts_code`*、`period`、`start_date`/`end_date`（公告日）、`report_type` |
| ⭐`balancesheet` | 资产负债表 | `ts_code`*、`period`、`report_type` |
| ⭐`cashflow` | 现金流量表（经营/投资/筹资，FCF 推导） | `ts_code`*、`period`、`report_type` |
| ⭐`fina_indicator` | 财务指标（ROE、毛利率、净利率、偿债/营运/成长） | `ts_code`*、`period`、`start_date`/`end_date` |
| `forecast` | 业绩预告 | `ts_code`、`period`、`type`（预增/预减…） |
| `express` | 业绩快报 | `ts_code`、`period` |
| ⭐`dividend` | 分红送股 | `ts_code`、`ann_date`、`ex_date` |
| `fina_mainbz` | 主营业务构成 | `ts_code`*、`period`、`type`（`P` 产品 / `D` 地区 / `I` 行业） |
| `fina_audit` | 财务审计意见 | `ts_code`、`period` |

**典型调用（`period`/`trade_date` 须来自第二节锚点，勿写死年份）：**
```
# 最新报告期三大表（period 由 disclosure_date / fina_indicator 确定）
income        ts_code="600519.SH" period="<最新报告期>"
balancesheet  ts_code="600519.SH" period="<最新报告期>"
cashflow      ts_code="600519.SH" period="<最新报告期>"
# 近 3 年财务指标
fina_indicator ts_code="600519.SH" start_date="<3年前>" end_date="<最新报告期对应公告日或分析基准日>"
# 当前估值
daily_basic   ts_code="600519.SH" trade_date="<最近交易日>"
```

---

## 六、股东与治理

| 工具 | 内容 | 关键参数 |
|------|------|----------|
| `top10_holders` | 前十大股东 | `ts_code`*、`period` |
| `top10_floatholders` | 前十大流通股东 | `ts_code`*、`period` |
| `stk_holdernumber` | 股东户数 | `ts_code`、`enddate`、`start_date`/`end_date` |
| `stk_holdertrade` | 股东增减持 | `ts_code`、`ann_date` |
| `stk_managers` | 管理层 | `ts_code`、`ann_date` |
| `stk_rewards` | 管理层薪酬与持股 | `ts_code` |
| `repurchase` | 股票回购 | `ts_code`、`ann_date` |
| `pledge_stat` / `pledge_detail` | 股权质押统计/明细 | `ts_code` |
| `share_float` | 限售股解禁 | `ts_code`、`ann_date` |

---

## 七、港股 / 美股财务

**港股**（`ts_code` 如 `09992.HK`、`00700.HK`）：

| 工具 | 内容 |
|------|------|
| `hk_income` | 利润表（参数：`ts_code`*、`period`、`start_date`/`end_date`、`ind_name`） |
| `hk_balancesheet` | 资产负债表 |
| `hk_cashflow` | 现金流量表 |
| `hk_fina_indicator` | 财务指标 |

**美股**（`ts_code` 参考 `us_basic`）：

| 工具 | 内容 |
|------|------|
| `us_income` | 利润表（参数：`ts_code`*、`period`、`report_type` Q1/Q2/Q3/Q4、`ind_name`） |
| `us_balancesheet` | 资产负债表 |
| `us_cashflow` | 现金流量表 |
| `us_fina_indicator` | 财务指标 |

> 港股财务是分析泡泡玛特(09992.HK)等港股标的的关键；港股估值指标（PE/PB）Tushare 无 A 股式 `daily_basic`，需据财报与市值自算。

---

## 八、公告 / 研报 / 一致预期（事件与预期）

| 工具 | 用途 | 关键参数 |
|------|------|----------|
| ⭐`anns_d` | 上市公司公告（含 PDF 下载 URL） | `ts_code`、`ann_date`、`start_date`/`end_date` |
| `research_report` | 券商研报 | `ts_code`、`ind_name`、`trade_date`、`report_type` |
| ⭐`report_rc` | 券商盈利预测（一致预期/目标价） | `ts_code`、`report_date`、`start_date`/`end_date` |
| `news` | 新闻快讯 | `src`*、`start_date`*、`end_date`*（`YYYY-MM-DD HH:MM:SS`） |
| `major_news` | 长篇通讯 | `start_date`、`end_date` |
| `irm_qa_sh` / `irm_qa_sz` | 上证 e 互动 / 深证互动易问答 | `ts_code`、`trade_date` |
| `broker_recommend` | 券商月度金股 | `month` |

> `report_rc`（盈利预测/目标价）可为 DCF 假设与安全边际提供机构一致预期参照。

---

## 九、资金流向（辅助情绪，可能受限）

| 工具 | 说明 |
|------|------|
| `moneyflow` | 个股资金流向（`ts_code`、`trade_date`、`start_date`/`end_date`） |
| `moneyflow_dc` / `moneyflow_ths` | 东财 / 同花顺个股资金流 |
| `moneyflow_mkt_dc` | 大盘资金流向 |
| `moneyflow_ind_dc` | 板块资金流向 |
| `hk_hold` / `hsgt_top10` / `ggt_top10` | 沪深股通持股 / 十大成交股 |

> 仅作短期情绪参考，非价值判断依据；权限不足时跳过。

---

## 十、宏观（DCF 折现率与周期背景）

| 工具 | 用途 | 关键参数 |
|------|------|----------|
| ⭐`yc_cb` | 中债国债收益率曲线（**无风险利率 → DCF 折现率**） | `ts_code`（`1001.CB` 国债）、`curve_type`（0 到期/1 即期）、`curve_term`、`trade_date` |
| `shibor` / `shibor_lpr` | Shibor / LPR 利率 | `date`、`start_date`/`end_date` |
| `cn_gdp` | GDP | `q`/`start_q`/`end_q`（如 `2024Q1`） |
| `cn_cpi` / `cn_ppi` | CPI / PPI | `m`/`start_m`/`end_m` |
| `cn_m` | 货币供应量 | `m` |
| `cn_pmi` | PMI | `m` |
| `sf_month` | 社融增量（月度） | `m` |
| `us_tycr` / `us_tltr` | 美国国债收益率（美股 DCF） | `date` |

---

## 十一、标准查询模式：市场现状分析

价值投资 skill 在定性框架之外，用以下固定顺序补充市场现状（对应 SKILL 的「市场现状分析」步骤）。**先完成第二节锚点查询**，再按序拉数；**日期用 `YYYYMMDD`**。

### 模式一：A 股个股市场现状（推荐）

```
0. 【锚点】trade_cal → 最近交易日；disclosure_date / fina_indicator → 最新报告期
1. index_daily(000001.SH, end_date=最近交易日) + index_dailybasic(trade_date=最近交易日) → 大盘环境与估值
2. daily(ts_code, end_date=最近交易日) → 最新股价/涨跌；monthly(ts_code, 5年至最近交易日) → 股价历史位置
3. daily_basic(ts_code, trade_date=最近交易日) → 当前 PE/PB/换手/市值/股息率
4. fina_indicator(ts_code, 近3年至最新报告期) → ROE/毛利率/净利率/成长
5. income + cashflow + balancesheet(ts_code, period=最新报告期) → 年报三大表
6. dividend / fina_mainbz / forecast|express / top10_holders / stk_holdernumber → 分红/主营/指引/股东
7. anns_d(ts_code, 近90日) → 年报及重大公告；report_rc(ts_code) → 机构盈利预测/目标价
8.（DCF 需要时）yc_cb(1001.CB, trade_date=最近交易日) → 无风险利率
→ 校验每条返回的 trade_date/period/ann_date → 汇总为「市场现状快照」（含数据时效声明）
```

### 模式二：港股个股市场现状

```
0. 【锚点】trade_cal 或 hk_daily 末行 → 最近交易日；hk_fina_indicator → 最新报告期
1. hk_daily(ts_code, end_date=最近交易日) → 行情；月度可据日线聚合
2. hk_income + hk_balancesheet + hk_cashflow + hk_fina_indicator(ts_code, period=最新报告期) → 财报
3. anns_d / research_report / report_rc → 公告/研报/预期（注明 ann_date/report_date）
（港股无 A 股式 daily_basic，PE/PB 需据财报与市值自算）
```

### 模式三：美股个股市场现状

```
0. 【锚点】us_daily 末行 → 最近交易日；us_fina_indicator → 最新报告期 + report_type
1. us_daily(ts_code, end_date=最近交易日) → 行情
2. us_income + us_balancesheet + us_cashflow + us_fina_indicator(ts_code, period=最新报告期, report_type) → 财报
3.（DCF）us_tycr(date=最近可用日) → 美债无风险利率
```

---

## 十二、错误处理与数据边界

| 情况 | 处理方式 |
|------|----------|
| 返回 `trade_date` 早于最近交易日 >3 日 | 检查 `end_date` 是否遗漏；重查后仍滞后则标注「行情滞后」 |
| `period` 早于预期最新报告期 | 查 `disclosure_date`/`express`/`forecast`；确认是否处于披露空窗期 |
| 复用对话/知识库中的旧数字 | **禁止**；必须重新 MCP 拉数并校验时效 |
| Token 失效 / 无权限 | 更新 `~/.cursor/mcp.json` 中 URL 的 token 并重启 Cursor |
| 返回权限/套餐不足 | 该接口超出当前套餐或权限；降级跳过并标注 |
| 港股/美股无 `daily_basic` | 估值指标据财报与市值自算 |
| 需要「名称→代码」 | 用 `stock_basic`/`hk_basic`/`us_basic` 先定 `ts_code` |
| 日期格式 | 一律 `YYYYMMDD`（`news` 例外为 `YYYY-MM-DD HH:MM:SS`）；报告期用 `period` |
| 单次返回条数上限 | 部分接口有条数限制（如 `fina_indicator` 每次 ~100 条），按日期分段多次请求 |
| 数据源冲突 | 与公司年报原文交叉核对，安全边际取更保守解读 |

> ⚠️ 所有通过 Tushare MCP 获取的数据仅供市场现状参考，价值判断以「看懂生意 + 五维度 + 四种好运」框架为主，MCP 数据用于验证 right price 与安全边际，不替代定性分析，也不构成投资建议。
