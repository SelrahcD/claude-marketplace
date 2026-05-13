# Refactoring skill

Drive a refactor as a sequence of small, named refactorings from Martin Fowler's catalog. Each named refactoring is one commit. Each commit is verified against a safety net (tests, type-checker, or manual review).

## Why

When a PR reviewer reads the commits of a refactor session, they should see the sequence of named refactorings applied, in order, without having to reconstruct intent from diffs. This skill enforces that discipline.

## How to invoke

- **Slash command:** `/refactor` (optionally with a free-text description: `/refactor split Order into Order + TaxCalculator`).
- **Natural language:** "refactor this", "extract a method here", "rename X to Y", "this code is messy, clean it up", "restructure without changing behavior".

## What you get

1. A SETUP step where you declare a safety net (tests / type-checker / both / manual).
2. A PLAN — an ordered list of named refactorings from Fowler's catalog. You approve or edit before any code changes.
3. Per refactoring: the skill loads the catalog mechanics, applies them step by step, runs verification, and commits with a message like `refactor: Extract Method 'calculateTax' from Order#total`.
4. A REASSESS step between refactorings so the plan can evolve if the code reveals something new.

## Catalog

17 refactorings ship in v1, covering Composing methods, Moving features, Organizing data, Simplifying conditionals, Refactoring APIs, Dealing with inheritance, and Larger restructurings. See `catalog/INDEX.md`.

## Limits

- The skill never delegates to `/commit` — it writes its own commit messages because the refactoring name is load-bearing.
- The skill operates on the current branch only. No branch switching mid-refactor.
- The skill is independent from `tdd-process`. To do a structured multi-step refactor while in TDD, exit `tdd-process` first.

## Credits

Mechanics drawn from *Refactoring: Improving the Design of Existing Code* (2nd ed.) by Martin Fowler.
