import { findCdNomenclature, langKey } from './nomenclature.utils';

describe('findCdNomenclature', () => {
  const items = [
    { id_nomenclature: 1, cd_nomenclature: 'A' },
    { id_nomenclature: 2, cd_nomenclature: 'B' },
  ];

  it('returns the code of the matching item', () => {
    expect(findCdNomenclature(items, 2)).toBe('B');
  });

  it('returns null when no item matches', () => {
    expect(findCdNomenclature(items, 3)).toBeNull();
    expect(findCdNomenclature(items, null)).toBeNull();
  });

  it('returns undefined when items are not loaded', () => {
    expect(findCdNomenclature(undefined, 1)).toBeUndefined();
  });
});

describe('langKey', () => {
  it('builds the attribute name for a language', () => {
    expect(langKey('label', 'fr')).toBe('label_fr');
    expect(langKey('definition', 'en')).toBe('definition_en');
  });
});
