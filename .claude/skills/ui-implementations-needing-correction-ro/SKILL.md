---
name: ui-implementations-needing-correction-ro
description: |
  Prevents ui implementations needing multiple correction rounds.
  Use when encountering ui implementations needing multiple correction rounds, especially the morphing 'agregar al carrito'/'ir a pagar' button approach didn't work, the freeze/show-data buttons changed size when text changed and had a wrong dark background.
  Do NOT use for tasks unrelated to the specific friction pattern described above.
allowed-tools: ["Read", "Glob", "Grep", "Bash"]
context: fork
argument-hint: "<file-or-component-path>"
---

## When to Use This Skill

- When a task involves ui implementations needing multiple correction rounds.
- When the morphing 'agregar al carrito'/'ir a pagar' button approach didn't work.
- When the freeze/show-data buttons changed size when text changed and had a wrong dark background.
- Do NOT use for tasks unrelated to the specific friction pattern described above.

## Example Usage

> **Request**: "Fix the the morphing 'agregar al carrito'/'ir a pagar' button approach didn't work"
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

- Always inspect and reference existing implementations, needing, multiple patterns before proposing a solution
- Do NOT apply broad or global changes — use the narrowest possible scope
- After implementing, verify the fix doesn't regress related components or sibling functionality
- Before applying changes, list affected components and get confirmation

## What Goes Wrong

Review these failure patterns before implementing. Your fix must not repeat them:

- The morphing 'Agregar al carrito'/'Ir a pagar' button approach didn't work, so you reverted to a persistent cart bar across both screens.
- The freeze/show-data buttons changed size when text changed and had a wrong dark background, needing two correction rounds to fix the Stack-induced width issue.

## Verification Checklist

- [ ] Fix addresses the specific issue the user reported
- [ ] Change follows existing codebase patterns found during diagnosis
- [ ] Change is narrowly scoped — minimal blast radius
- [ ] Related/sibling components verified — no regressions
- [ ] Verified against: "The morphing 'Agregar al carrito'/'Ir a pagar' button approach didn't work, so you reverted to a..."
- [ ] Verified against: "The freeze/show-data buttons changed size when text changed and had a wrong dark background,..."
- [ ] Approach was proposed and confirmed before implementation

## Why This Skill Exists

Several UI features were built with an approach that didn't behave as you wanted, taking two or more refinement passes to land. Describing the exact desired behavior and edge cases (sizing, navigation flow) upfront would reduce the back-and-forth.
