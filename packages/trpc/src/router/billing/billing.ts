import type { TRPCRouterRecord } from "@trpc/server";
import { protectedProcedure } from "../../trpc";

// Single-user fork: no subscriptions, no Stripe. Surface a static "free" plan
// so existing callers (Header chrome, settings/billing page) keep working
// without paying for the Stripe round-trip.

export const billingRouter = {
	activePlan: protectedProcedure.query(async () => ({
		plan: "free" as const,
		status: null,
	})),

	invoices: protectedProcedure.query(async () => []),

	details: protectedProcedure.query(async () => null),
} satisfies TRPCRouterRecord;
