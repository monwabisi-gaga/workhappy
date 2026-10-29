import { expect, test } from "@playwright/test";

test.describe("assessment dashboard", () => {
  test("opens the company dashboard and prevents future date selection", async ({ page }) => {
    await page.goto("/");
    await expect(page.getByRole("heading", { name: /clearer view/i })).toBeVisible();

    await page.getByRole("button", { name: "Open demo dashboard" }).click();
    await expect(page).toHaveURL(/\/assessments$/);
    await expect(page.getByRole("heading", { name: "Acme Health" })).toBeVisible();

    const today = new Date().toISOString().slice(0, 10);
    await expect(page.locator("form.filter-form input[name='from']")).toHaveAttribute("max", today);
    await expect(page.locator("form.filter-form input[name='to']")).toHaveAttribute("max", today);
  });

  test("filters the dashboard by status", async ({ page }) => {
    await page.goto("/");
    await page.getByRole("button", { name: "Open demo dashboard" }).click();

    await page.locator("select[name='status']").selectOption("in_progress");
    await page.getByRole("button", { name: "Apply filters" }).click();

    await expect(page.getByRole("cell", { name: "In progress" })).toBeVisible();
    await expect(page.getByRole("cell", { name: "Completed" })).not.toBeVisible();
  });

  test("downloads a redacted CSV export", async ({ page }) => {
    await page.goto("/");
    await page.getByRole("button", { name: "Open demo dashboard" }).click();

    const downloadPromise = page.waitForEvent("download");
    await page.getByRole("button", { name: "Export safe CSV" }).click();
    await expect(page.locator("[data-export-feedback]")).toHaveText("Preparing download…");
    const download = await downloadPromise;
    expect(download.suggestedFilename()).toBe("assessments.csv");

    const stream = await download.createReadStream();
    let content = "";
    if (stream) {
      for await (const chunk of stream) content += chunk.toString();
    }
    expect(content).toContain("assessment_id,status,created_at,score");
    expect(content).not.toContain("private@example.test");
    expect(content).not.toContain("questions");
  });
});
