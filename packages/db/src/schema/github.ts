import {
	boolean,
	index,
	integer,
	jsonb,
	pgTable,
	text,
	timestamp,
	unique,
	uuid,
} from "drizzle-orm/pg-core";

import { organizations } from "./auth";

/**
 * GitHub repositories tracked by an organization. Populated on demand from
 * the `gh` CLI (see packages/trpc/src/router/integration/github/repo-upsert.ts)
 * — there is no per-org GitHub App installation in this fork.
 */
export const githubRepositories = pgTable(
	"github_repositories",
	{
		id: uuid().primaryKey().defaultRandom(),

		organizationId: uuid("organization_id")
			.notNull()
			.references(() => organizations.id, { onDelete: "cascade" }),

		repoId: text("repo_id").notNull().unique(),
		owner: text().notNull(),
		name: text().notNull(),
		fullName: text("full_name").notNull(),
		defaultBranch: text("default_branch").notNull().default("main"),
		isPrivate: boolean("is_private").notNull().default(false),

		createdAt: timestamp("created_at").notNull().defaultNow(),
		updatedAt: timestamp("updated_at")
			.notNull()
			.defaultNow()
			.$onUpdate(() => new Date()),
	},
	(table) => [
		index("github_repositories_full_name_idx").on(table.fullName),
		index("github_repositories_org_id_idx").on(table.organizationId),
	],
);

export type InsertGithubRepository = typeof githubRepositories.$inferInsert;
export type SelectGithubRepository = typeof githubRepositories.$inferSelect;

/**
 * GitHub pull requests tracked for synced repositories. Populated by the
 * scheduled sync job at apps/api/src/app/api/github/jobs/sync/route.ts.
 */
export const githubPullRequests = pgTable(
	"github_pull_requests",
	{
		id: uuid().primaryKey().defaultRandom(),

		repositoryId: uuid("repository_id")
			.notNull()
			.references(() => githubRepositories.id, { onDelete: "cascade" }),

		organizationId: uuid("organization_id")
			.notNull()
			.references(() => organizations.id, { onDelete: "cascade" }),

		prNumber: integer("pr_number").notNull(),
		nodeId: text("node_id").notNull(),

		headBranch: text("head_branch").notNull(),
		headSha: text("head_sha").notNull(),
		baseBranch: text("base_branch").notNull(),

		title: text().notNull(),
		url: text().notNull(),
		authorLogin: text("author_login").notNull(),
		authorAvatarUrl: text("author_avatar_url"),

		state: text().notNull(),
		isDraft: boolean("is_draft").notNull().default(false),

		additions: integer().notNull().default(0),
		deletions: integer().notNull().default(0),
		changedFiles: integer("changed_files").notNull().default(0),

		reviewDecision: text("review_decision"),

		checksStatus: text("checks_status").notNull().default("none"),
		checks: jsonb()
			.$type<
				Array<{
					name: string;
					status: string;
					conclusion: string | null;
					detailsUrl?: string;
				}>
			>()
			.default([]),

		mergedAt: timestamp("merged_at"),
		closedAt: timestamp("closed_at"),
		lastSyncedAt: timestamp("last_synced_at"),

		createdAt: timestamp("created_at").notNull().defaultNow(),
		updatedAt: timestamp("updated_at").notNull().defaultNow(),
	},
	(table) => [
		unique("github_pull_requests_repo_pr_unique").on(
			table.repositoryId,
			table.prNumber,
		),
		index("github_pull_requests_repository_id_idx").on(table.repositoryId),
		index("github_pull_requests_state_idx").on(table.state),
		index("github_pull_requests_head_branch_idx").on(table.headBranch),
		index("github_pull_requests_org_id_idx").on(table.organizationId),
	],
);

export type InsertGithubPullRequest = typeof githubPullRequests.$inferInsert;
export type SelectGithubPullRequest = typeof githubPullRequests.$inferSelect;
