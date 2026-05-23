import { execFile, spawn } from "node:child_process";
import { promisify } from "node:util";

const execFileP = promisify(execFile);
const MAX_BUFFER = 16 * 1024 * 1024;

export class GhCliError extends Error {
	constructor(
		message: string,
		public readonly stderr?: string,
	) {
		super(message);
		this.name = "GhCliError";
	}
}

export async function runGh(args: string[]): Promise<string> {
	try {
		const { stdout } = await execFileP("gh", args, { maxBuffer: MAX_BUFFER });
		return stdout;
	} catch (error) {
		if (error instanceof Error) {
			const stderr = (error as NodeJS.ErrnoException & { stderr?: string })
				.stderr;
			throw new GhCliError(`gh ${args[0]} failed: ${error.message}`, stderr);
		}
		throw error;
	}
}

function runGhWithStdin(args: string[], stdin: string): Promise<string> {
	return new Promise((resolve, reject) => {
		const child = spawn("gh", args, { stdio: ["pipe", "pipe", "pipe"] });
		const stdoutChunks: Buffer[] = [];
		const stderrChunks: Buffer[] = [];
		let stdoutBytes = 0;

		child.stdout.on("data", (chunk: Buffer) => {
			stdoutBytes += chunk.length;
			if (stdoutBytes > MAX_BUFFER) {
				child.kill("SIGKILL");
				reject(new GhCliError(`gh stdout exceeded ${MAX_BUFFER} bytes`));
				return;
			}
			stdoutChunks.push(chunk);
		});
		child.stderr.on("data", (chunk: Buffer) => stderrChunks.push(chunk));
		child.on("error", (err) => reject(new GhCliError(err.message)));
		child.on("close", (code) => {
			const stdout = Buffer.concat(stdoutChunks).toString("utf8");
			const stderr = Buffer.concat(stderrChunks).toString("utf8");
			if (code === 0) {
				resolve(stdout);
			} else {
				reject(
					new GhCliError(`gh exited with code ${code}: ${stderr}`, stderr),
				);
			}
		});

		child.stdin.end(stdin);
	});
}

export async function ghGraphQL<T>(
	query: string,
	variables: Record<string, unknown> = {},
): Promise<T> {
	const body = JSON.stringify({ query, variables });
	const stdout = await runGhWithStdin(["api", "graphql", "--input", "-"], body);
	const parsed = JSON.parse(stdout) as { data?: T; errors?: unknown };
	if (parsed.errors) {
		throw new GhCliError(
			`gh GraphQL returned errors: ${JSON.stringify(parsed.errors)}`,
		);
	}
	if (!parsed.data) {
		throw new GhCliError("gh GraphQL returned no data");
	}
	return parsed.data;
}

type GhStatus = { available: boolean; login: string | null };

let statusCache: { at: number; value: GhStatus } | null = null;
const STATUS_TTL_MS = 60_000;

export async function ghStatus(): Promise<GhStatus> {
	if (statusCache && Date.now() - statusCache.at < STATUS_TTL_MS) {
		return statusCache.value;
	}
	try {
		const stdout = await runGh(["api", "user", "--jq", "{login: .login}"]);
		const { login } = JSON.parse(stdout) as { login: string };
		statusCache = { at: Date.now(), value: { available: true, login } };
	} catch {
		statusCache = { at: Date.now(), value: { available: false, login: null } };
	}
	return statusCache.value;
}
