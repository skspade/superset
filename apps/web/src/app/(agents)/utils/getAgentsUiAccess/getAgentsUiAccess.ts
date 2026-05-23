import { cache } from "react";

export const getAgentsUiAccess = cache(async () => ({
	hasAgentsUiAccess: true,
}));
