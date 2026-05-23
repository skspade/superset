import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { InMemoryTransport } from "@modelcontextprotocol/sdk/inMemory.js";
import {
	SINGLE_ORG_ID,
	SINGLE_USER_EMAIL,
	SINGLE_USER_ID,
} from "@superset/shared/single-user";
import type { McpContext } from "./auth";
import type { McpToolCallEmitter } from "./define-tool";
import { createMcpServer } from "./server";

export interface InMemoryClientOptions {
	userId: string;
	organizationId: string;
	clientLabel: string;
	relayUrl: string;
	onToolCall?: McpToolCallEmitter;
}

/**
 * Build an in-memory MCP client/server pair for server-side agent integrations.
 *
 * Single-user fork: the supplied userId/organizationId arguments are accepted
 * but always resolve to the local synthetic identity downstream.
 */
export async function createInMemoryMcpClient({
	organizationId,
	clientLabel,
	relayUrl,
	onToolCall,
}: InMemoryClientOptions): Promise<{
	client: Client;
	cleanup: () => Promise<void>;
}> {
	const mcpContext: McpContext = {
		userId: SINGLE_USER_ID,
		email: SINGLE_USER_EMAIL,
		organizationId: organizationId || SINGLE_ORG_ID,
		organizationIds: [SINGLE_ORG_ID],
		source: "local",
		clientLabel,
		requestId: crypto.randomUUID(),
		bearerToken: "local",
		relayUrl,
	};

	const server = createMcpServer({ onToolCall });
	const [serverTransport, clientTransport] =
		InMemoryTransport.createLinkedPair();

	const originalSend = clientTransport.send.bind(clientTransport);
	clientTransport.send = (message, options) =>
		originalSend(message, {
			...options,
			authInfo: {
				token: "internal",
				clientId: "mcp-v2-internal",
				scopes: ["mcp:full"],
				extra: { mcpContext },
			},
		});

	await server.connect(serverTransport);

	const client = new Client({
		name: "superset-v2-internal",
		version: "1.0.0",
	});
	await client.connect(clientTransport);

	return {
		client,
		cleanup: async () => {
			await client.close();
			await server.close();
		},
	};
}
