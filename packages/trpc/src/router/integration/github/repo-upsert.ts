import { dbWs } from "@superset/db/client";
import {
	githubRepositories,
	type SelectGithubRepository,
} from "@superset/db/schema";
import { and, eq, sql } from "drizzle-orm";
import { GhCliError, runGh } from "../../../lib/gh";

type GhRepoApi = {
	id: number;
	name: string;
	owner: { login: string };
	full_name: string;
	default_branch: string;
	private: boolean;
};

export async function upsertGithubRepoFromCli(
	ownerSlashName: string,
	organizationId: string,
): Promise<SelectGithubRepository | null> {
	const fullNameLower = ownerSlashName.toLowerCase();

	const existing = await dbWs.query.githubRepositories.findFirst({
		where: and(
			eq(sql`lower(${githubRepositories.fullName})`, fullNameLower),
			eq(githubRepositories.organizationId, organizationId),
		),
	});
	if (existing) return existing;

	// `github_repositories.repoId` has a global UNIQUE constraint, so if another
	// org already owns this repo we can't insert it again — and we shouldn't
	// link across org boundaries either.
	const otherOrgRow = await dbWs.query.githubRepositories.findFirst({
		columns: { id: true },
		where: eq(sql`lower(${githubRepositories.fullName})`, fullNameLower),
	});
	if (otherOrgRow) return null;

	let r: GhRepoApi;
	try {
		const stdout = await runGh(["api", `repos/${ownerSlashName}`]);
		r = JSON.parse(stdout) as GhRepoApi;
	} catch (err) {
		if (err instanceof GhCliError) {
			console.warn(
				`[upsertGithubRepoFromCli] gh lookup failed for ${ownerSlashName}: ${err.message}`,
			);
			return null;
		}
		throw err;
	}

	const [row] = await dbWs
		.insert(githubRepositories)
		.values({
			organizationId,
			repoId: String(r.id),
			owner: r.owner.login,
			name: r.name,
			fullName: r.full_name,
			defaultBranch: r.default_branch,
			isPrivate: r.private,
		})
		.returning();

	return row ?? null;
}
