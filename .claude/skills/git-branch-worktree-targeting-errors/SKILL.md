---
name: git-branch-worktree-targeting-errors
description: |
  Prevents git branch and worktree targeting errors.
  Use when encountering git branch and worktree targeting errors, especially a worktree branched from main instead of develop.
  Do NOT use for tasks unrelated to the specific friction pattern described above.
allowed-tools: ["Read", "Glob", "Grep", "Bash"]
context: fork
argument-hint: "<file-or-component-path>"
---

## When to Use This Skill

- When a task involves git branch and worktree targeting errors.
- When a worktree branched from main instead of develop.
- Do NOT use for tasks unrelated to the specific friction pattern described above.

## Example Usage

> **Request**: "Fix the issue following the existing codebase patterns"
>
> **Steps taken**:
> 1. Read the relevant files and map existing patterns before making changes
> 2. Identify constraints — what must not change and which components are affected
> 3. Apply the most minimal, narrowly-scoped change possible
> 4. Verify the fix works and does not regress related components
>
> **Result**: Issue resolved with minimal change, existing patterns preserved

## Steps

1. **Diagnose**: Read the relevant files and map existing patterns. Identify boundaries, ownership, and current behavior before changing anything.
2. **Identify constraints**: List what must NOT change and which components are affected. Get confirmation before proceeding.
3. **Propose approach**: Describe your planned fix and explain why it avoids the known failure patterns listed in "What Goes Wrong" below.
4. **Implement**: Apply the most minimal, narrowly-scoped change possible.
5. **Verify**: Confirm the fix works AND doesn't regress related components. Check against each example in "What Goes Wrong". Run relevant tests.

## Rules

- ## Branch & PR Targeting
- Always confirm the target branch before opening a PR (default to `develop`, NOT `main`)
- - When working in a worktree, confirm whether testing/changes should happen on the worktree or the main route, and branch worktrees from `develop` unless told otherwise
- After implementing, verify the fix doesn't regress related components or sibling functionality

## What Goes Wrong

Review these failure patterns before implementing. Your fix must not repeat them:

- Claude opened a **PR** against main when you only wanted changes on the navigation-improvement branch for testing, forcing the **PR** to be closed.
- A worktree branched from main instead of develop, requiring a rebase to pull in your previous fixes.

## Verification Checklist

- [ ] Fix addresses the specific issue the user reported
- [ ] Change follows existing codebase patterns found during diagnosis
- [ ] Change is narrowly scoped — minimal blast radius
- [ ] Related/sibling components verified — no regressions
- [ ] Verified against: "Claude opened a PR against main when you only wanted changes on the navigation-improvement branch..."
- [ ] Verified against: "A worktree branched from main instead of develop, requiring a rebase to pull in your previous fixes."
- [ ] Approach was proposed and confirmed before implementation

## Why This Skill Exists

Claude frequently picked the wrong target for PRs, testing, and branch bases, requiring you to interrupt and correct course. Stating the exact branch/route to target at the start of each git task would cut these reversals.
