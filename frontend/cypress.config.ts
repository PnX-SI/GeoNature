import { defineConfig } from "cypress";

export default defineConfig({
  experimentalStudio: true,
  projectId: "r36uo2",
  videosFolder: "cypress/videos",
  screenshotsFolder: "cypress/screenshots",
  fixturesFolder: "cypress/fixtures",
  defaultCommandTimeout: 30000,
  requestTimeout: 10000,

  e2e: {
    // We've imported your old cypress plugins here.
    // You may want to clean this up later by importing these.
    setupNodeEvents(on, config) {
      return require("./cypress/plugins/index.js")(on, config);
    },
    baseUrl: "http://127.0.0.1:4200",
    specPattern: "cypress/e2e/**/*.{js,jsx,ts,tsx}",
    supportFile: false,
  },

  component: {
    devServer: {
      framework: "angular",
      bundler: "webpack",
    },
    specPattern: "**/*.cy.ts",
  },
});
