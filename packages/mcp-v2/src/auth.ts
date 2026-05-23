import {
	SINGLE_ORG_ID,
	SINGLE_USER_EMAIL,
	SINGLE_USER_ID,
} from "@superset/shared/single-user";

export interface McpContext {
	userId: string;
	email: string;
	organizationId: string;
	organizationIds: string[];
	source: "api-key" | "oauth" | "local";
	clientLabel: string | null;
	requestId: string;
	bearerToken: string;
	relayUrl: string;
}

const MCP_UNAUTHORIZED = Symbol("MCP_UNAUTHORIZED");
export { MCP_UNAUTHORIZED };

export class McpUnauthorizedError extends Error {
	readonly tag = MCP_UNAUTHORIZED;
	constructor(message = "Unauthorized") {
		super(message);
		this.name = "McpUnauthorizedError";
	}
}

export function isMcpUnauthorized(
	error: unknown,
): error is McpUnauthorizedError {
	return (
		error instanceof Error &&
		(error as { tag?: symbol }).tag === MCP_UNAUTHORIZED
	);
}

export interface ResolveMcpContextOptions {
	apiUrl: string;
	relayUrl: string;
}

// Single-user fork: MCP requests resolve to the local synthetic user
// unconditionally. The bearer token is a placeholder downstream callers can
// treat as opaque (they no longer verify it).
export async function resolveMcpContext(
	_req: Request,
	options: ResolveMcpContextOptions,
): Promise<McpContext> {
	return {
		userId: SINGLE_USER_ID,
		email: SINGLE_USER_EMAIL,
		organizationId: SINGLE_ORG_ID,
		organizationIds: [SINGLE_ORG_ID],
		source: "local",
		clientLabel: null,
		requestId: crypto.randomUUID(),
		bearerToken: "local",
		relayUrl: options.relayUrl,
	};
}
