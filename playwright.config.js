const { defineConfig, devices } = require("@playwright/test");

module.exports = defineConfig({
  testDir: "./spec/browser",
  testMatch: "**/*.spec.js",
  fullyParallel: true,
  reporter: "line",
  use: {
    baseURL: "http://127.0.0.1:4173",
    trace: "retain-on-failure",
    ...devices["Desktop Chrome"]
  },
  webServer: {
    command: "rake install_local && ruby spec/browser/build_site.rb > .browser-server-root && ruby -run -e httpd -- -p 4173 $(cat .browser-server-root)",
    url: "http://127.0.0.1:4173/manual/",
    reuseExistingServer: false,
    timeout: 120000
  }
});
