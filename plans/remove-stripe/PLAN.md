# Plan: Remove Stripe Entirely from the Repo

## Summary

Remove all Stripe SDK dependencies, billing infrastructure, and related code. This is a single-user fork — the billing router already returns a static "free" plan and the paywall is a pass-through — so the Stripe integration is dead weight.

Two unrelated "stripe" names exist in the repo that are **NOT** the Stripe payments platform:
- **`stripe-gradient`** — a WebGL mesh-gradient npm package used by `<MeshGradient />` in `packages/ui`. This stays.
- **Desktop UI `stripe`** — variable names like `showsStandaloneActiveStripe` in sidebar components. These are visual stripes (highlight bars), not the payment platform. These stay.

---

## Phase 1: Delete Stripe API Integration (apps/api)

| # | Action | File(s) |
|---|--------|---------|
| 1a | Delete entire directory | `apps/api/src/app/api/integrations/stripe/` (3 files: `route.ts`, `slack-blocks.ts`, `slack-blocks.test.ts`) |
| 1b | Remove `stripe` npm dependency | `apps/api/package.json` — remove `"stripe": "20.4.1"` |

---

## Phase 2: Remove Stripe Env Vars

Remove all Stripe-related env var declarations. These appear in 5 env files, `.env.example`, and 2 CI workflows.

| # | Action | File(s) |
|---|--------|---------|
| 2a | Remove `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `STRIPE_PRO_MONTHLY_PRICE_ID`, `STRIPE_PRO_YEARLY_PRICE_ID`, `SLACK_BILLING_WEBHOOK_URL` from server env schema | `apps/api/src/env.ts`, `apps/web/src/env.ts`, `apps/admin/src/env.ts`, `apps/marketing/src/env.ts` |
| 2b | Remove the `# Stripe Billing` section and its 2 vars | `.env.example` |
| 2c | Remove all `STRIPE_*` and `SLACK_BILLING_WEBHOOK_URL` entries (secrets + `--env` flags) | `.github/workflows/deploy-production.yml`, `.github/workflows/deploy-preview.yml` |

**Env vars to remove everywhere:**
- `STRIPE_SECRET_KEY`
- `STRIPE_WEBHOOK_SECRET`
- `STRIPE_PRO_MONTHLY_PRICE_ID`
- `STRIPE_PRO_YEARLY_PRICE_ID`
- `STRIPE_ENTERPRISE_YEARLY_PRICE_ID` (CI-only, not in env.ts)
- `SLACK_BILLING_WEBHOOK_URL`

---

## Phase 3: Simplify DB Schema (packages/db)

Remove Stripe-specific columns from the `subscriptions` and `organizations` tables.

| # | Action | File(s) |
|---|--------|---------|
| 3a | Remove `stripeCustomerId` column + its index | `packages/db/src/schema/schema.ts` — `subscriptions` table |
| 3b | Remove `stripeSubscriptionId` column | `packages/db/src/schema/schema.ts` — `subscriptions` table |
| 3c | Remove `stripeScheduleId` column | `packages/db/src/schema/schema.ts` — `subscriptions` table |
| 3d | Remove `index("subscriptions_stripe_customer_id_idx")` | `packages/db/src/schema/schema.ts` |
| 3e | Remove `stripeCustomerId` column from `organizations` | `packages/db/src/schema/auth.ts` |
| 3f | **Generate migration** — after schema edits, ask user to run `bunx drizzle-kit generate --name="remove_stripe_columns"` from `packages/db/` | — |

> ⚠️ **Do NOT manually edit** `packages/db/drizzle/` files — Drizzle auto-generates those.

---

## Phase 4: Update Billing Router (packages/trpc)

The billing router is already stubbed for single-user mode but still has a `portal` mutation that mentions Stripe. Simplify it.

| # | Action | File(s) |
|---|--------|---------|
| 4a | Remove the `portal` mutation entirely (it throws NOT_IMPLEMENTED anyway) | `packages/trpc/src/router/billing/billing.ts` |
| 4b | Remove `stripeCustomerId` from any query that joins on it (currently none in billing.ts, already clean) | — |
| 4c | Remove the `billingRouter` import and `billing` key from root router **if no callers remain** — otherwise keep the stub | `packages/trpc/src/root.ts` |

> **Decision point**: The `billingRouter` is imported in `packages/trpc/src/root.ts` and mounted as `billing: billingRouter`. The billing settings page in `apps/web` calls `billing.activePlan` at most. The stub is harmless, but we could also delete the entire router if the UI billing pages are removed (see Phase 6). Recommend keeping the stub for now to avoid breaking any client that expects the `billing` tRPC namespace.

---

## Phase 5: Update Downstream Consumers of Shared Billing Utils

| # | Action | File(s) |
|---|--------|---------|
| 5a | `packages/trpc/src/router/host/host.ts` — `checkAccess` query joins on `subscriptions` to determine `paidPlan`. Remove the Stripe-specific subscription join logic; hardcode `paidPlan: true` (single-user fork) or keep the join but remove `isPaidPlan` import from `@superset/shared/billing` | `packages/trpc/src/router/host/host.ts` |
| 5b | `packages/db/src/utils/membership.ts` — uses `ACTIVE_SUBSCRIPTION_STATUSES` from `@superset/shared/billing` in the subscription join. Remove Stripe coupling; either keep the join (it still works without `stripeCustomerId`) or simplify if desired | `packages/db/src/utils/membership.ts` |
| 5c | `apps/desktop/src/renderer/hooks/useCurrentPlan.ts` — uses `isActiveSubscriptionStatus` and `PlanTier` from `@superset/shared/billing`. This is fine — the shared billing types (`PlanTier`, `isPaidPlan`, etc.) are abstract and don't reference Stripe. **No change needed.** | — |
| 5d | `packages/shared/src/billing.ts` — the utility functions here (`isPaidPlan`, `isActiveSubscriptionStatus`, `PlanTier`) are **not** Stripe-specific. **Keep this file.** | — |
| 5e | Remove `@superset/shared/billing` export from `packages/shared/package.json` only if we decide to delete `billing.ts` entirely (recommendation: keep it) | — |

---

## Phase 6: Remove/Stub Billing UI Pages

| # | Action | File(s) |
|---|--------|---------|
| 6a | `apps/web/src/app/(dashboard-legacy)/settings/billing/page.tsx` — already non-functional (redirects to desktop app). Either delete the page or replace with "Billing is not available in this mode" static text. | `apps/web/...` |
| 6b | `apps/desktop/src/renderer/components/Paywall/` — already a pass-through. **Keep as-is** — it's the correct single-user behavior and removing it would break import sites. | — |
| 6c | `apps/desktop/src/renderer/hooks/useCurrentPlan.ts` — references subscriptions via `useLiveQuery`. Without Stripe, subscriptions rows won't exist, so `plan` will always resolve to `"free"`. **Keep as-is.** | — |

---

## Phase 7: Clean Up Misc References

| # | Action | File(s) |
|---|--------|---------|
| 7a | Update `README.md` line 107 — remove "Stripe" from the list of third-party integration keys | `README.md` |
| 7b | `apps/web/src/app/(agents)/mock-data.ts` — lines 87 and 136 reference "Stripe" in mock agent/task names. These are cosmetic mock data, not real Stripe code. **Low priority** — can leave or rename. | `apps/web/...` |
| 7c | Run `bun install` after removing `stripe` from `apps/api/package.json` and `stripe-gradient` stays — the lockfile will update automatically | Root |

---

## Phase 8: Verify & Validate

| # | Action |
|---|--------|
| 8a | `bun run typecheck` — ensure no broken imports |
| 8b | `bun run lint:fix` — fix any unused-import warnings from removed Stripe code |
| 8c | `bun run lint` — must exit 0 |
| 8d | `bun test` — ensure the deleted `slack-blocks.test.ts` is the only removed test |
| 8e | `bun build` — verify full build passes |
| 8f | Search for any remaining `stripe` references (excluding `stripe-gradient`, visual stripe vars, and drizzle snapshots): `rg -i "stripe" --type ts --type tsx --type json --type yaml -l \| grep -v stripe-gradient \| grep -v bun.lock \| grep -v drizzle/meta` |

---

## What NOT to Touch

| Item | Reason |
|------|--------|
| `stripe-gradient` npm package + `stripe-gradient.d.ts` files | Unrelated WebGL animation library |
| `packages/ui/src/components/mesh-gradient.tsx` | Uses `stripe-gradient` (the WebGL lib), not Stripe payments |
| Desktop `showsStandaloneActiveStripe` variable | Visual "stripe" highlight, not the payment platform |
| `packages/db/drizzle/meta/` | Auto-generated Drizzle snapshots; updated via migration |
| `packages/shared/src/billing.ts` | Abstract billing types, no Stripe coupling |
| `apps/desktop/src/renderer/components/Paywall/` | Already a correct pass-through |
| `apps/desktop/src/renderer/hooks/useCurrentPlan.ts` | Works without Stripe data (falls back to "free") |

---

## Execution Order

1. **Phase 1** — Delete `apps/api/src/app/api/integrations/stripe/`, remove `stripe` dep
2. **Phase 2** — Clean env vars (all 5 env.ts files, .env.example, CI workflows)
3. **Phase 3** — Strip Stripe columns from DB schema, generate migration
4. **Phase 4** — Simplify billing router (remove portal mutation)
5. **Phase 5** — Update host router and membership utils to remove Stripe coupling
6. **Phase 6** — Stub/remove billing page
7. **Phase 7** — Misc cleanup (README, mock data, bun install)
8. **Phase 8** — Full validation (typecheck, lint, test, build, grep)

---

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Existing DB rows have `stripe_customer_id` values | Migration drops the columns; data is lost but it's orphaned Stripe metadata with no code to use it |
| CI workflows break if secrets are still referenced | Remove all `STRIPE_*` and `SLACK_BILLING_WEBHOOK_URL` references in Phase 2; Vercel/CI secret vars can be cleaned up separately |
| `checkAccess` query in host router changes behavior | After removing Stripe columns, the subscription join still works (just never matches on `stripeCustomerId`). Could simplify to always return `paidPlan: true` in single-user mode |
| `billing.activePlan` callers break | Keep the billing router stub returning `{ plan: "free" }` |
