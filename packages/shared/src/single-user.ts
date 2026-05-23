// Single-user fork: there is one user and one organization at runtime.
// These IDs are stable across boots and seeded into the auth tables so
// foreign keys (projects.organization_id, members.user_id, etc.) resolve.
export const SINGLE_USER_ID = "00000000-0000-0000-0000-000000000001";
export const SINGLE_ORG_ID = "00000000-0000-0000-0000-000000000002";
export const SINGLE_USER_EMAIL = "local@superset.local";
export const SINGLE_USER_NAME = "Local User";
export const SINGLE_ORG_NAME = "Local";
export const SINGLE_ORG_SLUG = "local";
