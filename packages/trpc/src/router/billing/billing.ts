import { TRPCError, type TRPCRouterRecord } from "@trpc/server";
import { z } from "zod";
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

	portal: protectedProcedure
		.input(
			z.object({
				flowType: z
					.enum(["payment_method_update", "general"])
					.optional()
					.default("general"),
			}),
		)
		.mutation(async () => {
			throw new TRPCError({
				code: "NOT_IMPLEMENTED",
				message: "Billing is disabled in single-user mode",
			});
		}),
} satisfies TRPCRouterRecord;
