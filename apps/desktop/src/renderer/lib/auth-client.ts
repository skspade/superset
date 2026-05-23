import {
	SINGLE_ORG_ID,
	SINGLE_USER_EMAIL,
	SINGLE_USER_ID,
	SINGLE_USER_NAME,
} from "@superset/shared/single-user";

// Single-user fork: the desktop app no longer pairs with a remote relay through
// OAuth. The stored "auth token" / "jwt" are now opaque PSKs the user (or the
// app itself) sets for talking to the local host-service. We keep the
// setAuthToken / setJwt API so existing call sites continue to work, but the
// authClient is a permissive stub that returns the synthetic session.

let authToken: string | null = null;
let jwt: string | null = null;

export function setAuthToken(token: string | null) {
	authToken = token;
}
export function getAuthToken(): string | null {
	return authToken;
}
export function setJwt(token: string | null) {
	jwt = token;
}
export function getJwt(): string | null {
	return jwt;
}

const syntheticUser = {
	id: SINGLE_USER_ID,
	email: SINGLE_USER_EMAIL,
	name: SINGLE_USER_NAME,
	image: null as string | null,
	emailVerified: true,
	onboardedAt: new Date(0),
	createdAt: new Date(0),
	updatedAt: new Date(0),
};

const syntheticSession = {
	user: syntheticUser,
	session: {
		id: "local",
		userId: SINGLE_USER_ID,
		activeOrganizationId: SINGLE_ORG_ID as string | null,
		organizationIds: [SINGLE_ORG_ID],
		role: "owner" as const,
		plan: "free" as const,
		token: "local",
		expiresAt: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000),
	},
};

const syntheticOrganization = {
	id: SINGLE_ORG_ID,
	name: "Local",
	slug: "local",
	logo: null,
	members: [
		{
			id: SINGLE_USER_ID,
			userId: SINGLE_USER_ID,
			organizationId: SINGLE_ORG_ID,
			role: "owner",
			user: syntheticUser,
		},
	],
};

type Session = typeof syntheticSession;

// biome-ignore lint/suspicious/noExplicitAny: stub returns must be permissively typed for ~50 desktop call sites
type Any = any;

const ok = async (..._args: Any[]): Promise<{ data: Any; error: null }> => ({
	data: {} as Any,
	error: null,
});

const okList = async (
	..._args: Any[]
): Promise<{ data: Any[]; error: null }> => ({
	data: [] as Any[],
	error: null,
});

function makeQueryHook<T>(value: T) {
	return () => ({
		data: value,
		isPending: false,
		isRefetching: false,
		error: null,
		refetch: async () => ({ data: value, error: null }),
	});
}

export const authClient = {
	useSession: makeQueryHook(syntheticSession),
	useActiveOrganization: makeQueryHook(syntheticOrganization),
	useListOrganizations: makeQueryHook([syntheticOrganization]),
	getSession: async () => ({ data: syntheticSession, error: null }),
	signIn: { social: ok, email: ok },
	signOut: ok,
	signUp: { email: ok },
	token: async () => ({ data: { token: "local" }, error: null }),
	organization: {
		setActive: ok,
		create: ok,
		list: async () => ({ data: [syntheticOrganization], error: null }),
		listMembers: async () => ({
			data: syntheticOrganization.members,
			error: null,
		}),
		getInvitation: async () => ({ data: null, error: null }),
		acceptInvitation: ok,
		rejectInvitation: ok,
		cancelInvitation: ok,
		inviteMember: ok,
		removeMember: ok,
		updateMemberRole: ok,
		listInvitations: okList,
		leave: ok,
		update: ok,
		checkSlug: async () => ({ data: { status: true }, error: null }),
		createTeam: ok,
		updateTeam: ok,
		removeTeam: ok,
	},
	apiKey: {
		create: ok,
		list: okList,
		delete: ok,
	},
	subscription: {
		list: okList,
		create: ok,
		cancel: ok,
		upgrade: ok,
		restore: ok,
	},
	updateUser: ok,
};

export type AuthSession = Session;
