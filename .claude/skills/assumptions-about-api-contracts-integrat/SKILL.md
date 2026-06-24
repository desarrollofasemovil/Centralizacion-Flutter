---
name: assumptions-about-api-contracts-integrat
description: |
  Prevents assumptions about api contracts and integrations.
  Use when encountering assumptions about api contracts and integrations, especially the auth datasource assumed a guid token format.
  Do NOT use for tasks unrelated to the specific friction pattern described above.
allowed-tools: ["Read", "Glob", "Grep", "Bash"]
context: fork
argument-hint: "<file-or-component-path>"
---

## When to Use This Skill

- When a task involves assumptions about api contracts and integrations.
- When the auth datasource assumed a guid token format.
- Do NOT use for tasks unrelated to the specific friction pattern described above.

## Example Usage

> **Request**: "Fix the the auth datasource assumed a guid token format"
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

### Suggested Starting Prompt

> Here is the Postman collection and API contract. Read them first and implement the login flow exactly to the real spec — do not assume token format, HTTP method, or response shape.

## Rules

- ## API Integration
- Never assume API contracts (token format, HTTP method, endpoint paths, response shape)
- Ask for or read the Postman collection / API spec before implementing auth or network code
- After implementing, verify the fix doesn't regress related components or sibling functionality
- Before applying changes, list affected components and get confirmation

## What Goes Wrong

Review these failure patterns before implementing. Your fix must not repeat them:

- The auth datasource assumed a **GUID** token format, but the real **API** returned a pipe-separated profile response, requiring a fix only surfaced when you tested login.
- The initial login used a placeholder endpoint and wrong **HTTP** method until you supplied Postman files with the real **API** spec, wasting an implementation round.

## Verification Checklist

- [ ] Fix addresses the specific issue the user reported
- [ ] Change follows existing codebase patterns found during diagnosis
- [ ] Change is narrowly scoped — minimal blast radius
- [ ] Related/sibling components verified — no regressions
- [ ] Verified against: "The auth datasource assumed a GUID token format, but the real API returned a pipe-separated profile..."
- [ ] Verified against: "The initial login used a placeholder endpoint and wrong HTTP method until you supplied Postman..."
- [ ] Approach was proposed and confirmed before implementation

## Why This Skill Exists

Claude repeatedly guessed at endpoint formats, token shapes, and integration details instead of confirming them first, forcing rework once you tested against the real backend. Providing the API spec, Postman files, or contract docs up front would prevent these dead-end implementations.
