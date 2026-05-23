import { db } from "@superset/db/client";
import { organizations } from "@superset/db/schema";
import { SINGLE_ORG_ID } from "@superset/shared/single-user";
import { TRPCError, type TRPCRouterRecord } from "@trpc/server";
import { eq } from "drizzle-orm";
import { z } from "zod";
import { generateImagePathname, uploadImage } from "../../lib/upload";
import { jwtProcedure, protectedProcedure } from "../../trpc";
import { organizationMembersRouter } from "./members";

// Single-user fork: there is exactly one organization (SINGLE_ORG_ID). Most of
// the historical multi-tenant operations (invitations, member management,
// leave) are stubs that throw or no-op so existing UI surfaces keep compiling.

async function loadSingleOrg() {
	return (
		(await db.query.organizations.findFirst({
			where: eq(organizations.id, SINGLE_ORG_ID),
			columns: { id: true, name: true, slug: true },
		})) ?? null
	);
}

const notSupported = (message: string) => {
	throw new TRPCError({ code: "NOT_IMPLEMENTED", message });
};

export const organizationRouter = {
	members: organizationMembersRouter,

	getActive: protectedProcedure.query(async () => loadSingleOrg()),
	getActiveFromJwt: jwtProcedure.query(async () => loadSingleOrg()),
	getByIdFromJwt: jwtProcedure
		.input(z.object({ id: z.string() }))
		.query(async ({ input }) =>
			input.id === SINGLE_ORG_ID ? loadSingleOrg() : null,
		),

	getInvitation: protectedProcedure
		.input(z.uuid())
		.query(async () => notSupported("Invitations are disabled")),

	getInvitationPreview: protectedProcedure
		.input(z.object({ invitationId: z.uuid(), token: z.string().min(1) }))
		.query(async () => notSupported("Invitations are disabled")),

	create: protectedProcedure
		.input(
			z.object({
				name: z.string().min(1),
				slug: z.string().min(1),
				logo: z.string().url().optional(),
			}),
		)
		.mutation(async () =>
			notSupported(
				"Cannot create additional organizations in single-user mode",
			),
		),

	update: protectedProcedure
		.input(
			z.object({
				id: z.string().uuid(),
				name: z.string().min(1).max(100).optional(),
				slug: z
					.string()
					.min(3)
					.max(50)
					.regex(/^[a-z0-9-]+$/)
					.regex(/^[a-z0-9]/)
					.regex(/[a-z0-9]$/)
					.optional(),
				logo: z.string().url().optional(),
			}),
		)
		.mutation(async ({ input }) => {
			const { id, ...data } = input;
			if (id !== SINGLE_ORG_ID) {
				throw new TRPCError({ code: "FORBIDDEN", message: "Unknown org" });
			}
			const [organization] = await db
				.update(organizations)
				.set(data)
				.where(eq(organizations.id, id))
				.returning();
			return organization;
		}),

	uploadLogo: protectedProcedure
		.input(
			z.object({
				organizationId: z.string().uuid(),
				fileData: z.string(),
				fileName: z.string(),
				mimeType: z.string(),
			}),
		)
		.mutation(async ({ input }) => {
			if (input.organizationId !== SINGLE_ORG_ID) {
				throw new TRPCError({ code: "FORBIDDEN", message: "Unknown org" });
			}

			const organization = await db.query.organizations.findFirst({
				where: eq(organizations.id, input.organizationId),
			});

			if (!organization) {
				throw new TRPCError({
					code: "NOT_FOUND",
					message: "Organization not found",
				});
			}

			const pathname = generateImagePathname({
				prefix: `organization/${input.organizationId}/logo`,
				mimeType: input.mimeType,
			});

			const url = await uploadImage({
				fileData: input.fileData,
				mimeType: input.mimeType,
				pathname,
				existingUrl: organization.logo,
			});

			const [updatedOrg] = await db
				.update(organizations)
				.set({ logo: url })
				.where(eq(organizations.id, input.organizationId))
				.returning();

			return { success: true, url, organization: updatedOrg };
		}),

	addMember: protectedProcedure
		.input(
			z.object({
				organizationId: z.string().uuid(),
				userId: z.string().uuid(),
			}),
		)
		.mutation(async () => notSupported("Member management is disabled")),

	removeMember: protectedProcedure
		.input(z.object({ organizationId: z.uuid(), userId: z.uuid() }))
		.mutation(async () => notSupported("Member management is disabled")),

	leave: protectedProcedure
		.input(z.object({ organizationId: z.uuid() }))
		.mutation(async () => notSupported("Member management is disabled")),

	updateMemberRole: protectedProcedure
		.input(
			z.object({
				organizationId: z.string().uuid(),
				memberId: z.string().uuid(),
				role: z.enum(["owner", "admin", "member"]),
			}),
		)
		.mutation(async () => notSupported("Member management is disabled")),
} satisfies TRPCRouterRecord;
