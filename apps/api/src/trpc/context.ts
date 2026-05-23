import { createTRPCContext } from "@superset/trpc";

export const createContext = async ({
	req,
}: {
	req: Request;
	resHeaders: Headers;
}) => createTRPCContext({ headers: req.headers });
