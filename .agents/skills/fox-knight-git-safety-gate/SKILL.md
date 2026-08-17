---
name: fox-knight-git-safety-gate
description: Audit FoxKnight files before Git commit, push, tag, GitHub publication, external playtest export, or release. Use when checking secrets, personal information, local paths, DOCX metadata, ignored artifacts, export filters, PCK contents, staged scope, or manual Git/GitHub Desktop steps. This skill reports gates and prepares an intentional scope; it never grants permission to commit, push, publish, rewrite history, or delete artifacts.
---

# FoxKnight Git Safety Gate

Run the project preflight before any Git write or external build delivery. Treat the gate as evidence, not authorization.

## Select a mode

- Use `Audit` before repository initialization or when reviewing general hygiene.
- Use `Commit` before staging is finalized or a commit is created.
- Use `Push` before adding or pushing a remote, publishing with GitHub Desktop, or pushing tags.
- Use `Export` before sending a playable build outside the project team.
- Use `Release` before attaching a build to a GitHub Release or other public distribution.

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .agents/skills/fox-knight-git-safety-gate/scripts/preflight.ps1 -Mode Audit
```

Replace `Audit` with the required mode. Read every `FAIL` and `WARN`; never expose a matched secret value in chat or logs.

## Enforce the gate

1. Read `AGENTS.md` and the relevant role instructions.
2. Run the selected preflight mode.
3. Stop on any `FAIL` and remediate it before proceeding.
4. Explain every remaining `WARN`; require the user to accept material privacy or portability risks.
5. Show the exact staged file list and `git diff --cached --stat` before a commit.
6. Request separate explicit authorization for `git commit` and for any remote write such as `push`, tag publication, repository publication, or release upload.
7. Never use `git add .`, `git commit -a`, force push, history rewriting, or destructive cleanup as a shortcut.
8. If a real credential was committed, rotate or revoke it before considering history repair.

## Keep the two control channels

- For agent-managed work, run the gate, present the proposed scope, and wait for explicit authorization at each external-write boundary.
- For user-managed work, follow [references/manual-git.md](references/manual-git.md). Do not take over the GitHub Desktop UI while the user is actively operating it.

## Project-specific boundaries

- Track source, formal documents, tests, agent rules, project Skills, `project.godot`, and portable `export_presets.cfg` settings.
- Keep `.godot/`, `build/`, `backups/`, machine-local export templates, logs, captures, temporary results, credentials, and private environment files out of Git.
- Treat exported PCK data as inspectable. Never bundle server-side API credentials in scripts or resources.
- Keep `export_presets.cfg` portable. Never commit a user-profile path or machine-specific custom template path.
- Treat `.godot/export_credentials.cfg` as confidential and untracked.
- Scrub non-generic author metadata from formal DOCX files before first remote publication.

## Validate changes to this Skill

Run the bundled preflight in `Audit` mode, then run the system `quick_validate.py` against this Skill directory. Test script changes on the FoxKnight project before relying on them.
