import {
	SINGLE_ORG_ID,
	SINGLE_USER_EMAIL,
	SINGLE_USER_ID,
	SINGLE_USER_NAME,
} from "@superset/shared/single-user";
import { initTRPC } from "@trpc/server";
import superjson from "superjson";
import { ZodError } from "zod";

// Single-user fork: the "session" is a build-time constant. Procedures that
// historically required auth (protectedProcedure, adminProcedure, jwtProcedure)
// now resolve to the same synthetic identity so the 30+ existing routers can
// keep reading ctx.session.user.id / ctx.userId without changes.
export type Session = {
	user: {
		id: string;
		email: string;
		name: string;
		image: string | null;
		emailVerified: boolean;
		onboardedAt: Date | null;
		createdAt: Date;
		updatedAt: Date;
	};
	session: { activeOrganizationId: string | null };
};

const SYNTHETIC_SESSION: Session = {
	user: {
		id: SINGLE_USER_ID,
		email: SINGLE_USER_EMAIL,
		name: SINGLE_USER_NAME,
		image: null,
		emailVerified: true,
		onboardedAt: new Date(0),
		createdAt: new Date(0),
		updatedAt: new Date(0),
	},
	session: { activeOrganizationId: SINGLE_ORG_ID },
};

export type TRPCContext = {
	session: Session;
	headers: Headers;
};

export const createTRPCContext = (opts: { headers: Headers }): TRPCContext => ({
	session: SYNTHETIC_SESSION,
	headers: opts.headers,
});

const t = initTRPC.context<TRPCContext>().create({
	transformer: superjson,
	errorFormatter({ shape, error }) {
		return {
			...shape,
			data: {
				...shape.data,
				zodError:
					error.cause instanceof ZodError ? error.cause.flatten() : null,
			},
		};
	},
});

export const createTRPCRouter = t.router;

export const createCallerFactory = t.createCallerFactory;

export const publicProcedure = t.procedure;

export const protectedProcedure = t.procedure.use(async ({ ctx, next }) =>
	next({ ctx: { ...ctx, activeOrganizationId: SINGLE_ORG_ID } }),
);

export const jwtProcedure = t.procedure.use(async ({ ctx, next }) =>
	next({
		ctx: {
			...ctx,
			userId: SINGLE_USER_ID,
			email: SINGLE_USER_EMAIL,
			organizationIds: [SINGLE_ORG_ID],
			activeOrganizationId: SINGLE_ORG_ID,
		},
	}),
);

export const adminProcedure = protectedProcedure;
