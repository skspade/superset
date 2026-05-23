import { TRPCError } from "@trpc/server";
import { z } from "zod";

import { protectedProcedure } from "../../trpc";

export const apiKeyRouter = {
	create: protectedProcedure
		.input(z.object({ name: z.string().min(1) }))
		.mutation(async () => {
			throw new TRPCError({
				code: "NOT_IMPLEMENTED",
				message: "API keys are disabled in single-user mode",
			});
		}),
};
