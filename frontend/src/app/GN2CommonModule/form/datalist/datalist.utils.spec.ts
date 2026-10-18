import { extractByPath, normalizeValues } from './datalist.utils';

describe('extractByPath', () => {
  it('returns the data when there is no path', () => {
    const data = [1, 2];
    expect(extractByPath(data)).toBe(data);
    expect(extractByPath(data, '')).toBe(data);
  });

  it('follows a path separated by slashes', () => {
    expect(extractByPath({ data: { liste: [1, 2] } }, 'data/liste')).toEqual([1, 2]);
    expect(extractByPath({ data: [3] }, 'data')).toEqual([3]);
  });
});

describe('normalizeValues', () => {
  it('turns raw values into label/value objects and keeps objects', () => {
    expect(normalizeValues(['a', { label: 'B', value: 'b' }])).toEqual([
      { label: 'a', value: 'a' },
      { label: 'B', value: 'b' },
    ]);
  });

  it('returns an empty list without data', () => {
    expect(normalizeValues(undefined)).toEqual([]);
    expect(normalizeValues(null)).toEqual([]);
  });
});
