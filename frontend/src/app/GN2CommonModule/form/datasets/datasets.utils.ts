/** Inputs of ``pnx-datasets`` that translate into API query parameters */
export interface DatasetsQuery {
  displayOnlyActive?: boolean;
  moduleCode?: string;
  creatableInModule?: string;
}

/**
 * Build the parameters of the datasets API call
 * @param query component inputs
 * @param params additional parameters (ex: acquisition framework filters), kept as is
 */
export function buildDatasetsParams(query: DatasetsQuery, params: Object = {}): Object {
  const filterParams = { ...params };
  if (query.displayOnlyActive) {
    filterParams['active'] = true;
  }
  if (query.moduleCode) {
    filterParams['module_code'] = query.moduleCode;
  }
  if (query.creatableInModule) {
    filterParams['create'] = query.creatableInModule;
  }
  return filterParams;
}
