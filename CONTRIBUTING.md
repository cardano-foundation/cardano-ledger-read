# Contributing

Thanks for contributing to `cardano-ledger-read`.

## Before you open a pull request

Run the full local CI. It is the same set of checks the pipeline runs, and it takes far less time than a round trip through GitHub Actions:

```bash
nix develop     # haskell.nix shell with cabal, GHC 9.12, just
just ci         # format + lint + build + test
```

If `just ci` passes locally, CI should pass.

## The checks, and what fails them

| recipe | tool | fails when |
| --- | --- | --- |
| `just format` | fourmolu + nixfmt | any file is not formatted. CI runs `just format && git diff --exit-code`, so an unformatted file fails even though the recipe rewrites it |
| `just lint` | hlint | **any hint is reported at all** |
| `just build` | cabal | the project does not build |
| `just test` | cabal | a test fails |

### hlint runs at zero tolerance

This is the one that surprises people. `just lint` is a bare `hlint` over `src` and `test`, so **a single hint of any severity fails the job** — including stylistic ones like `Use isJust`. There is no warning threshold.

If you believe a hint is wrong for this codebase, don't work around it in the code: add an `ignore` entry to `.hlint.yaml` in the same PR and say why.

## A note on CI for pull requests from forks

Workflow runs on fork PRs need a maintainer to approve them before they start. Until someone does, your PR shows no checks at all — not passing, not failing, just absent.

**This is not a signal about your change.** If your PR has been sitting without checks, please say so on the PR and a maintainer will approve the run.

If your fork is owned by an **organisation** rather than a personal account, note that GitHub's *Allow edits by maintainers* does not work — maintainers cannot push fixes to your branch even when the setting appears enabled. Expect review suggestions instead of direct pushes.

## Development

```bash
nix develop     # enter the dev shell (direnv: `use flake`)
just            # list all recipes
just build      # build all components
just test       # run the test suite
just format     # fourmolu + nixfmt
just lint       # hlint
just ci         # format + lint + build + test
just docs       # serve the docs site locally with mkdocs
```

## Commits and pull requests

- Keep the PR focused on one change.
- Explain *why* in the description; the diff already shows *what*.
- If your change is forced by an upstream API change, say which upstream change forced it — it makes review much faster.

## Era-indexed code

This library is a read-side projection over ledger eras, and a good deal of its code is era-indexed. When you add an era-specific function, **check whether it needs a case for every era, including the most recent one.**

A missing era case is not always a compile error and is rarely a failing test — an era ladder can simply stop one rung short and nothing will complain. If you add a function for one era, look for its siblings and make sure the set is complete.
