import { HttpParams } from '@angular/common/http';

/** Inputs of ``pnx-autocomplete`` that translate into the request */
export interface AutocompleteQuery {
  apiEndPoint: string;
  searchAsParameter?: boolean;
  queryParamSearch?: string;
  othersGetParams?: { [param: string]: any };
}

/**
 * Build the URL and the query string of the API call searching ``term``.
 * The term is put in the URL when ``searchAsParameter``, in the query string otherwise.
 */
export function buildAutocompleteRequest(
  query: AutocompleteQuery,
  term: string
): { url: string; params: HttpParams } {
  let url = query.apiEndPoint;
  let params = new HttpParams();
  if (query.searchAsParameter) {
    url = url + '/' + term;
  } else {
    params = params.append(query.queryParamSearch, term);
  }
  if (query.othersGetParams) {
    for (const param in query.othersGetParams) {
      // check if the param is not null
      if (query.othersGetParams[param]) {
        params = params.append(param, query.othersGetParams[param].toString());
      }
    }
  }
  return { url, params };
}
