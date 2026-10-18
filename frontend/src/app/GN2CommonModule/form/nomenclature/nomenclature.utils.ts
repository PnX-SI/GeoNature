/**
 * Return the ``cd_nomenclature`` of the item whose ``id_nomenclature`` is ``id``.
 * ``undefined`` if items are not loaded yet, ``null`` if no item matches.
 */
export function findCdNomenclature(
  items: Array<any> | undefined,
  id: number
): string | null | undefined {
  if (!items) {
    return undefined;
  }
  const item = items.find((item) => item.id_nomenclature === id);
  return item ? item.cd_nomenclature : null;
}

/** Name of the attribute holding the label (or the definition) in the current language */
export function langKey(prefix: 'label' | 'definition', lang: string): string {
  return `${prefix}_${lang}`;
}
