// Single-user fork: billing is disabled, so the Paywall is a pass-through that
// never gates content. We keep the surface so existing call sites compile.
import type { ReactNode } from "react";

export interface PaywallProps {
	children?: ReactNode;
	feature?: string;
}

export function Paywall({ children = null }: PaywallProps) {
	return children;
}

export const GATED_FEATURES = {
	V2_WORKSPACES: "v2_workspaces",
	REMOTE_CONTROL: "remote_control",
	REMOTE_WORKSPACES: "remote_workspaces",
	AUTOMATIONS: "automations",
	MULTI_HOST: "multi_host",
	TASKS: "tasks",
} as const;

export function usePaywall() {
	return {
		isGated: false,
		canAccess: true,
		open: () => {},
		close: () => {},
		gateFeature: (_feature?: string, _opts?: unknown) => true,
	};
}
