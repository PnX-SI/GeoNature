import { buildDatasetsParams } from './datasets.utils';

describe('buildDatasetsParams', () => {
  it('returns the given params when no filter is set', () => {
    expect(buildDatasetsParams({}, { id_acquisition_framework: 3 })).toEqual({
      id_acquisition_framework: 3,
    });
  });

  it('adds the filters from the query', () => {
    expect(
      buildDatasetsParams({
        displayOnlyActive: true,
        moduleCode: 'OCCTAX',
        creatableInModule: 'OCCHAB',
      })
    ).toEqual({ active: true, module_code: 'OCCTAX', create: 'OCCHAB' });
  });

  it('does not mutate the given params', () => {
    const params = { id_acquisition_frameworks: [1] };
    buildDatasetsParams({ displayOnlyActive: true }, params);
    expect(params).toEqual({ id_acquisition_frameworks: [1] });
  });
});
