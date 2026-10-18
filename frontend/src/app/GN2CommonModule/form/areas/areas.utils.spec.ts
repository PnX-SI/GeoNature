import { formatAreas, mergeDefaultItems } from './areas.utils';

describe('formatAreas', () => {
  it('appends the department number to the name of municipalities', () => {
    const data = [{ area_type: { type_code: 'COM' }, area_name: 'Paris', area_code: '75056' }];
    expect(formatAreas(data)[0]['area_name']).toBe('Paris (75) ');
  });

  it('leaves other area types untouched', () => {
    const data = [{ area_type: { type_code: 'DEP' }, area_name: 'Paris', area_code: '75' }];
    expect(formatAreas(data)[0]['area_name']).toBe('Paris');
  });

  it('accepts an empty list', () => {
    expect(formatAreas([])).toEqual([]);
  });
});

describe('mergeDefaultItems', () => {
  const items = [{ id_area: 1 }, { id_area: 2 }];

  it('returns the items when there is no default item', () => {
    expect(mergeDefaultItems(items, [], 'id_area')).toBe(items);
    expect(mergeDefaultItems(items, undefined, 'id_area')).toBe(items);
  });

  it('appends default items and removes duplicates', () => {
    expect(
      mergeDefaultItems(items, [{ id_area: 2, area_name: 'x' }, { id_area: 3 }], 'id_area')
    ).toEqual([{ id_area: 1 }, { id_area: 2, area_name: 'x' }, { id_area: 3 }]);
  });
});
