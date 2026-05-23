"use client";

import {
	SINGLE_USER_EMAIL,
	SINGLE_USER_ID,
	SINGLE_USER_NAME,
} from "@superset/shared/single-user";
import posthog from "posthog-js";
import { useEffect } from "react";

export function PostHogUserIdentifier() {
	useEffect(() => {
		posthog.identify(SINGLE_USER_ID, {
			email: SINGLE_USER_EMAIL,
			name: SINGLE_USER_NAME,
		});
	}, []);

	return null;
}
