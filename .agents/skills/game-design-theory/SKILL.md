---
name: game-design-theory
description: "为《狐狸骑士》进行受约束的游戏设计发散，使用 MDA、玩家动机、系统后果和体验目标提出彼此有实质差异的候选方案。仅在用户显式调用 `$game-design-theory`，或用户同意 Architecture Agent 提出的专项发散建议时使用；不得自动触发，不得收束决策、修改正式文档或形成开发需求。"
---

# Game Design Theory

## FoxKnight authority and invocation

Use this skill only after the user explicitly invokes it, or after the user accepts an Architecture Agent recommendation for a focused divergence pass. Expand the option space; never choose the final design.

Before use, read the root `AGENTS.md`, `agents/architect.md`, and the relevant parts of `docs/GDD.md` and `docs/DecisionLog.md`. Read `docs/TDD.md` only when current implementation cost or technical boundaries matter.

For each request:

1. Restate the experience problem and expose unproven assumptions.
2. Produce 3–5 materially different candidates rather than cosmetic or parameter variants.
3. For each candidate, state the intended player experience, causal chain, strongest failure mode, scope cost, and a minimal reversible test.
4. Compare real tradeoffs without ranking or approving candidates.
5. End with: all outputs are unresolved candidates, not GDD, TDD, or implementation requirements.

Treat MDA, Bartle types, flow, reward theory, and industry conventions as ideation lenses only, never as project evidence. Do not default to progression, rewards, bosses, multiplayer, level systems, or other out-of-scope features. Do not edit project documents, code, or scenes, and do not hand candidates directly to the Coding Agent. Architecture Agent must independently critique and converge; the user makes the final decision.

## The MDA Framework

```
┌─────────────────────────────────────────────────────────────┐
│                    MDA FRAMEWORK                             │
├─────────────────────────────────────────────────────────────┤
│  MECHANICS (Rules):                                          │
│  → Player actions, constraints, state changes               │
│  → Example: Jump has height limit, costs stamina            │
│                              ↓                               │
│  DYNAMICS (Behavior):                                        │
│  → Emergent gameplay from mechanic interactions             │
│  → Example: Wall-jump combos, speedrun routes               │
│                              ↓                               │
│  AESTHETICS (Experience):                                    │
│  → Emotional responses: Fun, tension, achievement           │
│  → Example: Flow state, satisfaction, immersion             │
└─────────────────────────────────────────────────────────────┘
```

## Core Game Loop

```
┌─────────────────────────────────────────────────────────────┐
│                    ENGAGEMENT LOOP                           │
├─────────────────────────────────────────────────────────────┤
│  1. INPUT    → Player takes action                          │
│  2. PROCESS  → Game calculates results                      │
│  3. FEEDBACK → Immediate visual/audio response              │
│  4. REWARD   → Progress, points, unlocks                    │
│  5. REPEAT   → Loop invites next iteration                  │
│                                                              │
│  Loop Quality Criteria:                                      │
│  ✓ Fast feedback (< 100ms)                                  │
│  ✓ Clear causation                                          │
│  ✓ Rewarding outcomes                                       │
│  ✓ Compelling repetition                                    │
└─────────────────────────────────────────────────────────────┘
```

## Flow Channel (Csikszentmihalyi)

```
     Anxiety
         ↑
  Hard   │     ████
         │   ██████   ← FLOW CHANNEL
Skill    │ ████████      (Optimal Engagement)
Level    │████████████
  Easy   │██████████████
         └──────────────────→
           Low    Challenge    High

TARGET: Match challenge to player skill
```

## Player Psychology

### Bartle's Player Types

| Type | Motivation | Design For |
|------|------------|------------|
| Achiever | Goals, progression | Achievements, levels |
| Explorer | Discovery, secrets | Hidden content, lore |
| Socializer | Community | Chat, guilds, co-op |
| Killer | Competition | PvP, leaderboards |

### Motivation Drivers

```
SELF-DETERMINATION THEORY:
┌─────────────────────────────────────────────────────────────┐
│  AUTONOMY:   Choice and control over actions               │
│  COMPETENCE: Mastery and skill demonstration               │
│  RELATEDNESS: Connection to characters/community           │
└─────────────────────────────────────────────────────────────┘
```

## Reward Systems

```
REWARD TYPES:
┌─────────────────────────────────────────────────────────────┐
│  INTRINSIC (Internal):                                       │
│  • Achievement satisfaction                                 │
│  • Creative expression                                      │
│  • Curiosity fulfillment                                    │
│  • Skill mastery                                            │
├─────────────────────────────────────────────────────────────┤
│  EXTRINSIC (External):                                       │
│  • Points, scores                                           │
│  • Unlocks, cosmetics                                       │
│  • Leaderboard position                                     │
│  • Currency rewards                                         │
└─────────────────────────────────────────────────────────────┘

REWARD SCHEDULING:
• Fixed Ratio: Every N actions (predictable)
• Variable Ratio: Random timing (engaging but ethical concerns)
• Fixed Interval: Every N seconds
• Milestone: At progression checkpoints
```

## Balance Principles

| Aspect | Goal | Technique |
|--------|------|-----------|
| Mechanical | All options viable | Counter-play, trade-offs |
| Economic | Meaningful scarcity | Sinks and faucets |
| Difficulty | Appropriate challenge | Dynamic scaling |
| Competitive | Fair play | Mirror balance, no dominance |

## 🔧 Troubleshooting

```
┌─────────────────────────────────────────────────────────────┐
│ PROBLEM: Players find game boring                           │
├─────────────────────────────────────────────────────────────┤
│ ROOT CAUSES:                                                 │
│ • Challenge too easy (below flow channel)                   │
│ • No clear goals or progression                             │
│ • Feedback loop too slow                                    │
├─────────────────────────────────────────────────────────────┤
│ SOLUTIONS:                                                   │
│ → Increase challenge curve                                  │
│ → Add clear milestones and rewards                          │
│ → Speed up core loop, add variety                           │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ PROBLEM: Players frustrated / quitting                      │
├─────────────────────────────────────────────────────────────┤
│ ROOT CAUSES:                                                 │
│ • Difficulty spike (above flow channel)                     │
│ • Unclear mechanics or feedback                             │
│ • Unfair or random feeling deaths                           │
├─────────────────────────────────────────────────────────────┤
│ SOLUTIONS:                                                   │
│ → Smooth difficulty curve                                   │
│ → Improve tutorial and feedback                             │
│ → Make deaths feel fair and educational                     │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ PROBLEM: Dominant strategy / no variety                     │
├─────────────────────────────────────────────────────────────┤
│ SOLUTIONS:                                                   │
│ → Add counter-play to dominant options                      │
│ → Buff underused alternatives                               │
│ → Create situational advantages                             │
└─────────────────────────────────────────────────────────────┘
```

## Design Checklist

```
PRE-PRODUCTION:
□ Target audience defined
□ Core loop documented
□ Unique selling point clear
□ Reference games analyzed

PRODUCTION:
□ Mechanics serve aesthetics
□ Feedback loops verified
□ Balance spreadsheets maintained
□ Playtest schedule in place

POLISH:
□ First-time user experience tested
□ Difficulty curve validated
□ Reward timing optimized
□ Edge cases handled
```

---

**Use this skill**: When designing game systems, understanding player psychology, or balancing gameplay.
