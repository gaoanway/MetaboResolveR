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
- [ ] Check git status before adding files.
- [ ] Confirm no private real file appears in `git status`.
- [ ] Confirm no private real file appears in `git log --stat` before push.

## GitHub Actions Plan

- [x] Add `r-lib/actions/setup-r`.
- [x] Add `r-lib/actions/setup-r-dependencies`.
- [x] Run `rcmdcheck::rcmdcheck(args = "--no-manual")`.
- [x] Cache R packages.
- [x] Run on `push` and `pull_request`.
- [ ] Confirm CI passes on GitHub.
- [ ] Confirm pkgdown deploys to `gh-pages`.

## Suggested Commit Sequence

- [ ] `chore: initialize package repository hygiene`
- [ ] `test: add real-case schema validation plan`
- [ ] `docs: add plasma reference database documentation`
- [ ] `ci: add R CMD check workflow`
- [ ] `docs: add package usage vignettes`

## Success Criteria

- Public repository exists.
- GitHub Actions pass.
- No private real data are present in repository history.
- A collaborator can install from GitHub and run basic examples.
