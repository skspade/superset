import { Badge } from "@superset/ui/badge";
import {
	Card,
	CardContent,
	CardDescription,
	CardHeader,
	CardTitle,
} from "@superset/ui/card";
import { AlertTriangle, ArrowLeft, CheckCircle2 } from "lucide-react";
import Link from "next/link";
import { FaGithub } from "react-icons/fa";
import { api } from "@/trpc/server";
import { PullRequestList } from "./components/PullRequestList";
import { RepositoryList } from "./components/RepositoryList";

export default async function GitHubIntegrationPage() {
	const trpc = await api();
	const organization = await trpc.user.myOrganization.query();

	if (!organization) {
		return (
			<div className="flex flex-col items-center justify-center py-16">
				<p className="text-muted-foreground">
					You need to be part of an organization to use integrations.
				</p>
			</div>
		);
	}

	const status = await trpc.integration.github.status.query();
	const myPrs = status.available
		? await trpc.integration.github.myPullRequests.query()
		: { authored: [], reviewRequested: [] };

	return (
		<div className="space-y-8">
			<Link
				href="/integrations"
				className="inline-flex items-center gap-2 text-sm text-muted-foreground transition-colors hover:text-foreground"
			>
				<ArrowLeft className="size-4" />
				Back to Integrations
			</Link>

			<div className="flex items-start gap-6">
				<div className="flex size-16 items-center justify-center rounded-xl border bg-card p-3">
					<FaGithub className="size-10" />
				</div>
				<div className="flex-1">
					<div className="flex items-center gap-3">
						<h1 className="text-2xl font-semibold">GitHub</h1>
						{status.available ? (
							<Badge variant="default" className="gap-1">
								<CheckCircle2 className="size-3" />
								{status.login ? `@${status.login}` : "Connected"}
							</Badge>
						) : (
							<Badge variant="destructive" className="gap-1">
								<AlertTriangle className="size-3" />
								gh CLI unavailable
							</Badge>
						)}
					</div>
					<p className="mt-1 text-muted-foreground">
						Tracks your pull requests via the `gh` CLI on the API host. Repos
						are linked when you create a project from a GitHub clone URL.
					</p>
				</div>
			</div>

			{!status.available && (
				<Card>
					<CardHeader>
						<CardTitle>Set up the GitHub CLI</CardTitle>
						<CardDescription>
							The API server can't reach an authenticated `gh` CLI.
						</CardDescription>
					</CardHeader>
					<CardContent className="space-y-2 text-sm text-muted-foreground">
						<p>
							Install the GitHub CLI on the machine running the API (`brew
							install gh` or see cli.github.com), then run{" "}
							<code className="rounded bg-muted px-1 py-0.5">
								gh auth login
							</code>{" "}
							once. The integration will detect the existing auth automatically.
						</p>
					</CardContent>
				</Card>
			)}

			{status.available && (
				<Card>
					<CardHeader>
						<CardTitle>My Pull Requests</CardTitle>
						<CardDescription>
							Open PRs from your GitHub account, fetched live via `gh`.
						</CardDescription>
					</CardHeader>
					<CardContent className="space-y-6">
						<PullRequestList
							title="Authored"
							prs={myPrs.authored}
							emptyText="You don't have any open PRs."
						/>
						<PullRequestList
							title="Awaiting your review"
							prs={myPrs.reviewRequested}
							emptyText="Nothing in your review queue."
						/>
					</CardContent>
				</Card>
			)}

			<Card>
				<CardHeader>
					<CardTitle>Tracked Repositories</CardTitle>
					<CardDescription>
						Repos linked to projects in this organization. The sync job
						refreshes their PRs every 10 minutes.
					</CardDescription>
				</CardHeader>
				<CardContent>
					<RepositoryList organizationId={organization.id} />
				</CardContent>
			</Card>
		</div>
	);
}
