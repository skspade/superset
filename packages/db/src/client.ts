import { config } from "dotenv";
import { drizzle } from "drizzle-orm/postgres-js";
import postgres from "postgres";

import { env } from "./env";
import * as schema from "./schema";

config({ path: ".env", quiet: true });

const client = postgres(env.DATABASE_URL);

export const db = drizzle({
	client,
	schema,
	casing: "snake_case",
});

export const dbWs = db;
