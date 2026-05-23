import { expect, test } from "@playwright/test";

test.describe("sign-in page", () => {
	test("renders provider buttons and footer links", async ({ page }) => {
		await page.goto("/sign-in");

		await expect(
			page.getByRole("heading", { name: "Welcome back" }),
		).toBeVisible();

		await expect(
			page.getByRole("button", { name: /sign in with github/i }),
		).toBeVisible();

		await expect(
			page.getByRole("button", { name: /sign in with google/i }),
		).toBeVisible();

		await expect(page.getByRole("link", { name: /sign up/i })).toHaveAttribute(
			"href",
			"/sign-up",
		);
	});
});
