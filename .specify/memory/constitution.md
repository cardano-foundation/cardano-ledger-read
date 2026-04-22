<!-- Sync Impact Report
Version change: 0.0.0 → 1.0.0
Added sections: All (initial constitution)
Modified principles: N/A (first version)
Templates requiring updates:
  - .specify/templates/plan-template.md ✅ reviewed (Constitution Check aligns)
  - .specify/templates/spec-template.md ✅ reviewed (no updates needed)
  - .specify/templates/tasks-template.md ✅ reviewed (phase structure compatible)
Follow-up TODOs: None
-->

# cardano-ledger-read Constitution

## Core Principles

### I. Read-Only Library

`cardano-ledger-read` is a *read-side* projection layer over
`cardano-ledger-*`. It MUST NOT construct, balance, sign, or submit
transactions; those concerns belong to `cardano-balance-transaction`,
`cardano-wallet-sign`, and downstream applications. The library's
surface is restricted to reading and projecting on-chain data: blocks,
transactions, outputs, certificates, metadata. Any helper that mutates
ledger state or produces a tx for submission belongs elsewhere.

### II. Closed-World Era Model

Eras are a **closed type-level list** (`KnownEras` in
`Cardano.Read.Ledger.Eras.KnownEras`), not an open set. The full era
list is enumerated in one place; consumers depend on this closure.
Adding or removing an era is a single mechanical sweep:

1. Extend (or shrink) the `KnownEras` type-level list.
2. Add (or remove) the constructor in the `Era era` GADT.
3. Add (or remove) the `IsEra era` instance.
4. Extend `indexOfEra`, `knownEras`, every closed type-family equation,
   every GADT-`case` over `Era`, and every `EraValue f` traversal.

The closed-world assumption is load-bearing: pattern matches over `Era`
must be exhaustive without a wildcard, and CI MUST flag any
non-exhaustive `case` over `Era` as a build failure.

### III. Type Families and GADTs Over Typeclasses

Era-indexed types are projected via **closed type families**
(`OutputType era`, `TxT era`, `ValueType era`, `MintType era`, …) — one
equation per era. Era-polymorphic *operations* dispatch via **GADT
pattern matching** on the `Era era` singleton (`case theEra @era of
Byron -> …; Shelley -> …; …`).

There is exactly one typeclass in the era model — `IsEra era` — and it
exists only to reflect a type-level era to the value level (`theEra ::
Era era`). It MUST NOT grow per-era methods; new behavior MUST go in a
new closed type family + GADT-case dispatch, never in an open class
with per-era instances. This keeps every era extension grep-able and
prevents instance-based abstraction holes.

### IV. Total Functions at Era Boundaries

Era projection and upgrade functions (`upgradeToOutput*`,
`upgradeToTx*`, `getEraValue`, `extractEraValue`, …) MUST be total over
`KnownEras`. Partial `error "cannot downgrade from Dijkstra"`-style
stubs are prohibited in released versions. If an upgrade or downgrade
is genuinely undefined for an era pair, the function MUST return
`Maybe` / `Either` and the constraint MUST be reflected in the type.
A new era addition MUST update *every* upgrade-from site in the same
PR; the closed-world property exists to make this audit possible.

### V. Mirror, Don't Redefine

Per-era projections MUST mirror the underlying `cardano-ledger-*` type
shape rather than introduce wallet-specific intermediate types. The
library is a thin re-projection: it adds era-indexing and
`EraValue`-existential machinery, but the leaf types are
`cardano-ledger-*` types. New domain types (e.g. wallet-specific
metadata wrappers) belong in the consumer, not here.

### VI. Minimal Dependency Surface

The library MUST minimize transitive dependencies. Direct dependencies
on high-level aggregation packages are prohibited:

- **Allowed**: `cardano-ledger-*`, `cardano-binary`, `cardano-crypto-*`,
  `cardano-strict-containers`, `cardano-chain` (for Byron read paths),
  base Haskell ecosystem packages.
- **Prohibited**: `cardano-api` in any form; `cardano-wallet-*`;
  `cardano-node`; `cardano-cli`; `ouroboros-consensus-cardano` (use
  `ouroboros-consensus` directly when needed).
- **Boundary**: The library MUST be buildable without any
  `cardano-wallet`, `cardano-node`, or `cardano-api` package in scope.

### VII. Version-Bound Hygiene

Every Cabal dependency on a `cardano-ledger-*` package MUST carry an
explicit version bound matching the style of the existing
`cardano-ledger-conway` / `cardano-ledger-babbage` entries. Unbounded
new-era libraries (e.g. a fresh `cardano-ledger-dijkstra`) are
prohibited in released versions. Bounds MUST be tightened in the same
PR that bumps the source-repository-package pin or `index-state`.

### VIII. Property-Based Testing

Era projection and upgrade functions MUST have round-trip property
tests: `serialize → deserialize → equal`; `upgrade(downgrade(x)) ≈ x`
where defined. Per-era test transactions MUST exercise
era-distinguishing features — a Dijkstra test transaction MUST use a
Dijkstra-only field, not be a structural copy of the Conway one.
Generic property tests MUST iterate over `KnownEras` rather than
hardcode an era subset.

### IX. Behavioral Preservation

Refactoring (including dependency changes and era list edits) MUST NOT
change observable serialization or projection behavior. The existing
test suite is the behavioral contract. Any internal rewrite MUST pass
all existing tests without modification to test assertions. If a test
needs updating, the behavioral change MUST be documented and justified
in the PR.

## Architectural Constraints

- **Module layout**: `Cardano.Read.Ledger.<Domain>.<Concept>` (e.g.
  `Cardano.Read.Ledger.Tx.Output`, `Cardano.Read.Ledger.Block.BHeader`).
  Per-domain era families live next to their domain.
- **One TF per concept**: each closed type family covers one concept
  across all eras (`OutputType`, `TxT`, …). Do not split into
  per-era-group families.
- **`EraValue f` is the only existential**: era-existential wrapping
  uses `EraValue (f :: Type -> Type)`, not bespoke `InAnyEra` types.
- **Singletons stay singletons**: `Era` and `IsEra` are not extended
  with per-era methods, witnesses, or evidence beyond `theEra`.

## Development Workflow

- **Haskell style**: Fourmolu formatting, explicit imports, qualified
  imports for external modules, leading commas, `NoImplicitPrelude`.
- **Build system**: Nix flake with `haskell.nix`; cabal as the build
  tool; `justfile` for common commands; `nix develop -c just ci` is the
  CI contract.
- **CI**: GitHub Actions. All PRs MUST pass CI before merge. Treat any
  non-exhaustive era pattern match as a build failure.
- **Commits**: Conventional Commits; small, focused, one logical change
  per commit; bisect-safe (every commit compiles).
- **Branches**: Feature branches from `main`, rebase-merge.
- **Releases**: release-please drives version bumps from commit history.
- **Spec-Driven Development**: Every non-trivial change goes through
  `/speckit.specify` → `/speckit.plan` → `/speckit.tasks` →
  `/speckit.implement`. Era additions, type-family edits, and upgrade
  function changes MUST go through speckit because they touch the
  closed-world contract.

## Governance

This constitution is the authority for architectural decisions in
`cardano-ledger-read`. All PRs MUST be checked against these
principles, particularly the closed-world era model, type-family /
GADT dispatch rule, and totality at era boundaries. Amendments require
a PR modifying this file with rationale in the commit message. Version
follows semver:

- **MAJOR**: Principle removal or redefinition (e.g. opening the era
  world, or admitting per-era typeclass instances).
- **MINOR**: New principle or material expansion.
- **PATCH**: Clarification or wording fix.

**Version**: 1.0.0 | **Ratified**: 2026-04-22 | **Last Amended**: 2026-04-22
