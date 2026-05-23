import { db } from "@superset/db/client";
import { githubPullRequests, githubRepositories } from "@superset/db/schema";
import type { TRPCRouterRecord } from "@trpc/server";
import { Client } from "@upstash/qstash";
import { and, desc, eq, inArray } from "drizzle-orm";
import { z } from "zod";
import { env } from "../../../env";
import { ghGraphQL, ghStatus } from "../../../lib/gh";
import { protectedProcedure } from "../../../trpc";
import { verifyOrgMembership } from "../utils";

const qstash = new Client({ token: env.QSTASH_TOKEN });

const PR_FIELDS = `
	number
	url
	title
	state
	isDraft
	createdAt
	updatedAt
	mergedAt
	closedAt
	additions
	deletions
	changedFiles
	reviewDecision
	author { login ... on User { avatarUrl } }
	repository { nameWithOwner }
	headRefName
	baseRefName
	statusCheckRollup {
		state
	}
`;

type GhPrAuthor = { login: string; avatarUrl?: string } | null;
type GhSearchPr = {
	number: number;
	url: string;
	title: string;
	state: string;
	isDraft: boolean;
	updatedAt: string;
	additions: number;
	deletions: number;
	changedFiles: number;
	reviewDecision: string | null;
	author: GhPrAuthor;
	repository: { nameWithOwner: string };
	headRefName: string;
	baseRefName: string;
	statusCheckRollup: { state: string } | null;
};

async function searchPrs(query: string): Promise<GhSearchPr[]> {
	const data = await ghGraphQL<{
		search: { nodes: GhSearchPr[] };
	}>(
		`query($q: String!) {
			search(query: $q, type: ISSUE, first: 50) {
				nodes { ... on PullRequest { ${PR_FIELDS} } }
			}
		}`,
		{ q: query },
	);
	return data.search.nodes.filter((node) => node.number !== undefined);
}

export const githubRouter = {
	status: protectedProcedure.query(async () => {
		return ghStatus();
	}),

	myPullRequests: protectedProcedure.query(async () => {
		const status = await ghStatus();
		if (!status.available) {
			return { authored: [], reviewRequested: [] };
		}

		const [authored, reviewRequested] = await Promise.all([
			searchPrs("is:pr is:open author:@me archived:false sort:updated-desc"),
			searchPrs(
				"is:pr is:open review-requested:@me archived:false sort:updated-desc",
			),
		]);

		return { authored, reviewRequested };
	}),

	listRepositories: protectedProcedure
		.input(z.object({ organizationId: z.string().uuid() }))
		.query(async ({ ctx, input }) => {
			await verifyOrgMembership(ctx.session.user.id, input.organizationId);
			return db.query.githubRepositories.findMany({
				where: eq(githubRepositories.organizationId, input.organizationId),
				orderBy: [desc(githubRepositories.updatedAt)],
			});
		}),

	listPullRequests: protectedProcedure
		.input(
			z.object({
				organizationId: z.string().uuid(),
				repositoryId: z.string().uuid().optional(),
				state: z.enum(["open", "closed", "all"]).optional().default("open"),
			}),
		)
		.query(async ({ ctx, input }) => {
			await verifyOrgMembership(ctx.session.user.id, input.organizationId);

			const repos = await db.query.githubRepositories.findMany({
				where: input.repositoryId
					? and(
							eq(githubRepositories.organizationId, input.organizationId),
							eq(githubRepositories.id, input.repositoryId),
						)
					: eq(githubRepositories.organizationId, input.organizationId),
				columns: { id: true },
			});

			if (repos.length === 0) return [];

			const repoIds = repos.map((r) => r.id);
			const conditions = [inArray(githubPullRequests.repositoryId, repoIds)];
			if (input.state !== "all") {
				conditions.push(eq(githubPullRequests.state, input.state));
			}

			return db.query.githubPullRequests.findMany({
				where: and(...conditions),
				with: {
					repository: {
						columns: { id: true, fullName: true, owner: true, name: true },
					},
				},
				orderBy: [desc(githubPullRequests.updatedAt)],
				limit: 100,
			});
		}),

	triggerSync: protectedProcedure
		.input(z.object({ organizationId: z.string().uuid() }))
		.mutation(async ({ ctx, input }) => {
			await verifyOrgMembership(ctx.session.user.id, input.organizationId);

			const syncUrl = `${env.NEXT_PUBLIC_API_URL}/api/github/jobs/sync`;
			const syncBody = { organizationId: input.organizationId };

			if (env.NODE_ENV === "development") {
				fetch(syncUrl, {
					method: "POST",
					headers: { "Content-Type": "application/json" },
					body: JSON.stringify(syncBody),
				}).catch((error) => {
					console.error("[github/triggerSync] Dev sync failed:", error);
				});
			} else {
				await qstash.publishJSON({
					url: syncUrl,
					body: syncBody,
					retries: 3,
				});
			}

			return { success: true };
		}),
} satisfies TRPCRouterRecord;
