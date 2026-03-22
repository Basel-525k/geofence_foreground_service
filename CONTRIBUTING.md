# Contributing

Thank you for helping improve this plugin. The guidelines below keep reviews fast and the codebase stable.

## Pull requests: keep them small

- **One logical change per PR** — fix a bug, add one feature slice, or refactor one area. Split unrelated work into separate PRs.
- **At most 15 files touched per PR** (excluding generated lockfiles only if the project convention requires committing them). If you exceed that, the change is probably doing too much; break it up.
- **Prefer smaller diffs** — fewer lines and fewer concepts per review round leads to better feedback and fewer regressions.

If a large feature is unavoidable, use a **stacked or sequential PR** approach: land foundational pieces first, then build on them in follow-up PRs.

## Before you open a PR

- **Match existing style** — naming, formatting, and patterns should look like the surrounding code.
- **Run tests** — ensure existing tests pass; add or update tests when behavior changes or new logic is introduced.

## PR description

Include enough context for reviewers who do not have your full history:

- **What** changed and **why** (problem or goal).
- **How** to validate (commands run, manual steps on Android/iOS if relevant).
- Link **related issues** when applicable.

## Scope and compatibility

- **Avoid unrelated refactors** in the same PR as a feature or bugfix.
- **Call out breaking API changes** clearly in the PR.
- **Platform parity** — if you change behavior on one platform, note whether the other should match and whether you implemented it.

## Commits

- **Clear commit messages** — short subject line; optional body explaining non-obvious decisions.
- **Logical commits** — each commit should build and make sense on its own when possible (helps bisect and review).

## Reviews

- **Respond to review feedback** — push follow-up commits or reply when something is intentional.
- **Resolve conversation threads** after addressing them (when the host allows), so reviewers know what is done.

## Questions and design

For larger features or API changes, consider opening an **issue first** to align on direction before investing in a big implementation.

## License

By contributing, you agree that your contributions will be licensed under the same license as the project (see the repository’s `LICENSE` file).
