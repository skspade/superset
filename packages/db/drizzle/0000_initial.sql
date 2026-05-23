CREATE SCHEMA "auth";
--> statement-breakpoint
CREATE SCHEMA "ingest";
--> statement-breakpoint
CREATE TYPE "public"."automation_prompt_source" AS ENUM('human', 'agent', 'restore');--> statement-breakpoint
CREATE TYPE "public"."automation_run_status" AS ENUM('dispatching', 'dispatched', 'skipped_offline', 'dispatch_failed');--> statement-breakpoint
CREATE TYPE "public"."automation_session_kind" AS ENUM('chat', 'terminal');--> statement-breakpoint
CREATE TYPE "public"."command_status" AS ENUM('pending', 'completed', 'failed', 'timeout');--> statement-breakpoint
CREATE TYPE "public"."device_type" AS ENUM('desktop', 'mobile', 'web');--> statement-breakpoint
CREATE TYPE "public"."integration_provider" AS ENUM('linear', 'github', 'slack');--> statement-breakpoint
CREATE TYPE "public"."remote_control_session_mode" AS ENUM('command', 'full');--> statement-breakpoint
CREATE TYPE "public"."remote_control_session_status" AS ENUM('active', 'revoked', 'expired');--> statement-breakpoint
CREATE TYPE "public"."task_priority" AS ENUM('urgent', 'high', 'medium', 'low', 'none');--> statement-breakpoint
CREATE TYPE "public"."task_status" AS ENUM('backlog', 'todo', 'planning', 'working', 'needs-feedback', 'ready-to-merge', 'completed', 'canceled');--> statement-breakpoint
CREATE TYPE "public"."v2_client_type" AS ENUM('desktop', 'mobile', 'web');--> statement-breakpoint
CREATE TYPE "public"."v2_users_host_role" AS ENUM('owner', 'member');--> statement-breakpoint
CREATE TYPE "public"."v2_workspace_type" AS ENUM('main', 'worktree');--> statement-breakpoint
CREATE TYPE "public"."workspace_type" AS ENUM('local', 'cloud');--> statement-breakpoint
CREATE TABLE "auth"."accounts" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"account_id" text NOT NULL,
	"provider_id" text NOT NULL,
	"user_id" uuid NOT NULL,
	"access_token" text,
	"refresh_token" text,
	"id_token" text,
	"access_token_expires_at" timestamp,
	"refresh_token_expires_at" timestamp,
	"scope" text,
	"password" text,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp NOT NULL
);
--> statement-breakpoint
CREATE TABLE "auth"."apikeys" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"config_id" text DEFAULT 'default' NOT NULL,
	"name" text,
	"start" text,
	"reference_id" text NOT NULL,
	"prefix" text,
	"key" text NOT NULL,
	"refill_interval" integer,
	"refill_amount" integer,
	"last_refill_at" timestamp,
	"enabled" boolean DEFAULT true,
	"rate_limit_enabled" boolean DEFAULT true,
	"rate_limit_time_window" integer DEFAULT 86400000,
	"rate_limit_max" integer DEFAULT 10,
	"request_count" integer DEFAULT 0,
	"remaining" integer,
	"last_request" timestamp,
	"expires_at" timestamp,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	"permissions" text,
	"metadata" text,
	"organization_id" uuid GENERATED ALWAYS AS (CASE
				WHEN metadata IS NULL OR metadata = '' THEN NULL
				WHEN NOT (metadata IS JSON OBJECT) THEN NULL
				WHEN (metadata::jsonb->>'organizationId') ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
					THEN (metadata::jsonb->>'organizationId')::uuid
				ELSE NULL
			END) STORED
);
--> statement-breakpoint
CREATE TABLE "auth"."device_codes" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"device_code" text NOT NULL,
	"user_code" text NOT NULL,
	"user_id" text,
	"expires_at" timestamp NOT NULL,
	"status" text NOT NULL,
	"last_polled_at" timestamp,
	"polling_interval" integer,
	"client_id" text,
	"scope" text
);
--> statement-breakpoint
CREATE TABLE "auth"."invitations" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"organization_id" uuid NOT NULL,
	"email" text NOT NULL,
	"role" text,
	"status" text DEFAULT 'pending' NOT NULL,
	"expires_at" timestamp NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"inviter_id" uuid NOT NULL,
	"team_id" uuid
);
--> statement-breakpoint
CREATE TABLE "auth"."jwkss" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"public_key" text NOT NULL,
	"private_key" text NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"expires_at" timestamp
);
--> statement-breakpoint
CREATE TABLE "auth"."members" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"organization_id" uuid NOT NULL,
	"user_id" uuid NOT NULL,
	"role" text DEFAULT 'member' NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "auth"."oauth_access_tokens" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"token" text,
	"client_id" text NOT NULL,
	"session_id" uuid,
	"user_id" uuid,
	"reference_id" text,
	"refresh_id" uuid,
	"expires_at" timestamp,
	"created_at" timestamp,
	"scopes" text[] NOT NULL,
	CONSTRAINT "oauth_access_tokens_token_unique" UNIQUE("token")
);
--> statement-breakpoint
CREATE TABLE "auth"."oauth_clients" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"client_id" text NOT NULL,
	"client_secret" text,
	"disabled" boolean DEFAULT false,
	"skip_consent" boolean,
	"enable_end_session" boolean,
	"scopes" text[],
	"user_id" uuid,
	"created_at" timestamp,
	"updated_at" timestamp,
	"name" text,
	"uri" text,
	"icon" text,
	"contacts" text[],
	"tos" text,
	"policy" text,
	"software_id" text,
	"software_version" text,
	"software_statement" text,
	"redirect_uris" text[] NOT NULL,
	"post_logout_redirect_uris" text[],
	"token_endpoint_auth_method" text,
	"grant_types" text[],
	"response_types" text[],
	"public" boolean,
	"type" text,
	"require_pkce" boolean,
	"subject_type" text,
	"reference_id" text,
	"metadata" jsonb,
	CONSTRAINT "oauth_clients_client_id_unique" UNIQUE("client_id")
);
--> statement-breakpoint
CREATE TABLE "auth"."oauth_consents" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"client_id" text NOT NULL,
	"user_id" uuid,
	"reference_id" text,
	"scopes" text[] NOT NULL,
	"created_at" timestamp,
	"updated_at" timestamp
);
--> statement-breakpoint
CREATE TABLE "auth"."oauth_refresh_tokens" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"token" text NOT NULL,
	"client_id" text NOT NULL,
	"session_id" uuid,
	"user_id" uuid NOT NULL,
	"reference_id" text,
	"expires_at" timestamp,
	"created_at" timestamp,
	"revoked" timestamp,
	"auth_time" timestamp,
	"scopes" text[] NOT NULL
);
--> statement-breakpoint
CREATE TABLE "auth"."organizations" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"name" text NOT NULL,
	"slug" text NOT NULL,
	"logo" text,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"metadata" text,
	"stripe_customer_id" text,
	"allowed_domains" text[] DEFAULT '{}' NOT NULL,
	CONSTRAINT "organizations_slug_unique" UNIQUE("slug")
);
--> statement-breakpoint
CREATE TABLE "auth"."sessions" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"expires_at" timestamp NOT NULL,
	"token" text NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp NOT NULL,
	"ip_address" text,
	"user_agent" text,
	"user_id" uuid NOT NULL,
	"active_organization_id" uuid,
	"active_team_id" uuid,
	CONSTRAINT "sessions_token_unique" UNIQUE("token")
);
--> statement-breakpoint
CREATE TABLE "auth"."team_members" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"team_id" uuid NOT NULL,
	"user_id" uuid NOT NULL,
	"organization_id" uuid NOT NULL,
	"created_at" timestamp DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "auth"."teams" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"name" text NOT NULL,
	"slug" text NOT NULL,
	"organization_id" uuid NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "auth"."users" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"name" text NOT NULL,
	"email" text NOT NULL,
	"email_verified" boolean DEFAULT false NOT NULL,
	"image" text,
	"organization_ids" uuid[] DEFAULT '{}' NOT NULL,
	"onboarded_at" timestamp,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "users_email_unique" UNIQUE("email")
);
--> statement-breakpoint
CREATE TABLE "auth"."verifications" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"identifier" text NOT NULL,
	"value" text NOT NULL,
	"expires_at" timestamp NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "github_pull_requests" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"repository_id" uuid NOT NULL,
	"organization_id" uuid NOT NULL,
	"pr_number" integer NOT NULL,
	"node_id" text NOT NULL,
	"head_branch" text NOT NULL,
	"head_sha" text NOT NULL,
	"base_branch" text NOT NULL,
	"title" text NOT NULL,
	"url" text NOT NULL,
	"author_login" text NOT NULL,
	"author_avatar_url" text,
	"state" text NOT NULL,
	"is_draft" boolean DEFAULT false NOT NULL,
	"additions" integer DEFAULT 0 NOT NULL,
	"deletions" integer DEFAULT 0 NOT NULL,
	"changed_files" integer DEFAULT 0 NOT NULL,
	"review_decision" text,
	"checks_status" text DEFAULT 'none' NOT NULL,
	"checks" jsonb DEFAULT '[]'::jsonb,
	"merged_at" timestamp,
	"closed_at" timestamp,
	"last_synced_at" timestamp,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "github_pull_requests_repo_pr_unique" UNIQUE("repository_id","pr_number")
);
--> statement-breakpoint
CREATE TABLE "github_repositories" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"organization_id" uuid NOT NULL,
	"repo_id" text NOT NULL,
	"owner" text NOT NULL,
	"name" text NOT NULL,
	"full_name" text NOT NULL,
	"default_branch" text DEFAULT 'main' NOT NULL,
	"is_private" boolean DEFAULT false NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "github_repositories_repo_id_unique" UNIQUE("repo_id")
);
--> statement-breakpoint
CREATE TABLE "ingest"."webhook_events" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"provider" "integration_provider" NOT NULL,
	"event_id" text NOT NULL,
	"event_type" text,
	"payload" jsonb NOT NULL,
	"status" text DEFAULT 'pending' NOT NULL,
	"processed_at" timestamp,
	"error" text,
	"retry_count" integer DEFAULT 0 NOT NULL,
	"received_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "agent_commands" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"organization_id" uuid NOT NULL,
	"target_device_id" text,
	"target_device_type" text,
	"tool" text NOT NULL,
	"params" jsonb,
	"parent_command_id" uuid,
	"status" "command_status" DEFAULT 'pending' NOT NULL,
	"result" jsonb,
	"error" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"executed_at" timestamp with time zone,
	"timeout_at" timestamp with time zone
);
--> statement-breakpoint
CREATE TABLE "automation_prompt_versions" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"automation_id" uuid NOT NULL,
	"author_user_id" uuid NOT NULL,
	"window_bucket" integer NOT NULL,
	"content" text NOT NULL,
	"content_hash" text NOT NULL,
	"source" "automation_prompt_source" NOT NULL,
	"restored_from_version_id" uuid,
	"started_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "automation_runs" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"automation_id" uuid NOT NULL,
	"organization_id" uuid NOT NULL,
	"title" text NOT NULL,
	"scheduled_for" timestamp with time zone NOT NULL,
	"host_id" text,
	"v2_workspace_id" uuid,
	"session_kind" "automation_session_kind",
	"chat_session_id" uuid,
	"terminal_session_id" text,
	"status" "automation_run_status" NOT NULL,
	"error" text,
	"dispatched_at" timestamp with time zone,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "automations" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"organization_id" uuid NOT NULL,
	"owner_user_id" uuid NOT NULL,
	"name" text NOT NULL,
	"prompt" text NOT NULL,
	"agent" text NOT NULL,
	"target_host_id" text,
	"v2_project_id" uuid NOT NULL,
	"v2_workspace_id" uuid,
	"rrule" text NOT NULL,
	"dtstart" timestamp with time zone NOT NULL,
	"timezone" text NOT NULL,
	"enabled" boolean DEFAULT true NOT NULL,
	"mcp_scope" jsonb DEFAULT '[]'::jsonb NOT NULL,
	"next_run_at" timestamp with time zone NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "chat_attachments" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"chat_session_id" uuid NOT NULL,
	"created_by" uuid NOT NULL,
	"organization_id" uuid NOT NULL,
	"blob_pathname" text NOT NULL,
	"media_type" text NOT NULL,
	"filename" text NOT NULL,
	"size_bytes" integer NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "chat_sessions" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"organization_id" uuid NOT NULL,
	"created_by" uuid NOT NULL,
	"workspace_id" uuid,
	"v2_workspace_id" uuid,
	"title" text,
	"last_active_at" timestamp DEFAULT now() NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "device_presence" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"organization_id" uuid NOT NULL,
	"device_id" text NOT NULL,
	"device_name" text NOT NULL,
	"device_type" "device_type" NOT NULL,
	"last_seen_at" timestamp with time zone DEFAULT now() NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "integration_connections" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"organization_id" uuid NOT NULL,
	"connected_by_user_id" uuid NOT NULL,
	"provider" "integration_provider" NOT NULL,
	"access_token" text NOT NULL,
	"refresh_token" text,
	"token_expires_at" timestamp,
	"disconnected_at" timestamp,
	"disconnect_reason" text,
	"external_org_id" text,
	"external_org_name" text,
	"config" jsonb,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "integration_connections_unique" UNIQUE("organization_id","provider")
);
--> statement-breakpoint
CREATE TABLE "projects" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"organization_id" uuid NOT NULL,
	"name" text NOT NULL,
	"slug" text NOT NULL,
	"github_repository_id" uuid,
	"repo_owner" text NOT NULL,
	"repo_name" text NOT NULL,
	"repo_url" text NOT NULL,
	"default_branch" text DEFAULT 'main' NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "projects_org_slug_unique" UNIQUE("organization_id","slug")
);
--> statement-breakpoint
CREATE TABLE "sandbox_images" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"organization_id" uuid NOT NULL,
	"project_id" uuid NOT NULL,
	"setup_commands" jsonb DEFAULT '[]'::jsonb,
	"base_image" text,
	"system_packages" jsonb DEFAULT '[]'::jsonb,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "sandbox_images_project_unique" UNIQUE("project_id")
);
--> statement-breakpoint
CREATE TABLE "secrets" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"organization_id" uuid NOT NULL,
	"project_id" uuid NOT NULL,
	"key" text NOT NULL,
	"encrypted_value" text NOT NULL,
	"sensitive" boolean DEFAULT false NOT NULL,
	"created_by_user_id" uuid,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "secrets_project_key_unique" UNIQUE("project_id","key")
);
--> statement-breakpoint
CREATE TABLE "submitted_prompts" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"organization_id" uuid,
	"prompt_text" text NOT NULL,
	"submitter_name" text,
	"created_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "subscriptions" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"plan" text NOT NULL,
	"reference_id" uuid NOT NULL,
	"stripe_customer_id" text,
	"stripe_subscription_id" text,
	"status" text DEFAULT 'incomplete' NOT NULL,
	"period_start" timestamp,
	"period_end" timestamp,
	"trial_start" timestamp,
	"trial_end" timestamp,
	"cancel_at_period_end" boolean DEFAULT false,
	"cancel_at" timestamp,
	"canceled_at" timestamp,
	"ended_at" timestamp,
	"seats" integer,
	"billing_interval" text,
	"stripe_schedule_id" text,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "task_statuses" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"organization_id" uuid NOT NULL,
	"name" text NOT NULL,
	"color" text NOT NULL,
	"type" text NOT NULL,
	"position" real NOT NULL,
	"progress_percent" real,
	"external_provider" "integration_provider",
	"external_id" text,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "task_statuses_org_external_unique" UNIQUE("organization_id","external_provider","external_id")
);
--> statement-breakpoint
CREATE TABLE "tasks" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"slug" text NOT NULL,
	"title" text NOT NULL,
	"description" text,
	"status_id" uuid NOT NULL,
	"priority" "task_priority" DEFAULT 'none' NOT NULL,
	"organization_id" uuid NOT NULL,
	"assignee_id" uuid,
	"creator_id" uuid NOT NULL,
	"estimate" integer,
	"due_date" timestamp,
	"labels" jsonb DEFAULT '[]'::jsonb,
	"branch" text,
	"pr_url" text,
	"external_provider" "integration_provider",
	"external_id" text,
	"external_key" text,
	"external_url" text,
	"last_synced_at" timestamp,
	"sync_error" text,
	"assignee_external_id" text,
	"assignee_display_name" text,
	"assignee_avatar_url" text,
	"started_at" timestamp,
	"completed_at" timestamp,
	"deleted_at" timestamp,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "tasks_external_unique" UNIQUE("organization_id","external_provider","external_id"),
	CONSTRAINT "tasks_org_slug_unique" UNIQUE("organization_id","slug")
);
--> statement-breakpoint
CREATE TABLE "users__slack_users" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"slack_user_id" text NOT NULL,
	"team_id" text NOT NULL,
	"user_id" uuid NOT NULL,
	"organization_id" uuid NOT NULL,
	"model_preference" text,
	"created_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "users__slack_users_unique" UNIQUE("slack_user_id","team_id")
);
--> statement-breakpoint
CREATE TABLE "v2_clients" (
	"organization_id" uuid NOT NULL,
	"user_id" uuid NOT NULL,
	"machine_id" text NOT NULL,
	"type" "v2_client_type" NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "v2_clients_organization_id_user_id_machine_id_pk" PRIMARY KEY("organization_id","user_id","machine_id")
);
--> statement-breakpoint
CREATE TABLE "v2_hosts" (
	"organization_id" uuid NOT NULL,
	"machine_id" text NOT NULL,
	"name" text NOT NULL,
	"is_online" boolean DEFAULT false NOT NULL,
	"created_by_user_id" uuid,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "v2_hosts_organization_id_machine_id_pk" PRIMARY KEY("organization_id","machine_id")
);
--> statement-breakpoint
CREATE TABLE "v2_projects" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"organization_id" uuid NOT NULL,
	"name" text NOT NULL,
	"slug" text NOT NULL,
	"repo_clone_url" text,
	"github_repository_id" uuid,
	"icon_url" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "v2_projects_org_slug_unique" UNIQUE("organization_id","slug")
);
--> statement-breakpoint
CREATE TABLE "v2_remote_control_sessions" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"organization_id" uuid NOT NULL,
	"host_id" text NOT NULL,
	"workspace_id" uuid NOT NULL,
	"terminal_id" text NOT NULL,
	"created_by_user_id" uuid NOT NULL,
	"mode" "remote_control_session_mode" NOT NULL,
	"status" "remote_control_session_status" DEFAULT 'active' NOT NULL,
	"token_hash" text NOT NULL,
	"expires_at" timestamp with time zone NOT NULL,
	"revoked_at" timestamp with time zone,
	"revoked_by_user_id" uuid,
	"last_connected_at" timestamp with time zone,
	"viewer_count" integer DEFAULT 0 NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "v2_users_hosts" (
	"organization_id" uuid NOT NULL,
	"user_id" uuid NOT NULL,
	"host_id" text NOT NULL,
	"role" "v2_users_host_role" DEFAULT 'member' NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "v2_users_hosts_organization_id_user_id_host_id_pk" PRIMARY KEY("organization_id","user_id","host_id")
);
--> statement-breakpoint
CREATE TABLE "v2_workspaces" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"organization_id" uuid NOT NULL,
	"project_id" uuid NOT NULL,
	"host_id" text NOT NULL,
	"name" text NOT NULL,
	"branch" text NOT NULL,
	"type" "v2_workspace_type" DEFAULT 'worktree' NOT NULL,
	"created_by_user_id" uuid,
	"task_id" uuid,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "workspaces" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"organization_id" uuid NOT NULL,
	"project_id" uuid NOT NULL,
	"name" text NOT NULL,
	"type" "workspace_type" NOT NULL,
	"config" jsonb NOT NULL,
	"created_by_user_id" uuid,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "auth"."accounts" ADD CONSTRAINT "accounts_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "auth"."invitations" ADD CONSTRAINT "invitations_organization_id_organizations_id_fk" FOREIGN KEY ("organization_id") REFERENCES "auth"."organizations"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "auth"."invitations" ADD CONSTRAINT "invitations_inviter_id_users_id_fk" FOREIGN KEY ("inviter_id") REFERENCES "auth"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "auth"."invitations" ADD CONSTRAINT "invitations_team_id_teams_id_fk" FOREIGN KEY ("team_id") REFERENCES "auth"."teams"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "auth"."members" ADD CONSTRAINT "members_organization_id_organizations_id_fk" FOREIGN KEY ("organization_id") REFERENCES "auth"."organizations"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "auth"."members" ADD CONSTRAINT "members_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "auth"."oauth_access_tokens" ADD CONSTRAINT "oauth_access_tokens_client_id_oauth_clients_client_id_fk" FOREIGN KEY ("client_id") REFERENCES "auth"."oauth_clients"("client_id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "auth"."oauth_access_tokens" ADD CONSTRAINT "oauth_access_tokens_session_id_sessions_id_fk" FOREIGN KEY ("session_id") REFERENCES "auth"."sessions"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "auth"."oauth_access_tokens" ADD CONSTRAINT "oauth_access_tokens_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "auth"."oauth_access_tokens" ADD CONSTRAINT "oauth_access_tokens_refresh_id_oauth_refresh_tokens_id_fk" FOREIGN KEY ("refresh_id") REFERENCES "auth"."oauth_refresh_tokens"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "auth"."oauth_clients" ADD CONSTRAINT "oauth_clients_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "auth"."oauth_consents" ADD CONSTRAINT "oauth_consents_client_id_oauth_clients_client_id_fk" FOREIGN KEY ("client_id") REFERENCES "auth"."oauth_clients"("client_id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "auth"."oauth_consents" ADD CONSTRAINT "oauth_consents_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "auth"."oauth_refresh_tokens" ADD CONSTRAINT "oauth_refresh_tokens_client_id_oauth_clients_client_id_fk" FOREIGN KEY ("client_id") REFERENCES "auth"."oauth_clients"("client_id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "auth"."oauth_refresh_tokens" ADD CONSTRAINT "oauth_refresh_tokens_session_id_sessions_id_fk" FOREIGN KEY ("session_id") REFERENCES "auth"."sessions"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "auth"."oauth_refresh_tokens" ADD CONSTRAINT "oauth_refresh_tokens_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "auth"."sessions" ADD CONSTRAINT "sessions_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "auth"."team_members" ADD CONSTRAINT "team_members_team_id_teams_id_fk" FOREIGN KEY ("team_id") REFERENCES "auth"."teams"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "auth"."team_members" ADD CONSTRAINT "team_members_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "auth"."team_members" ADD CONSTRAINT "team_members_organization_id_organizations_id_fk" FOREIGN KEY ("organization_id") REFERENCES "auth"."organizations"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "auth"."teams" ADD CONSTRAINT "teams_organization_id_organizations_id_fk" FOREIGN KEY ("organization_id") REFERENCES "auth"."organizations"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "github_pull_requests" ADD CONSTRAINT "github_pull_requests_repository_id_github_repositories_id_fk" FOREIGN KEY ("repository_id") REFERENCES "public"."github_repositories"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "github_pull_requests" ADD CONSTRAINT "github_pull_requests_organization_id_organizations_id_fk" FOREIGN KEY ("organization_id") REFERENCES "auth"."organizations"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "github_repositories" ADD CONSTRAINT "github_repositories_organization_id_organizations_id_fk" FOREIGN KEY ("organization_id") REFERENCES "auth"."organizations"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "agent_commands" ADD CONSTRAINT "agent_commands_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "agent_commands" ADD CONSTRAINT "agent_commands_organization_id_organizations_id_fk" FOREIGN KEY ("organization_id") REFERENCES "auth"."organizations"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "automation_prompt_versions" ADD CONSTRAINT "automation_prompt_versions_automation_id_automations_id_fk" FOREIGN KEY ("automation_id") REFERENCES "public"."automations"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "automation_prompt_versions" ADD CONSTRAINT "automation_prompt_versions_author_user_id_users_id_fk" FOREIGN KEY ("author_user_id") REFERENCES "auth"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "automation_prompt_versions" ADD CONSTRAINT "automation_prompt_versions_restored_from_version_id_fk" FOREIGN KEY ("restored_from_version_id") REFERENCES "public"."automation_prompt_versions"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "automation_runs" ADD CONSTRAINT "automation_runs_automation_id_automations_id_fk" FOREIGN KEY ("automation_id") REFERENCES "public"."automations"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "automation_runs" ADD CONSTRAINT "automation_runs_organization_id_organizations_id_fk" FOREIGN KEY ("organization_id") REFERENCES "auth"."organizations"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "automation_runs" ADD CONSTRAINT "automation_runs_chat_session_id_chat_sessions_id_fk" FOREIGN KEY ("chat_session_id") REFERENCES "public"."chat_sessions"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "automations" ADD CONSTRAINT "automations_organization_id_organizations_id_fk" FOREIGN KEY ("organization_id") REFERENCES "auth"."organizations"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "automations" ADD CONSTRAINT "automations_owner_user_id_users_id_fk" FOREIGN KEY ("owner_user_id") REFERENCES "auth"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "automations" ADD CONSTRAINT "automations_v2_project_id_v2_projects_id_fk" FOREIGN KEY ("v2_project_id") REFERENCES "public"."v2_projects"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "chat_attachments" ADD CONSTRAINT "chat_attachments_chat_session_id_chat_sessions_id_fk" FOREIGN KEY ("chat_session_id") REFERENCES "public"."chat_sessions"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "chat_attachments" ADD CONSTRAINT "chat_attachments_created_by_users_id_fk" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "chat_attachments" ADD CONSTRAINT "chat_attachments_organization_id_organizations_id_fk" FOREIGN KEY ("organization_id") REFERENCES "auth"."organizations"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "chat_sessions" ADD CONSTRAINT "chat_sessions_organization_id_organizations_id_fk" FOREIGN KEY ("organization_id") REFERENCES "auth"."organizations"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "chat_sessions" ADD CONSTRAINT "chat_sessions_created_by_users_id_fk" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "chat_sessions" ADD CONSTRAINT "chat_sessions_workspace_id_workspaces_id_fk" FOREIGN KEY ("workspace_id") REFERENCES "public"."workspaces"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "chat_sessions" ADD CONSTRAINT "chat_sessions_v2_workspace_id_v2_workspaces_id_fk" FOREIGN KEY ("v2_workspace_id") REFERENCES "public"."v2_workspaces"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "device_presence" ADD CONSTRAINT "device_presence_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "device_presence" ADD CONSTRAINT "device_presence_organization_id_organizations_id_fk" FOREIGN KEY ("organization_id") REFERENCES "auth"."organizations"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "integration_connections" ADD CONSTRAINT "integration_connections_organization_id_organizations_id_fk" FOREIGN KEY ("organization_id") REFERENCES "auth"."organizations"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "integration_connections" ADD CONSTRAINT "integration_connections_connected_by_user_id_users_id_fk" FOREIGN KEY ("connected_by_user_id") REFERENCES "auth"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "projects" ADD CONSTRAINT "projects_organization_id_organizations_id_fk" FOREIGN KEY ("organization_id") REFERENCES "auth"."organizations"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "projects" ADD CONSTRAINT "projects_github_repository_id_github_repositories_id_fk" FOREIGN KEY ("github_repository_id") REFERENCES "public"."github_repositories"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "sandbox_images" ADD CONSTRAINT "sandbox_images_organization_id_organizations_id_fk" FOREIGN KEY ("organization_id") REFERENCES "auth"."organizations"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "sandbox_images" ADD CONSTRAINT "sandbox_images_project_id_projects_id_fk" FOREIGN KEY ("project_id") REFERENCES "public"."projects"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "secrets" ADD CONSTRAINT "secrets_organization_id_organizations_id_fk" FOREIGN KEY ("organization_id") REFERENCES "auth"."organizations"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "secrets" ADD CONSTRAINT "secrets_project_id_projects_id_fk" FOREIGN KEY ("project_id") REFERENCES "public"."projects"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "secrets" ADD CONSTRAINT "secrets_created_by_user_id_users_id_fk" FOREIGN KEY ("created_by_user_id") REFERENCES "auth"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "submitted_prompts" ADD CONSTRAINT "submitted_prompts_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "submitted_prompts" ADD CONSTRAINT "submitted_prompts_organization_id_organizations_id_fk" FOREIGN KEY ("organization_id") REFERENCES "auth"."organizations"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "subscriptions" ADD CONSTRAINT "subscriptions_reference_id_organizations_id_fk" FOREIGN KEY ("reference_id") REFERENCES "auth"."organizations"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "task_statuses" ADD CONSTRAINT "task_statuses_organization_id_organizations_id_fk" FOREIGN KEY ("organization_id") REFERENCES "auth"."organizations"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "tasks" ADD CONSTRAINT "tasks_status_id_task_statuses_id_fk" FOREIGN KEY ("status_id") REFERENCES "public"."task_statuses"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "tasks" ADD CONSTRAINT "tasks_organization_id_organizations_id_fk" FOREIGN KEY ("organization_id") REFERENCES "auth"."organizations"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "tasks" ADD CONSTRAINT "tasks_assignee_id_users_id_fk" FOREIGN KEY ("assignee_id") REFERENCES "auth"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "tasks" ADD CONSTRAINT "tasks_creator_id_users_id_fk" FOREIGN KEY ("creator_id") REFERENCES "auth"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "users__slack_users" ADD CONSTRAINT "users__slack_users_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "users__slack_users" ADD CONSTRAINT "users__slack_users_organization_id_organizations_id_fk" FOREIGN KEY ("organization_id") REFERENCES "auth"."organizations"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "v2_clients" ADD CONSTRAINT "v2_clients_organization_id_organizations_id_fk" FOREIGN KEY ("organization_id") REFERENCES "auth"."organizations"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "v2_clients" ADD CONSTRAINT "v2_clients_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "v2_hosts" ADD CONSTRAINT "v2_hosts_organization_id_organizations_id_fk" FOREIGN KEY ("organization_id") REFERENCES "auth"."organizations"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "v2_hosts" ADD CONSTRAINT "v2_hosts_created_by_user_id_users_id_fk" FOREIGN KEY ("created_by_user_id") REFERENCES "auth"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "v2_projects" ADD CONSTRAINT "v2_projects_organization_id_organizations_id_fk" FOREIGN KEY ("organization_id") REFERENCES "auth"."organizations"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "v2_projects" ADD CONSTRAINT "v2_projects_github_repository_id_github_repositories_id_fk" FOREIGN KEY ("github_repository_id") REFERENCES "public"."github_repositories"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "v2_remote_control_sessions" ADD CONSTRAINT "v2_remote_control_sessions_organization_id_organizations_id_fk" FOREIGN KEY ("organization_id") REFERENCES "auth"."organizations"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "v2_remote_control_sessions" ADD CONSTRAINT "v2_remote_control_sessions_workspace_id_v2_workspaces_id_fk" FOREIGN KEY ("workspace_id") REFERENCES "public"."v2_workspaces"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "v2_remote_control_sessions" ADD CONSTRAINT "v2_remote_control_sessions_created_by_user_id_users_id_fk" FOREIGN KEY ("created_by_user_id") REFERENCES "auth"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "v2_remote_control_sessions" ADD CONSTRAINT "v2_remote_control_sessions_revoked_by_user_id_users_id_fk" FOREIGN KEY ("revoked_by_user_id") REFERENCES "auth"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "v2_remote_control_sessions" ADD CONSTRAINT "v2_remote_control_sessions_host_fk" FOREIGN KEY ("organization_id","host_id") REFERENCES "public"."v2_hosts"("organization_id","machine_id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "v2_users_hosts" ADD CONSTRAINT "v2_users_hosts_organization_id_organizations_id_fk" FOREIGN KEY ("organization_id") REFERENCES "auth"."organizations"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "v2_users_hosts" ADD CONSTRAINT "v2_users_hosts_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "v2_users_hosts" ADD CONSTRAINT "v2_users_hosts_host_fk" FOREIGN KEY ("organization_id","host_id") REFERENCES "public"."v2_hosts"("organization_id","machine_id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "v2_workspaces" ADD CONSTRAINT "v2_workspaces_organization_id_organizations_id_fk" FOREIGN KEY ("organization_id") REFERENCES "auth"."organizations"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "v2_workspaces" ADD CONSTRAINT "v2_workspaces_project_id_v2_projects_id_fk" FOREIGN KEY ("project_id") REFERENCES "public"."v2_projects"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "v2_workspaces" ADD CONSTRAINT "v2_workspaces_created_by_user_id_users_id_fk" FOREIGN KEY ("created_by_user_id") REFERENCES "auth"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "v2_workspaces" ADD CONSTRAINT "v2_workspaces_task_id_tasks_id_fk" FOREIGN KEY ("task_id") REFERENCES "public"."tasks"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "v2_workspaces" ADD CONSTRAINT "v2_workspaces_host_fk" FOREIGN KEY ("organization_id","host_id") REFERENCES "public"."v2_hosts"("organization_id","machine_id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "workspaces" ADD CONSTRAINT "workspaces_organization_id_organizations_id_fk" FOREIGN KEY ("organization_id") REFERENCES "auth"."organizations"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "workspaces" ADD CONSTRAINT "workspaces_project_id_projects_id_fk" FOREIGN KEY ("project_id") REFERENCES "public"."projects"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "workspaces" ADD CONSTRAINT "workspaces_created_by_user_id_users_id_fk" FOREIGN KEY ("created_by_user_id") REFERENCES "auth"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "accounts_user_id_idx" ON "auth"."accounts" USING btree ("user_id");--> statement-breakpoint
CREATE INDEX "apikeys_configId_idx" ON "auth"."apikeys" USING btree ("config_id");--> statement-breakpoint
CREATE INDEX "apikeys_referenceId_idx" ON "auth"."apikeys" USING btree ("reference_id");--> statement-breakpoint
CREATE INDEX "apikeys_key_idx" ON "auth"."apikeys" USING btree ("key");--> statement-breakpoint
CREATE INDEX "apikeys_organization_id_idx" ON "auth"."apikeys" USING btree ("organization_id");--> statement-breakpoint
CREATE INDEX "apikeys_metadata_trgm_idx" ON "auth"."apikeys" USING gin ("metadata" gin_trgm_ops);--> statement-breakpoint
CREATE INDEX "invitations_organization_id_idx" ON "auth"."invitations" USING btree ("organization_id");--> statement-breakpoint
CREATE INDEX "invitations_email_idx" ON "auth"."invitations" USING btree ("email");--> statement-breakpoint
CREATE INDEX "members_organization_id_idx" ON "auth"."members" USING btree ("organization_id");--> statement-breakpoint
CREATE INDEX "members_user_id_idx" ON "auth"."members" USING btree ("user_id");--> statement-breakpoint
CREATE UNIQUE INDEX "organizations_slug_idx" ON "auth"."organizations" USING btree ("slug");--> statement-breakpoint
CREATE INDEX "organizations_allowed_domains_idx" ON "auth"."organizations" USING gin ("allowed_domains");--> statement-breakpoint
CREATE INDEX "sessions_user_id_idx" ON "auth"."sessions" USING btree ("user_id");--> statement-breakpoint
CREATE INDEX "team_members_team_id_idx" ON "auth"."team_members" USING btree ("team_id");--> statement-breakpoint
CREATE INDEX "team_members_user_id_idx" ON "auth"."team_members" USING btree ("user_id");--> statement-breakpoint
CREATE INDEX "team_members_organization_id_idx" ON "auth"."team_members" USING btree ("organization_id");--> statement-breakpoint
CREATE UNIQUE INDEX "team_members_team_user_unique" ON "auth"."team_members" USING btree ("team_id","user_id");--> statement-breakpoint
CREATE INDEX "teams_organization_id_idx" ON "auth"."teams" USING btree ("organization_id");--> statement-breakpoint
CREATE UNIQUE INDEX "teams_org_slug_unique" ON "auth"."teams" USING btree ("organization_id","slug");--> statement-breakpoint
CREATE INDEX "users_organization_ids_idx" ON "auth"."users" USING gin ("organization_ids");--> statement-breakpoint
CREATE INDEX "verifications_identifier_idx" ON "auth"."verifications" USING btree ("identifier");--> statement-breakpoint
CREATE INDEX "github_pull_requests_repository_id_idx" ON "github_pull_requests" USING btree ("repository_id");--> statement-breakpoint
CREATE INDEX "github_pull_requests_state_idx" ON "github_pull_requests" USING btree ("state");--> statement-breakpoint
CREATE INDEX "github_pull_requests_head_branch_idx" ON "github_pull_requests" USING btree ("head_branch");--> statement-breakpoint
CREATE INDEX "github_pull_requests_org_id_idx" ON "github_pull_requests" USING btree ("organization_id");--> statement-breakpoint
CREATE INDEX "github_repositories_full_name_idx" ON "github_repositories" USING btree ("full_name");--> statement-breakpoint
CREATE INDEX "github_repositories_org_id_idx" ON "github_repositories" USING btree ("organization_id");--> statement-breakpoint
CREATE INDEX "webhook_events_provider_status_idx" ON "ingest"."webhook_events" USING btree ("provider","status");--> statement-breakpoint
CREATE UNIQUE INDEX "webhook_events_provider_event_id_idx" ON "ingest"."webhook_events" USING btree ("provider","event_id");--> statement-breakpoint
CREATE INDEX "webhook_events_received_at_idx" ON "ingest"."webhook_events" USING btree ("received_at");--> statement-breakpoint
CREATE INDEX "agent_commands_user_status_idx" ON "agent_commands" USING btree ("user_id","status");--> statement-breakpoint
CREATE INDEX "agent_commands_target_device_status_idx" ON "agent_commands" USING btree ("target_device_id","status");--> statement-breakpoint
CREATE INDEX "agent_commands_org_created_idx" ON "agent_commands" USING btree ("organization_id","created_at");--> statement-breakpoint
CREATE UNIQUE INDEX "automation_prompt_versions_bucket_uniq" ON "automation_prompt_versions" USING btree ("automation_id","author_user_id","window_bucket") WHERE "automation_prompt_versions"."source" <> 'restore';--> statement-breakpoint
CREATE INDEX "automation_prompt_versions_automation_idx" ON "automation_prompt_versions" USING btree ("automation_id","updated_at");--> statement-breakpoint
CREATE UNIQUE INDEX "automation_runs_dedup_idx" ON "automation_runs" USING btree ("automation_id","scheduled_for");--> statement-breakpoint
CREATE INDEX "automation_runs_history_idx" ON "automation_runs" USING btree ("automation_id","created_at");--> statement-breakpoint
CREATE INDEX "automation_runs_status_idx" ON "automation_runs" USING btree ("status");--> statement-breakpoint
CREATE INDEX "automation_runs_workspace_idx" ON "automation_runs" USING btree ("v2_workspace_id");--> statement-breakpoint
CREATE INDEX "automations_dispatcher_idx" ON "automations" USING btree ("enabled","next_run_at");--> statement-breakpoint
CREATE INDEX "automations_owner_idx" ON "automations" USING btree ("owner_user_id");--> statement-breakpoint
CREATE INDEX "automations_organization_idx" ON "automations" USING btree ("organization_id");--> statement-breakpoint
CREATE INDEX "chat_attachments_session_idx" ON "chat_attachments" USING btree ("chat_session_id");--> statement-breakpoint
CREATE INDEX "chat_attachments_created_by_idx" ON "chat_attachments" USING btree ("created_by");--> statement-breakpoint
CREATE INDEX "chat_sessions_org_idx" ON "chat_sessions" USING btree ("organization_id");--> statement-breakpoint
CREATE INDEX "chat_sessions_created_by_idx" ON "chat_sessions" USING btree ("created_by");--> statement-breakpoint
CREATE INDEX "chat_sessions_last_active_idx" ON "chat_sessions" USING btree ("last_active_at");--> statement-breakpoint
CREATE INDEX "device_presence_user_org_idx" ON "device_presence" USING btree ("user_id","organization_id");--> statement-breakpoint
CREATE UNIQUE INDEX "device_presence_user_device_idx" ON "device_presence" USING btree ("user_id","device_id");--> statement-breakpoint
CREATE INDEX "device_presence_last_seen_idx" ON "device_presence" USING btree ("last_seen_at");--> statement-breakpoint
CREATE UNIQUE INDEX "integration_connections_slack_external_org_active_unique" ON "integration_connections" USING btree ("external_org_id") WHERE "integration_connections"."provider" = 'slack' AND "integration_connections"."disconnected_at" IS NULL;--> statement-breakpoint
CREATE INDEX "integration_connections_org_idx" ON "integration_connections" USING btree ("organization_id");--> statement-breakpoint
CREATE INDEX "projects_organization_id_idx" ON "projects" USING btree ("organization_id");--> statement-breakpoint
CREATE INDEX "sandbox_images_organization_id_idx" ON "sandbox_images" USING btree ("organization_id");--> statement-breakpoint
CREATE INDEX "secrets_project_id_idx" ON "secrets" USING btree ("project_id");--> statement-breakpoint
CREATE INDEX "secrets_organization_id_idx" ON "secrets" USING btree ("organization_id");--> statement-breakpoint
CREATE INDEX "submitted_prompts_user_id_idx" ON "submitted_prompts" USING btree ("user_id");--> statement-breakpoint
CREATE INDEX "submitted_prompts_organization_id_idx" ON "submitted_prompts" USING btree ("organization_id");--> statement-breakpoint
CREATE INDEX "submitted_prompts_created_at_idx" ON "submitted_prompts" USING btree ("created_at");--> statement-breakpoint
CREATE INDEX "subscriptions_reference_id_idx" ON "subscriptions" USING btree ("reference_id");--> statement-breakpoint
CREATE INDEX "subscriptions_stripe_customer_id_idx" ON "subscriptions" USING btree ("stripe_customer_id");--> statement-breakpoint
CREATE INDEX "subscriptions_status_idx" ON "subscriptions" USING btree ("status");--> statement-breakpoint
CREATE INDEX "task_statuses_organization_id_idx" ON "task_statuses" USING btree ("organization_id");--> statement-breakpoint
CREATE INDEX "task_statuses_type_idx" ON "task_statuses" USING btree ("type");--> statement-breakpoint
CREATE INDEX "tasks_slug_idx" ON "tasks" USING btree ("slug");--> statement-breakpoint
CREATE INDEX "tasks_organization_id_idx" ON "tasks" USING btree ("organization_id");--> statement-breakpoint
CREATE INDEX "tasks_assignee_id_idx" ON "tasks" USING btree ("assignee_id");--> statement-breakpoint
CREATE INDEX "tasks_creator_id_idx" ON "tasks" USING btree ("creator_id");--> statement-breakpoint
CREATE INDEX "tasks_status_id_idx" ON "tasks" USING btree ("status_id");--> statement-breakpoint
CREATE INDEX "tasks_created_at_idx" ON "tasks" USING btree ("created_at");--> statement-breakpoint
CREATE INDEX "tasks_external_provider_idx" ON "tasks" USING btree ("external_provider");--> statement-breakpoint
CREATE INDEX "tasks_assignee_external_id_idx" ON "tasks" USING btree ("assignee_external_id");--> statement-breakpoint
CREATE INDEX "users__slack_users_user_idx" ON "users__slack_users" USING btree ("user_id");--> statement-breakpoint
CREATE INDEX "users__slack_users_org_idx" ON "users__slack_users" USING btree ("organization_id");--> statement-breakpoint
CREATE INDEX "v2_clients_organization_id_idx" ON "v2_clients" USING btree ("organization_id");--> statement-breakpoint
CREATE INDEX "v2_clients_user_id_idx" ON "v2_clients" USING btree ("user_id");--> statement-breakpoint
CREATE INDEX "v2_hosts_organization_id_idx" ON "v2_hosts" USING btree ("organization_id");--> statement-breakpoint
CREATE INDEX "v2_projects_organization_id_idx" ON "v2_projects" USING btree ("organization_id");--> statement-breakpoint
CREATE UNIQUE INDEX "v2_remote_control_sessions_token_hash_uniq" ON "v2_remote_control_sessions" USING btree ("token_hash");--> statement-breakpoint
CREATE INDEX "v2_remote_control_sessions_organization_id_idx" ON "v2_remote_control_sessions" USING btree ("organization_id");--> statement-breakpoint
CREATE INDEX "v2_remote_control_sessions_host_id_idx" ON "v2_remote_control_sessions" USING btree ("host_id");--> statement-breakpoint
CREATE INDEX "v2_remote_control_sessions_workspace_id_idx" ON "v2_remote_control_sessions" USING btree ("workspace_id");--> statement-breakpoint
CREATE INDEX "v2_remote_control_sessions_terminal_id_idx" ON "v2_remote_control_sessions" USING btree ("terminal_id");--> statement-breakpoint
CREATE INDEX "v2_remote_control_sessions_status_idx" ON "v2_remote_control_sessions" USING btree ("status");--> statement-breakpoint
CREATE INDEX "v2_users_hosts_organization_id_idx" ON "v2_users_hosts" USING btree ("organization_id");--> statement-breakpoint
CREATE INDEX "v2_users_hosts_user_id_idx" ON "v2_users_hosts" USING btree ("user_id");--> statement-breakpoint
CREATE INDEX "v2_users_hosts_host_id_idx" ON "v2_users_hosts" USING btree ("host_id");--> statement-breakpoint
CREATE INDEX "v2_workspaces_project_id_idx" ON "v2_workspaces" USING btree ("project_id");--> statement-breakpoint
CREATE INDEX "v2_workspaces_organization_id_idx" ON "v2_workspaces" USING btree ("organization_id");--> statement-breakpoint
CREATE INDEX "v2_workspaces_host_id_idx" ON "v2_workspaces" USING btree ("host_id");--> statement-breakpoint
CREATE INDEX "v2_workspaces_task_id_idx" ON "v2_workspaces" USING btree ("task_id");--> statement-breakpoint
CREATE UNIQUE INDEX "v2_workspaces_one_main_per_host" ON "v2_workspaces" USING btree ("project_id","host_id") WHERE "v2_workspaces"."type" = 'main';--> statement-breakpoint
CREATE INDEX "workspaces_project_id_idx" ON "workspaces" USING btree ("project_id");--> statement-breakpoint
CREATE INDEX "workspaces_organization_id_idx" ON "workspaces" USING btree ("organization_id");--> statement-breakpoint
CREATE INDEX "workspaces_type_idx" ON "workspaces" USING btree ("type");