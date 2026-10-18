import { buildAutocompleteRequest } from './autocomplete.utils';

describe('buildAutocompleteRequest', () => {
  it('puts the term in the query string', () => {
    const { url, params } = buildAutocompleteRequest(
      { apiEndPoint: 'http://api/search', queryParamSearch: 'q' },
      'canis'
    );
    expect(url).toBe('http://api/search');
    expect(params.toString()).toBe('q=canis');
  });

  it('puts the term in the URL', () => {
    const { url, params } = buildAutocompleteRequest(
      { apiEndPoint: 'http://api/search', searchAsParameter: true },
      'canis'
    );
    expect(url).toBe('http://api/search/canis');
    expect(params.keys()).toEqual([]);
  });

  it('adds the other params, except the empty ones', () => {
    const { params } = buildAutocompleteRequest(
      {
        apiEndPoint: 'http://api',
        queryParamSearch: 'q',
        othersGetParams: { limit: 10, regne: null, group: '', ids: [1, 2] },
      },
      'c'
    );
    expect(params.toString()).toBe('q=c&limit=10&ids=1,2');
  });
});
