const DEFAULT_DECODE_OPTIONS = { encoding: 'utf-8', format: 'csv', srid: 4326, separator: ';' };

// Fast-forwards an import through the wizard's early steps via direct API calls
// (mirroring backend/geonature/tests/imports/fixtures.py) instead of driving the
// upload/decode/fieldmapping/contentmapping UI, which is what actually dominates
// runtime for specs that only test a later step.

Cypress.Commands.add('uploadImportFileViaApi', (destination, fixtureFile) => {
  const apiEndpoint = Cypress.env('apiEndpoint');
  const fileName = fixtureFile.split('/').pop();
  const boundary = `CypressFormBoundary${Date.now()}`;
  // Built by hand rather than via FormData/Blob: Cypress's cy.request() re-serializes a
  // FormData body itself (see its FormData branch in cypress_runner.js), and the code
  // meant to strip a manually-set Content-Type header there has a bug (it inspects
  // Object.keys(requestOpts) instead of requestOpts.headers), so an explicit header
  // survives alongside Cypress's own — two conflicting Content-Type headers reach the
  // server and Werkzeug fails to parse the multipart body. A hand-built body sidesteps it.
  return cy.fixture(fixtureFile, 'utf-8').then((fileContent) => {
    const body =
      `--${boundary}\r\n` +
      `Content-Disposition: form-data; name="file"; filename="${fileName}"\r\n` +
      `Content-Type: text/csv\r\n\r\n` +
      `${fileContent}\r\n` +
      `--${boundary}--\r\n`;
    return cy
      .request({
        method: 'POST',
        url: `${apiEndpoint}import/${destination}/imports/upload`,
        headers: { 'content-type': `multipart/form-data; boundary=${boundary}` },
        body,
      })
      .then((response) => response.body.id_import);
  });
});

Cypress.Commands.add('decodeImportViaApi', (destination, importId) => {
  const apiEndpoint = Cypress.env('apiEndpoint');
  return cy.request({
    method: 'POST',
    url: `${apiEndpoint}import/${destination}/imports/${importId}/decode`,
    body: DEFAULT_DECODE_OPTIONS,
  });
});

Cypress.Commands.add('setFieldMappingViaApi', (destination, importId, { label, datasetName }) => {
  const apiEndpoint = Cypress.env('apiEndpoint');
  return cy
    .request('GET', `${apiEndpoint}import/${destination}/fieldmappings/`)
    .then((response) => {
      const preset = response.body.find((mapping) => mapping.label === label);
      const values = { ...preset.values };
      if (!datasetName) {
        return values;
      }
      return cy.request('GET', `${apiEndpoint}meta/datasets`).then((datasetsResponse) => {
        const dataset = datasetsResponse.body.find((d) => d.dataset_name === datasetName);
        values.unique_dataset_id = { constant_value: dataset.unique_dataset_id };
        return values;
      });
    })
    .then((values) =>
      cy.request({
        method: 'POST',
        url: `${apiEndpoint}import/${destination}/imports/${importId}/fieldmapping`,
        body: values,
      })
    );
});

Cypress.Commands.add('loadImportDataViaApi', (destination, importId) => {
  const apiEndpoint = Cypress.env('apiEndpoint');
  return cy.request('POST', `${apiEndpoint}import/${destination}/imports/${importId}/load`);
});

Cypress.Commands.add('setContentMappingViaApi', (destination, importId, label) => {
  const apiEndpoint = Cypress.env('apiEndpoint');
  return cy
    .request('GET', `${apiEndpoint}import/${destination}/contentmappings/`)
    .then((response) => {
      const preset = response.body.find((mapping) => mapping.label === label);
      return cy.request({
        method: 'POST',
        url: `${apiEndpoint}import/${destination}/imports/${importId}/contentmapping`,
        body: preset.values,
      });
    });
});

Cypress.Commands.add('generateObserverMappingViaApi', (destination, importId) => {
  const apiEndpoint = Cypress.env('apiEndpoint');
  return cy.request(
    'GET',
    `${apiEndpoint}import/${destination}/generate_user_matching/${importId}`
  );
});

// Polls the import until its background Celery task (prepare/import) has finished.
// Gives up loudly (throws) rather than silently letting the test proceed: with the dev
// Celery worker running at concurrency 1, a busy queue can take longer than a short
// poll budget allows, and letting the test move on regardless races the still-running
// task against this test's own cleanup — the task's later commit then targets a
// t_imports row the test has already deleted ("0 were matched" StaleDataError).
Cypress.Commands.add('waitImportTaskDoneViaApi', (destination, importId, attemptsLeft = 200) => {
  const apiEndpoint = Cypress.env('apiEndpoint');
  return cy
    .request('GET', `${apiEndpoint}import/${destination}/imports/${importId}/`)
    .then((response) => {
      if (response.body.task_id === null) {
        return response.body;
      }
      if (attemptsLeft <= 0) {
        throw new Error(
          `waitImportTaskDoneViaApi: import ${importId} still has a running task ` +
            `(task_id=${response.body.task_id}) after the poll budget was exhausted.`
        );
      }
      cy.wait(300);
      return cy.waitImportTaskDoneViaApi(destination, importId, attemptsLeft - 1);
    });
});

Cypress.Commands.add('prepareImportViaApi', (destination, importId) => {
  const apiEndpoint = Cypress.env('apiEndpoint');
  return cy
    .request('POST', `${apiEndpoint}import/${destination}/imports/${importId}/prepare`)
    .then(() => cy.waitImportTaskDoneViaApi(destination, importId));
});

Cypress.Commands.add('finalizeImportViaApi', (destination, importId) => {
  const apiEndpoint = Cypress.env('apiEndpoint');
  return cy
    .request('POST', `${apiEndpoint}import/${destination}/imports/${importId}/import`)
    .then(() => cy.waitImportTaskDoneViaApi(destination, importId));
});

// targetStep is the step page to land on: 'fieldmapping', 'contentmapping', 'observermapping',
// 'import' (the recapitulatif/verification step) or 'report'.
// Yields the created import's id so callers can clean it up (e.g. cy.deleteImport).
Cypress.Commands.add('setupImportViaApi', (targetStep, options = {}) => {
  const {
    destination = 'synthese',
    fixtureFile = 'import/synthese/valid_file_test_link_list_import_synthese.csv',
    datasetName,
    fieldmappingLabel = 'Synthese GeoNature',
    contentmappingLabel = 'Nomenclatures SINP (labels)',
  } = options;

  // cy.visit() to a URL that only differs by hash from the page already loaded doesn't
  // reload the SPA — Angular's router just handles it internally, so the previous import's
  // component state, pending HTTP requests and toasts all survive. That's fatal for repeated
  // setupImportViaApi calls within one test (e.g. restartTheProcess()): stale in-flight
  // requests from a just-deleted import can land and throw error toasts on top of the new
  // page, and reused component instances can carry over stale form/selection state. Force a
  // real reload after navigating so each call starts from a clean Angular bootstrap.
  const visitStep = (url) => {
    cy.visit(url);
    cy.reload();
  };

  return cy.uploadImportFileViaApi(destination, fixtureFile).then((importId) => {
    // Alias as soon as the import exists, not just at the end: callers chain
    // .as('currentImportId') onto this command's final yielded value, but if any later
    // step in this chain (decode/fieldmapping/load/...) throws, the command never yields
    // and that alias never gets attached — leaving the already-created import with no
    // handle for afterEach to delete it. Aliasing here means it's always cleanable, even
    // on a partial failure. (This is exactly how several orphaned test imports accumulated
    // in the dev DB across earlier debugging runs.)
    cy.wrap(importId).as('currentImportId');
    cy.decodeImportViaApi(destination, importId);
    if (targetStep === 'fieldmapping') {
      visitStep(`/#/import/${destination}/process/${importId}/fieldmapping`);
      return cy.wrap(importId);
    }

    cy.setFieldMappingViaApi(destination, importId, {
      label: fieldmappingLabel,
      datasetName,
    });
    cy.loadImportDataViaApi(destination, importId);
    if (targetStep === 'contentmapping') {
      visitStep(`/#/import/${destination}/process/${importId}/contentmapping`);
      return cy.wrap(importId);
    }

    cy.setContentMappingViaApi(destination, importId, contentmappingLabel);
    if (targetStep === 'observermapping') {
      visitStep(`/#/import/${destination}/process/${importId}/observermapping`);
      return cy.wrap(importId);
    }

    cy.generateObserverMappingViaApi(destination, importId);
    cy.prepareImportViaApi(destination, importId);
    if (targetStep === 'import') {
      visitStep(`/#/import/${destination}/process/${importId}/import`);
      return cy.wrap(importId);
    }

    if (targetStep === 'report') {
      cy.finalizeImportViaApi(destination, importId);
      visitStep(`/#/import/${destination}/${importId}/report`);
      return cy.wrap(importId);
    }

    throw new Error(`setupImportViaApi: unknown target step "${targetStep}"`);
  });
});
