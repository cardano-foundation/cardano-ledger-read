# Plan — cardano-ledger-read#23

## Strategy

One OWNER slice. The change is one exported function following an
existing sibling. LIGHT is ineligible: the brief names a commit
owner plus a sanity auditor, and FR-SHAPE/FR-NO-ERROR need a
semantic check that the function upgrades toward the latest era
rather than inventing an `error`.

## Topology (operator-named exceptions, not precedent)

- Ticket owner: grok (`grok --always-approve -m grok-4.6`).
- Commit owner: qwen (`qwen --yolo --model qwen3.8-max`) —
  exception to draft-only. `draft=NONE`. Operator pin: **max, not
  max-preview**.
- Auditor: claude Sonnet
  (`claude --dangerously-skip-permissions --model sonnet --effort high`).
- Push, signing, PR creation: parent epic owner pane `%121`.
  Local commits use `git -c commit.gpgsign=false`.

## Slice S1 — add `upgradeToOutputDijkstra`

Base: `d5847e29f5f9633fad268c0debd1413c353e5523`.
Branch: `feat/issue-23-upgrade-to-output-dijkstra`.
Worktree: this clone (not `/code/cardano-ledger-read`).

Owned paths (commit owner):

- `src/Cardano/Read/Ledger/Tx/Output.hs` (export + new function +
  haddock matching the Conway sibling)
- `CHANGELOG.md` only if an existing convention on this branch
  already records API additions (default: leave it)

Forbidden:

- `upgradeToOutputConway` body, including its Dijkstra `error`
- `test/` (parity is zero dedicated tests)
- `cabal.project`, `*.cabal` bounds, `flake.nix`, `flake.lock`
- tracked `.gitignore`
- `/code/cardano-ledger-read`, `/code/cardano-wallet`
- GPG agent, push credentials, `gh pr create`, `git push`
- new modules, new test suites, coverage expansion, refactors

Compiler-forced import already present: `upgradeTxOut` from
`Cardano.Ledger.Api`. One extra `upgradeTxOut` on the Conway chain
is the expected shape. If there is no Conway → Dijkstra instance,
**HS-API**: Q and park.

## Build

Repo's own dev shell (IOG crypto overlay). Not a bare `nix shell`.

```sh
nix develop --quiet --accept-flake-config --no-write-lock-file -c just build
nix develop --quiet --accept-flake-config --no-write-lock-file -c just test
```

## Auditor fence (carry verbatim)

Sanity checks and adaptation soundness only. Does it build? Do
tests pass? Is the new function faithful to the ladder's existing
shape?

No coverage expansion beyond parity with the sibling upgrades. No
new test suites. No refactor demands. No mutation campaign.

The auditor may report a real defect. It may not turn a
one-function addition into a quality programme. The ticket owner
cuts that back.

## Hard stops

HS-ERROR / HS-ORDER / HS-API / HS-OUTSIDE in `spec.md`: file
`questions/Q-NNN-*.md` and park.

## Live boundary

None. Library function. No node, no network.

## Output ceiling

Mandate packet (this directory) target ≤ 20 KiB. Compiled
commit-owner brief target ≤ 16 KiB.
