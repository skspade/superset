"use client";

import { Badge } from "@superset/ui/badge";
import {
	CheckCircle2,
	CircleDashed,
	CircleDot,
	GitMerge,
	GitPullRequestClosed,
	GitPullRequestDraft,
	XCircle,
} from "lucide-react";
import type { ComponentType } from "react";

interface PullRequest {
	number: number;
	url: string;
	title: string;
	state: string;
	isDraft: boolean;
	updatedAt: string;
	additions: number;
	deletions: number;
	reviewDecision: string | null;
	author: { login?: string; avatarUrl?: string } | null;
	repository: { nameWithOwner: string };
	statusCheckRollup: { state: string } | null;
}

interface PullRequestListProps {
	title: string;
	prs: PullRequest[];
	emptyText: string;
}

export function PullRequestList({
	title,
	prs,
	emptyText,
}: PullRequestListProps) {
	return (
		<div className="space-y-3">
			<h3 className="text-sm font-medium text-muted-foreground">
				{title} ({prs.length})
			</h3>
			{prs.length === 0 ? (
				<p className="text-sm text-muted-foreground">{emptyText}</p>
			) : (
				<ul className="space-y-2">
					{prs.map((pr) => (
						<li key={pr.url}>
							<a
								href={pr.url}
								target="_blank"
								rel="noreferrer"
								className="flex items-start gap-3 rounded-lg border p-3 transition-colors hover:bg-accent"
							>
								<PrStateIcon pr={pr} />
								<div className="min-w-0 flex-1">
									<div className="flex items-center gap-2 text-xs text-muted-foreground">
										<span className="font-mono">
											{pr.repository.nameWithOwner}#{pr.number}
										</span>
										<span>•</span>
										<span>{pr.author?.login ?? "unknown"}</span>
									</div>
									<p className="mt-0.5 truncate font-medium">{pr.title}</p>
								</div>
								<div className="flex flex-shrink-0 items-center gap-2">
									<ReviewBadge decision={pr.reviewDecision} />
									<ChecksBadge state={pr.statusCheckRollup?.state ?? null} />
									<span className="hidden whitespace-nowrap font-mono text-xs text-muted-foreground sm:inline">
										+{pr.additions} -{pr.deletions}
									</span>
								</div>
							</a>
						</li>
					))}
				</ul>
			)}
		</div>
	);
}

function PrStateIcon({ pr }: { pr: PullRequest }) {
	let Icon: ComponentType<{ className?: string }>;
	let className: string;
	if (pr.state === "MERGED") {
		Icon = GitMerge;
		className = "text-purple-500";
	} else if (pr.state === "CLOSED") {
		Icon = GitPullRequestClosed;
		className = "text-red-500";
	} else if (pr.isDraft) {
		Icon = GitPullRequestDraft;
		className = "text-muted-foreground";
	} else {
		Icon = CircleDot;
		className = "text-green-500";
	}
	return <Icon className={`mt-0.5 size-4 flex-shrink-0 ${className}`} />;
}

function ReviewBadge({ decision }: { decision: string | null }) {
	if (!decision) return null;
	if (decision === "APPROVED") {
		return (
			<Badge variant="outline" className="border-green-500/40 text-green-600">
				Approved
			</Badge>
		);
	}
	if (decision === "CHANGES_REQUESTED") {
		return (
			<Badge variant="outline" className="border-red-500/40 text-red-600">
				Changes
			</Badge>
		);
	}
	return (
		<Badge variant="outline" className="text-muted-foreground">
			Review
		</Badge>
	);
}

function ChecksBadge({ state }: { state: string | null }) {
	if (!state) return null;
	if (state === "SUCCESS") {
		return <CheckCircle2 className="size-4 text-green-500" />;
	}
	if (state === "FAILURE" || state === "ERROR") {
		return <XCircle className="size-4 text-red-500" />;
	}
	return <CircleDashed className="size-4 text-amber-500" />;
}
