import {
	SINGLE_ORG_ID,
	SINGLE_ORG_NAME,
	SINGLE_ORG_SLUG,
	SINGLE_USER_EMAIL,
	SINGLE_USER_ID,
	SINGLE_USER_NAME,
} from "@superset/shared/single-user";
import { db } from "./client";
import { members, organizations, users } from "./schema";
import { seedDefaultStatuses } from "./seed-default-statuses";

/**
 * Single-user fork: every foreign key that points at users/organizations/members
 * resolves to one synthetic identity. This seed guarantees those rows exist on
 * first boot so the rest of the app's writes don't violate FK constraints.
 *
 * Safe to re-run; all inserts are onConflictDoNothing.
 */
export async function seedSingleUser(): Promise<void> {
	await db
		.insert(users)
		.values({
			id: SINGLE_USER_ID,
			email: SINGLE_USER_EMAIL,
			name: SINGLE_USER_NAME,
			emailVerified: true,
			organizationIds: [SINGLE_ORG_ID],
		})
		.onConflictDoNothing();

	await db
		.insert(organizations)
		.values({
			id: SINGLE_ORG_ID,
			name: SINGLE_ORG_NAME,
			slug: SINGLE_ORG_SLUG,
		})
		.onConflictDoNothing();

	await db
		.insert(members)
		.values({
			organizationId: SINGLE_ORG_ID,
			userId: SINGLE_USER_ID,
			role: "owner",
		})
		.onConflictDoNothing();

	await seedDefaultStatuses(SINGLE_ORG_ID);
}
