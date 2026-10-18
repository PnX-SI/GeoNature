import { taxonSearchEndPoint } from './taxonomy.utils';

describe('taxonSearchEndPoint', () => {
  it('targets the names of a list', () => {
    expect(taxonSearchEndPoint('http://th/api', 100)).toBe(
      'http://th/api/taxref/allnamebylist/100'
    );
  });

  it('targets all the names without list', () => {
    expect(taxonSearchEndPoint('http://th/api')).toBe('http://th/api/taxref/allnamebylist');
    expect(taxonSearchEndPoint('http://th/api', null)).toBe('http://th/api/taxref/allnamebylist');
  });
});
