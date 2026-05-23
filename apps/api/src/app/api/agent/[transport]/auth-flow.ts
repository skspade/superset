import type { AuthInfo } from "@modelcontextprotocol/sdk/server/auth/types.js";
import type { WebStandardStreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/webStandardStreamableHttp.js";
import type { createMcpServer } from "@superset/mcp";
import type { McpContext } from "@superset/mcp/auth";
import { SINGLE_ORG_ID, SINGLE_USER_ID } from "@superset/shared/single-user";

export interface McpRequestDeps {
	createServer: typeof createMcpServer;
	createTransport: () => WebStandardStreamableHTTPServerTransport;
}

function buildLocalAuthInfo(): AuthInfo {
	return {
		token: "local",
		clientId: "local",
		scopes: ["mcp:full"],
		extra: {
			mcpContext: {
				userId: SINGLE_USER_ID,
				organizationId: SINGLE_ORG_ID,
			} satisfies McpContext,
		},
	};
}

export async function handleMcpRequest(
	req: Request,
	deps: McpRequestDeps,
): Promise<Response> {
	const transport = deps.createTransport();
	const server = deps.createServer();
	await server.connect(transport);

	return transport.handleRequest(req, { authInfo: buildLocalAuthInfo() });
}
