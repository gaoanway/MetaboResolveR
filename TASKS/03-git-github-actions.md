# Phase 3 Task: Public GitHub And GitHub Actions

**Goal:** Put `MetaboResolveR` into a public GitHub repository with clean
history, safe ignores, and automated R package checks.

**Repository Visibility Decision**

The GitHub repository should be public.

**Data Safety Decision**

The real 1,416-row observed workbook, split chunks, and direct local outputs must not
be committed.

## Deliverables

- [x] `.gitignore`
- [x] Git repository initialized or cleaned.
- [x] Public GitHub repository.
- [x] `.github/workflows/R-CMD-check.yaml`
- [x] Optional `.github/workflows/pkgdown.yaml`
- [ ] First release tag after version decision.

## Git Safety Checklist

- [x] Add `.gitignore` before first public push.
- [x] Ignore:
  - `data-raw/real_case/`
  - `*.Rcheck/`
  - `..Rcheck/`
  - `.r-cache/`
  - package tarballs.
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
- [x] Confirm CI passes on GitHub.
- [x] Confirm pkgdown deploys to `gh-pages`.

## Current Status

- Local `main` has been committed with package source, documentation, tests,
  reference-data build scripts, and GitHub Actions workflows.
- Ignored local-only files include the real-case workbook/chunks, R check
  outputs, package tarballs, cache files, and large raw zip archive.
- Remote repository has been created as `gaoanway/MetaboResolveR`.
- Local `main` has been pushed to `gaoanway/MetaboResolveR`.
- GitHub Actions run 2 passed for both `R-CMD-check` and `pkgdown`.
- The `gh-pages` branch contains the generated pkgdown site.
- The public Pages URL may require enabling GitHub Pages source to
  `gh-pages` / root once in repository settings.

## Suggested Commit Sequence

- [x] `chore: initialize MetaboResolveR package with CI/CD`

## Success Criteria

- Public repository exists.
- GitHub Actions pass.
- No private real data are present in repository history.
- A collaborator can install from GitHub and run basic examples.
- Release tag remains pending until the package version is finalized.
- Public pkgdown URL should be rechecked after Pages source is enabled.
