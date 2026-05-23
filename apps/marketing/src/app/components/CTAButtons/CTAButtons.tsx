import { env } from "@/env";
import { HeaderCTA } from "./HeaderCTA";

export async function CTAButtons() {
	// Single-user fork: there's no separate signed-out state to gate on.
	return <HeaderCTA isLoggedIn={true} dashboardUrl={env.NEXT_PUBLIC_WEB_URL} />;
}
