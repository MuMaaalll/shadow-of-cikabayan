# docs/ — AI Agent Context Layer
## Shadow of Cikabayan | IPB University GKV Project

> **How to use this folder:**
> Paste the relevant `.md` file(s) into your AI chat context BEFORE asking questions.
> The more context you give, the more accurate and project-specific the answer.

---

## 📁 Folder Structure

```
docs/
├── README.md                        ← You are here
├── context/
│   └── PROJECT_OVERVIEW.md          ← 🔴 ALWAYS READ THIS FIRST
├── tasks/
│   ├── TASK_MELANDRI.md             ← Read if you're Melandri / asking about gameplay code
│   ├── TASK_IRFAN.md                ← Read if you're Irfan / asking about shaders & lighting
│   └── TASK_HIKMAL.md               ← Read if you're Hikmal / asking about assets & levels
├── technical/
│   ├── FSM_ARCHITECTURE.md          ← State machine diagrams & GDScript patterns
│   ├── SHADER_REFERENCE.md          ← All GLSL shader code & math explanation
│   └── COMBAT_LOGIC.md              ← Element matrix, damage formula, GDScript impl
└── workflow/
    └── GIT_WORKFLOW.md              ← Branch rules, file ownership, conflict resolution
```

---

## 🤖 Recommended Prompt Template

When starting a new AI session, paste this:

```
[Paste content of PROJECT_OVERVIEW.md]
[Paste content of your TASK_*.md file]
[Paste content of the relevant technical doc if needed]

My question: [your question here]
```

---

## 👥 Quick Reference — Who Owns What

| I want help with... | Read these docs |
|--------------------|-----------------|
| Player movement / combat code | `PROJECT_OVERVIEW` + `TASK_MELANDRI` + `FSM_ARCHITECTURE` |
| Shaders / lighting / particles | `PROJECT_OVERVIEW` + `TASK_IRFAN` + `SHADER_REFERENCE` |
| Sprites / tilemaps / scene layout | `PROJECT_OVERVIEW` + `TASK_HIKMAL` |
| Combat damage math | `PROJECT_OVERVIEW` + `COMBAT_LOGIC` |
| Git merge conflict | `GIT_WORKFLOW` |
| Academic report (LKP/SSR) | `PROJECT_OVERVIEW` + `FSM_ARCHITECTURE` + `SHADER_REFERENCE` |

---

## 📌 Key Project Rules (for AI agents)

1. **Engine:** Godot 4, GDScript only. Never suggest Unity or C# unless asked.
2. **No 3D:** This is a 2D top-down pixel art game. Never suggest 3D/spatial nodes.
3. **No scope creep:** 1 playable chapter only. No multiplayer, no open world.
4. **File ownership is sacred:** `.tscn` = Hikmal's. `.gd` = Melandri's. `.gdshader` = Irfan's.
5. **GKV requirements must always be met:** FSM, dynamic lighting, custom shader, particles.
