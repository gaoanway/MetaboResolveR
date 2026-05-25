# Phase 3 Task: Public GitHub And GitHub Actions

**Goal:** Put `plasmaAnnotateR` into a public GitHub repository with clean
history, safe ignores, and automated R package checks.

**Repository Visibility Decision**

The GitHub repository should be public.

**Data Safety Decision**

The real 1,416-row observed workbook, split chunks, and direct local outputs must not
be committed.

## Deliverables

- [x] `.gitignore`
- [x] Git repository initialized or cleaned.
- [ ] Public GitHub repository.
- [x] `.github/workflows/R-CMD-check.yaml`
- [x] Optional `.github/workflows/pkgdown.yaml`
- [ ] First release tag after CI passes.

## Git Safety Checklist

- [x] Add `.gitignore` before first public push.
- [x] Ignore:
  - `data-raw/real_case/`
  - `*.Rcheck/`
  - `..Rcheck/`
  - `.r-cache/`
  - `plasmaAnnotateR_*.tar.gz`
  - local Excel files.
  - public raw files too large for normal GitHub storage.
- [x] Check git status before adding files.
- [x] Confirm no private real file appears in `git status`.
- [x] Confirm no private real file appears in `git log --stat` before push.

## GitHub Actions Plan

- [x] Add `r-lib/actions/setup-r`.
- [x] Add `r-lib/actions/setup-r-dependencies`.
- [x] Run `rcmdcheck::rcmdcheck(args = "--no-manual")`.
- [x] Cache R packages.
- [x] Run on `push` and `pull_request`.
- [ ] Confirm CI passes on GitHub.
- [ ] Confirm pkgdown deploys to `gh-pages`.

## Current Status

- Local `main` has been committed with package source, documentation, tests,
  reference-data build scripts, and GitHub Actions workflows.
- Ignored local-only files include the real-case workbook/chunks, R check
  outputs, package tarballs, cache files, and large raw zip archive.
- Remote publication is waiting for a public GitHub repository that the GitHub
  App can access.

## Suggested Commit Sequence

- [x] `chore: initialize plasmaAnnotateR package with CI/CD`

## Success Criteria

- Public repository exists.
- GitHub Actions pass.
- No private real data are present in repository history.
- A collaborator can install from GitHub and run basic examples.
