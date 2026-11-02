# Development workflow

- Edit this repository's source directly. Use Codex `apply_patch` for reviewable inline text edits.
- Do not generate patch files, patch-producing scripts, incremental ZIPs, source bundles or duplicate source trees. Use ordinary Git commits and checked CI builds.
- Keep runtime assets, saves and useful build/test commands; remove obsolete generated packaging artifacts.
- Do not use, install, download, launch, configure or delegate to local AI models/services, including Ruflo, Qwen and Ollama. Use the current Codex session and ordinary development tools.
- Read [AI_HANDOFF.md](AI_HANDOFF.md) before starting project work and update it at the end of every AI work session. Record verified changes, tests, current branch/commit, unfinished work and user-reverted edits; never restore a user-reverted change without permission.
