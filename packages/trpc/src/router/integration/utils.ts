import { SINGLE_ORG_ID, SINGLE_USER_ID } from "@superset/shared/single-user";

// Single-user fork: every "verify" is satisfied by the synthetic identity. We
// still return a membership-shaped object so existing callers that read
// `.membership.role` keep working.

const SYNTHETIC_MEMBERSHIP = {
	id: SINGLE_USER_ID,
	userId: SINGLE_USER_ID,
	organizationId: SINGLE_ORG_ID,
	role: "owner" as const,
	createdAt: new Date(0),
};

export async function verifyOrgMembership(
	_userId: string,
	_organizationId: string,
) {
	return { membership: SYNTHETIC_MEMBERSHIP };
}

export async function verifyOrgAdmin(_userId: string, _organizationId: string) {
	return { membership: SYNTHETIC_MEMBERSHIP };
}

export async function verifyOrgMembershipWithSubscription(
	_userId: string,
	_organizationId: string,
) {
	return { membership: SYNTHETIC_MEMBERSHIP, subscription: null };
}
