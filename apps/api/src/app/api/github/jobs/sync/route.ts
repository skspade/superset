// Pulls PR data for tracked repos using the `gh` CLI on the API host.
// Replaces the old GitHub-App + webhook pipeline. Configure a QStash schedule
// pointing at this route every 10 minutes.

import { db } from "@superset/db/client";
import { githubPullRequests, githubRepositories } from "@superset/db/schema";
import { ghGraphQL } from "@superset/trpc/lib/gh";
import { Receiver } from "@upstash/qstash";
import { subDays } from "date-fns";
import { eq } from "drizzle-orm";
import { z } from "zod";
import { env } from "@/env";

const receiver = new Receiver({
	currentSigningKey: env.QSTASH_CURRENT_SIGNING_KEY,
	nextSigningKey: env.QSTASH_NEXT_SIGNING_KEY,
});

const payloadSchema = z.object({
	organizationId: z.string().uuid(),
});

type GhPr = {
	number: number;
	id: string;
	title: string;
	url: string;
	state: string;
	isDraft: boolean;
	author: { login?: string; avatarUrl?: string } | null;
	headRefName: string;
	headRefOid: string;
	baseRefName: string;
	additions: number;
	deletions: number;
	changedFiles: number;
	reviewDecision: string | null;
	mergedAt: string | null;
	closedAt: string | null;
	updatedAt: string;
	statusCheckRollup: {
		state: string;
		contexts: { nodes: Array<GhCheckRun | GhStatusContext> };
	} | null;
};

type GhCheckRun = {
	__typename: "CheckRun";
	name: string;
	conclusion: string | null;
	status: string;
	detailsUrl: string | null;
};

type GhStatusContext = {
	__typename: "StatusContext";
	context: string;
	state: string;
	targetUrl: string | null;
};

type RepoPrsResponse = {
	repository: {
		pullRequests: {
			pageInfo: { hasNextPage: boolean; endCursor: string | null };
			nodes: GhPr[];
		};
	} | null;
};

const REPO_PRS_QUERY = `
query RepoPRs($owner: String!, $name: String!, $cursor: String) {
	repository(owner: $owner, name: $name) {
		pullRequests(first: 50, after: $cursor, orderBy: { field: UPDATED_AT, direction: DESC }) {
			pageInfo { hasNextPage endCursor }
			nodes {
				number
				id
				title
				url
				state
				isDraft
				author { login ... on User { avatarUrl } }
				headRefName
				headRefOid
				baseRefName
				additions
				deletions
				changedFiles
				reviewDecision
				mergedAt
				closedAt
				updatedAt
				statusCheckRollup {
					state
					contexts(first: 50) {
						nodes {
							__typename
							... on CheckRun { name conclusion status detailsUrl }
							... on StatusContext { context state targetUrl }
						}
					}
				}
			}
		}
	}
}`;

function mapState(s: string): string {
	// GraphQL returns OPEN | CLOSED | MERGED; schema column stores lowercase.
	return s.toLowerCase();
}

function mapChecks(rollup: GhPr["statusCheckRollup"]) {
	if (!rollup) return { checksStatus: "none", checks: [] };

	const checks = rollup.contexts.nodes.map((node) => {
		if (node.__typename === "CheckRun") {
			return {
				name: node.name,
				status: node.status.toLowerCase(),
				conclusion: node.conclusion ? node.conclusion.toLowerCase() : null,
				detailsUrl: node.detailsUrl ?? undefined,
			};
		}
		return {
			name: node.context,
			status: node.state === "PENDING" ? "in_progress" : "completed",
			conclusion:
				node.state === "SUCCESS" ? "success" : node.state.toLowerCase(),
			detailsUrl: node.targetUrl ?? undefined,
		};
	});

	const checksStatus = (() => {
		switch (rollup.state) {
			case "SUCCESS":
				return "success";
			case "FAILURE":
			case "ERROR":
				return "failure";
			case "PENDING":
			case "EXPECTED":
				return "pending";
			default:
				return checks.length > 0 ? "pending" : "none";
		}
	})();

	return { checksStatus, checks };
}

export async function POST(request: Request) {
	const body = await request.text();
	const signature = request.headers.get("upstash-signature");

	const isDev = env.NODE_ENV === "development";
	if (!isDev) {
		if (!signature) {
			return Response.json({ error: "Missing signature" }, { status: 401 });
		}
		const isValid = await receiver
			.verify({
				body,
				signature,
				url: `${env.NEXT_PUBLIC_API_URL}/api/github/jobs/sync`,
			})
			.catch((error) => {
				console.error("[github/sync] Signature verification failed:", error);
				return false;
			});
		if (!isValid) {
			return Response.json({ error: "Invalid signature" }, { status: 401 });
		}
	}

	let bodyData: unknown;
	try {
		bodyData = JSON.parse(body);
	} catch {
		return Response.json({ error: "Invalid JSON" }, { status: 400 });
	}

	const parsed = payloadSchema.safeParse(bodyData);
	if (!parsed.success) {
		return Response.json({ error: "Invalid payload" }, { status: 400 });
	}

	const { organizationId } = parsed.data;

	const repos = await db.query.githubRepositories.findMany({
		where: eq(githubRepositories.organizationId, organizationId),
	});

	if (repos.length === 0) {
		return Response.json({ success: true, repoCount: 0, prCount: 0 });
	}

	const cutoff = subDays(new Date(), 30);
	let prCount = 0;

	for (const repo of repos) {
		let cursor: string | null = null;
		let reachedCutoff = false;

		while (!reachedCutoff) {
			const data: RepoPrsResponse = await ghGraphQL<RepoPrsResponse>(
				REPO_PRS_QUERY,
				{ owner: repo.owner, name: repo.name, cursor },
			);

			if (!data.repository) {
				console.warn(
					`[github/sync] Repository ${repo.fullName} not accessible via gh`,
				);
				break;
			}

			const { nodes, pageInfo } = data.repository.pullRequests;

			for (const pr of nodes) {
				if (new Date(pr.updatedAt) < cutoff) {
					reachedCutoff = true;
					break;
				}

				const { checksStatus, checks } = mapChecks(pr.statusCheckRollup);

				await db
					.insert(githubPullRequests)
					.values({
						repositoryId: repo.id,
						organizationId,
						prNumber: pr.number,
						nodeId: pr.id,
						headBranch: pr.headRefName,
						headSha: pr.headRefOid,
						baseBranch: pr.baseRefName,
						title: pr.title,
						url: pr.url,
						authorLogin: pr.author?.login ?? "unknown",
						authorAvatarUrl: pr.author?.avatarUrl ?? null,
						state: mapState(pr.state),
						isDraft: pr.isDraft,
						additions: pr.additions,
						deletions: pr.deletions,
						changedFiles: pr.changedFiles,
						reviewDecision: pr.reviewDecision,
						checksStatus,
						checks,
						mergedAt: pr.mergedAt ? new Date(pr.mergedAt) : null,
						closedAt: pr.closedAt ? new Date(pr.closedAt) : null,
						lastSyncedAt: new Date(),
						updatedAt: new Date(pr.updatedAt),
					})
					.onConflictDoUpdate({
						target: [
							githubPullRequests.repositoryId,
							githubPullRequests.prNumber,
						],
						set: {
							organizationId,
							headBranch: pr.headRefName,
							headSha: pr.headRefOid,
							baseBranch: pr.baseRefName,
							title: pr.title,
							authorLogin: pr.author?.login ?? "unknown",
							authorAvatarUrl: pr.author?.avatarUrl ?? null,
							state: mapState(pr.state),
							isDraft: pr.isDraft,
							additions: pr.additions,
							deletions: pr.deletions,
							changedFiles: pr.changedFiles,
							reviewDecision: pr.reviewDecision,
							checksStatus,
							checks,
							mergedAt: pr.mergedAt ? new Date(pr.mergedAt) : null,
							closedAt: pr.closedAt ? new Date(pr.closedAt) : null,
							lastSyncedAt: new Date(),
							updatedAt: new Date(pr.updatedAt),
						},
					});

				prCount += 1;
			}

			if (!pageInfo.hasNextPage) break;
			cursor = pageInfo.endCursor;
		}
	}

	console.log(
		`[github/sync] Synced ${prCount} PRs across ${repos.length} repos for org ${organizationId}`,
	);

	return Response.json({
		success: true,
		repoCount: repos.length,
		prCount,
	});
}
