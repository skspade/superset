import { SINGLE_ORG_ID, SINGLE_USER_ID } from "@superset/shared/single-user";

import { env } from "@/env";
import { createSignedState } from "@/lib/oauth-state";

export async function GET(_request: Request) {
	const state = createSignedState({
		organizationId: SINGLE_ORG_ID,
		userId: SINGLE_USER_ID,
	});

	const linearAuthUrl = new URL("https://linear.app/oauth/authorize");
	linearAuthUrl.searchParams.set("client_id", env.LINEAR_CLIENT_ID);
	linearAuthUrl.searchParams.set(
		"redirect_uri",
		`${env.NEXT_PUBLIC_API_URL}/api/integrations/linear/callback`,
	);
	linearAuthUrl.searchParams.set("response_type", "code");
	linearAuthUrl.searchParams.set("scope", "read,write,issues:create");
	linearAuthUrl.searchParams.set("state", state);

	return Response.redirect(linearAuthUrl.toString());
}
