# Contributing to SkyCAIR OS

Thank you for your interest in contributing to SkyCAIR OS!

**Contact**: SkyCAIR@123Tech.net | https://123tech.net
**Branch**: `skycair-2.6-cosmic` (all contributions target this branch)

---

## Ways to Contribute

- **Bug reports** — open a GitHub Issue using the bug report template
- **Feature requests** — open a GitHub Issue using the feature request template
- **Build script improvements** — submit a Pull Request
- **Documentation** — typos, clarity, missing info are all welcome
- **Package additions** — new SlackBuilds for the App Store or module extras

---

## Before You Start

1. **Check existing issues** — your bug or feature may already be tracked
2. **Test on SkyCAIR** — contributions should be tested in a SkyCAIR or Slackware current environment
3. **Small, focused PRs** — one logical change per pull request

---

## Pull Request Process

1. Fork this repository
2. Create a branch from `skycair-2.6-cosmic`:
   ```bash
   git checkout -b fix/your-fix-name skycair-2.6-cosmic
   ```
3. Make your changes and test them
4. Commit with a clear message:
   ```
   component: short description of change

   Longer explanation if needed. Reference issue numbers: Fixes #123
   ```
5. Push and open a Pull Request against `skycair-2.6-cosmic`
6. Fill in the PR template completely

---

## Build Environment

SkyCAIR modules must be built in a **Slackware 64-bit current** or
**SkyCAIR live** environment. Build order:

```
000-kernel → 001-core → 002-gui → 002-xtra → 003-<desktop> → (optional: 05-devel, 08-multilanguage, 0050-multilib-lite)
```

Output: `/tmp/skycair-builder-[version]/`

---

## Code Style

- Shell scripts: POSIX-compatible where possible, bash where needed
- Indent with tabs (consistent with existing code)
- SlackBuilds follow the standard Slackware SlackBuild format
- Keep build scripts idempotent where possible

---

## Upstream Sync

This repo is a fork of [porteux/porteux](https://github.com/porteux/porteux).
Upstream changes are merged into `main` first, then rebased onto `skycair-2.6-cosmic`.
Do not submit PRs that conflict with upstream without discussion.

---

## License

By submitting a contribution, you agree that your contribution will be
licensed under the [SkyCAIR Source Available License](LICENSE).
For commercial licensing: SkyCAIR@123Tech.net
