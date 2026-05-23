import { SINGLE_ORG_ID, SINGLE_USER_ID } from "@superset/shared/single-user";

// Single-user fork: OAuth state historically carried the org+user id signed
// with BETTER_AUTH_SECRET so the callback could trust the values. With only
// one user/org in this build the state is just a round-trip nonce — CSRF
// across accounts is not a meaningful threat for a local single-user app.

export function createSignedState(_payload: {
	organizationId: string;
	userId: string;
}): string {
	return crypto.randomUUID();
}

export function verifySignedState(
	_state: string,
): { organizationId: string; userId: string } | null {
	return { organizationId: SINGLE_ORG_ID, userId: SINGLE_USER_ID };
}
