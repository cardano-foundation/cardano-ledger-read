# Plan — cardano-ledger-read#21

## Strategy

One OWNER slice. The pin set is mechanical, but
`ouroboros-consensus` 3→4 and `cardano-crypto-class` 2.3→2.5 are
majors, so source adaptation needs a commit owner and a sanity
auditor. LIGHT is ineligible: the gate cannot entail adaptation
faithfulness.

`cardano-deps` governs. Do not improvise around it.

## Topology (operator-named exceptions, not precedent)

- Ticket owner: grok (`grok --always-approve -m grok-4.6`) — exception
  to the metered-family fence.
- Commit owner: qwen (`qwen --yolo --model qwen3.8-max-preview`) —
  exception to draft-only. `draft=NONE` (qwen occupies the owner
  seat; no nested draft).
- Auditor: claude Sonnet
  (`claude --dangerously-skip-permissions --model sonnet --effort high`).
- Push, signing, PR creation: parent epic owner pane `%121`. Local
  commits use `git -c commit.gpgsign=false`. Neither grok nor qwen
  touches the GPG agent or push credentials.

## cardano-deps mapping

| step | this repo |
|---|---|
| s4 CHaP lock | `flake.lock` CHaP → `c0770200fcaa899ecdef548183dfee78e17bfb57` (node 11.1.0) |
| s5 freeze | already produced; sha256 `6a636c62…`, 570 lines |
| s6 .cabal bounds | one library; freeze-lower / next-minor-upper |
| s7 cabal.project | both index-states + exact constraint block |
| s8 node runtime | N/A (this repo does not pin a node runtime) |
| nix indexState | `flake.nix` `indexState` → `2026-08-14T13:38:07Z` |

## Slice S1 — pin set + mechanical adaptation

Base: `54f91a71874c50c14260de4eab6b2c2123e7d391` (`origin/main`).
Branch: `chore/issue-21-node-11-1-0`.
Worktree: this clone (not `/code/cardano-ledger-read`).

Owned paths (commit owner):

- `cabal.project`
- `cardano-ledger-read.cabal`
- `flake.nix` (`indexState`; plus, if option A cannot express the
  nested override, the node-style `hackageNix` input and
  `haskellNix.inputs.hackage.follows` — Q-001 fallback B)
- `flake.lock`: CHaP lock, **and** haskell.nix's `hackage` /
  `hackage.nix` snapshot so the mandated index-state is not newer
  than the index (Q-001). Target rev is cardano-node 11.1.0's
  `hackageNix` `1d6c4337df9348ef6a1c21f7dfd47e9b9a454ccf`. Sibling
  lock nodes rewritten as a mechanical consequence of that one
  override are in fence. Do not bump `haskellNix` itself unless A
  and B both fail (then a new Q).
- `nix/project.nix` only to delete evaluator-rejected stale
  `packages.<pkg>` overrides for packages absent from the 11.1.0
  freeze (Q-002: drop `cardano-lmdb` pkgconfig). Leave
  `blockio-uring` and crypto overlays. Do not drop unused
  `buildInputs` unless evaluation requires it.
- `src/**/*.hs` and `test/**/*.hs` only as the compiler requires
- `CHANGELOG.md` only if an existing convention on this branch
  already records pin bumps (PR #17 did not; default is leave it)

Forbidden:

- `/code/cardano-ledger-read` (shared checkout)
- `/code/cardano-wallet` (never `cd` into it)
- any path outside this clone
- new test suites, coverage expansion, refactors, extra constraint
  packages, invented versions
- GPG agent, push credentials, `gh pr create`, `git push`

## Build

Always the repo's own dev shell (IOG crypto overlay:
`libsodium-vrf`, `secp256k1`, `blst`). A bare `nix shell` lacks
`libsodium-any` and will reject `cardano-crypto-praos`.

```sh
nix develop --quiet --accept-flake-config -c just build
nix develop --quiet --accept-flake-config -c just test
```

## Auditor fence (carry verbatim)

Sanity checks and adaptation soundness only. Does it resolve? Does
it build? Do tests pass or are failures explained? Is the source
adaptation faithful to the upstream API change?

No coverage expansion. No new test suites. No refactor demands. No
mutation campaign. The auditor may report a real defect. It may not
turn this into a quality programme.

## Hard stops

HS-DESIGN / HS-BEHAVIOUR / HS-OUTSIDE in `spec.md`: file
`questions/Q-NNN-*.md` and park.

## Live boundary

None. This is a library pin + compile. No node, no network service.

## Output ceiling

Mandate packet (this directory) target ≤ 30 KiB. Compiled commit-owner
brief target ≤ 20 KiB.
