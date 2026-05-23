import { ORGANIZATION_HEADER } from "@superset/shared/constants";
import {
	createTRPCContext,
	createCaller as makeAppCaller,
} from "@superset/trpc";
import type { McpContext } from "./auth";

export type McpCaller = ReturnType<typeof makeAppCaller>;

/**
 * Build a tRPC server-side caller for the AppRouter from an MCP context.
 *
 * Single-user fork: the tRPC context is hydrated from build-time constants
 * (see packages/trpc/src/trpc.ts), so this caller just forwards the headers
 * that downstream procedures still inspect (org id, optional bearer token).
 */
export function createMcpCaller(ctx: McpContext): McpCaller {
	const headers = new Headers();
	headers.set(ORGANIZATION_HEADER, ctx.organizationId);

	return makeAppCaller(createTRPCContext({ headers }));
}
