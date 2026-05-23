import { TRPCError, type TRPCRouterRecord } from "@trpc/server";
import { z } from "zod";
import { protectedProcedure } from "../../trpc";

// Single-user fork: teams were an org sub-grouping for multi-user accounts.
// Membership management is disabled here so the only operations left are
// no-ops that report the feature as unavailable.

const teamDisabled = () => {
	throw new TRPCError({
		code: "NOT_IMPLEMENTED",
		message: "Team membership is disabled in single-user mode",
	});
};

export const teamRouter = {
	addMember: protectedProcedure
		.input(
			z.object({
				teamId: z.string().uuid(),
				userId: z.string().uuid(),
			}),
		)
		.mutation(async () => teamDisabled()),

	removeMember: protectedProcedure
		.input(
			z.object({
				teamId: z.string().uuid(),
				userId: z.string().uuid(),
			}),
		)
		.mutation(async () => teamDisabled()),
} satisfies TRPCRouterRecord;
