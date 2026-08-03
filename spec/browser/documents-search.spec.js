const { test, expect } = require("@playwright/test");
const path = require("path");

const lunrScript = path.resolve("node_modules/lunr/lunr.min.js");

test.beforeEach(async ({ page }) => {
  await page.route("https://unpkg.com/lunr/lunr.js", route => route.fulfill({ path: lunrScript }));
});

test("searches the generated index and renders a baseurl-safe result", async ({ page }) => {
  await page.goto("/manual/");

  const input = page.locator("#doc-search-input");
  const results = page.locator("#doc-search-results");
  await expect(input).toBeVisible();

  await input.fill("Annual");

  await expect(results).toContainText("Annual Report");
  await expect(results.locator("a")).toHaveAttribute(
    "href",
    "/manual/documents/reports/annual-report/"
  );
  await expect(results.locator("img")).toHaveAttribute(
    "src",
    "/manual/assets/icons/color/pdf-document-svgrepo-com.svg"
  );
});

test("renders no-results feedback for an unmatched query", async ({ page }) => {
  await page.goto("/manual/");
  await page.locator("#doc-search-input").fill("does-not-exist");

  await expect(page.locator("#doc-search-results")).toContainText("No results.");
});

test("does not report browser console or network errors", async ({ page }) => {
  const consoleErrors = [];
  const failedRequests = [];
  page.on("console", message => {
    if (message.type() === "error") consoleErrors.push(message.text());
  });
  page.on("requestfailed", request => failedRequests.push(request.url()));

  await page.goto("/manual/");
  await expect(page.locator("#doc-search-input")).toBeVisible();
  await page.locator("#doc-search-input").fill("Annual");
  await expect(page.locator("#doc-search-results")).toContainText("Annual Report");

  expect(consoleErrors).toEqual([]);
  expect(failedRequests).toEqual([]);
});
