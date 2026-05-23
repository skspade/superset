// Single-user fork: mobile app has no real auth. Expose stubs that satisfy
// the existing call sites with the synthetic user.

const SINGLE_USER_ID = "00000000-0000-0000-0000-000000000001";
const SINGLE_ORG_ID = "00000000-0000-0000-0000-000000000002";

const syntheticSession = {
	user: {
		id: SINGLE_USER_ID,
		email: "local@superset.local",
		name: "Local User",
		image: null as string | null,
		emailVerified: true,
	},
	session: {
		id: "local",
		userId: SINGLE_USER_ID,
		activeOrganizationId: SINGLE_ORG_ID,
		organizationIds: [SINGLE_ORG_ID],
		token: "local",
	},
};

type Session = typeof syntheticSession;

interface AuthError {
	message?: string;
	code?: string;
}

const ok = async (..._args: unknown[]) => ({
	data: { success: true },
	error: null as AuthError | null,
});

export function useSession() {
	return { data: syntheticSession, isPending: false, error: null };
}

export const authClient = {
	useSession,
	signIn: {
		social: ok,
		email: ok,
	},
	signOut: ok,
	signUp: { email: ok },
	organization: {
		setActive: ok,
		list: async () => ({ data: [], error: null as AuthError | null }),
	},
	getCookie: () => null,
};

export const signIn = authClient.signIn;
export const signOut = authClient.signOut;
export const signUp = authClient.signUp;

export type AuthSession = Session;
