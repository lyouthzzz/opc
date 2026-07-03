---
name: /value-assessor
id: value-assessor
category: Investing
description: 触发「value-assessor」skill，做自由现金流 DCF 估值、护城河评估与多模型交叉验证
argument-hint: [股票代码，如 600519.SH / 0700.HK / AAPL]
---

# 价值评估师 (/value-assessor)

触发 `value-assessor` skill，对 `$ARGUMENTS` 指定的股票做格雷厄姆-巴菲特式价值评估。

## 必须做的事

1. **立即读取并遵循** `value-assessor` skill 的 `SKILL.md`：
   - 全局：`~/.claude/skills/value-assessor/SKILL.md`（或对应 Agent 的 skills 目录）
2. 以**未来自由现金流**为核心，按 skill 的五阶段流程分析 `$ARGUMENTS`：
   现金流认知 → 现金流确定性（护城河）→ DCF 核心估值 → 多模型交叉验证 → 投资结论。
3. 通过所配置的通达信/金融数据 MCP 拉取财务、行情与研报数据；数据缺失时降级并标注。
4. 输出：未来 FCF 分析 + DCF 估值区间与敏感性矩阵 + 护城河评级 + 多模型评分 + 安全边际与颜色评级。

## 使用方法

```text
/value-assessor 600519.SH
/value-assessor 0700.HK
/value-assessor AAPL
```

## 不要做的事

- 不构成投资建议；所有 DCF 预测均基于假设。
- 无法理解商业模式的标的拒绝评估（能力圈原则）。
- 不支持债券、基金、ETF、加密货币等非股票标的。
