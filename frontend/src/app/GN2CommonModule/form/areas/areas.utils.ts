import { Area } from '../../interfaces';

/**
 * Ajouter entre parenthèse le numéro du département si le premier objet
 * est de type commune (=COM).
 * @param data Liste d'objets contenant des infos sur des zones géographiques.
 */
export function formatAreas(data: Area[]): Area[] {
  if (data.length > 0 && data[0].area_type?.type_code === 'COM') {
    return data.map((element) => {
      element.area_name = `${element.area_name} (${element.area_code.substring(0, 2)}) `;
      return element;
    });
  }
  return data;
}

/**
 * Merge the areas from the API with the default items (update mode), without duplicates.
 * Default items are appended at the end.
 */
export function mergeDefaultItems(items: Array<any>, defaultItems: Array<any>, key: string) {
  if (!defaultItems || defaultItems.length === 0) {
    return items;
  }
  const filteredItems = items.filter(
    (area) => !defaultItems.some((defaultArea) => defaultArea[key] === area[key])
  );
  return filteredItems.concat(defaultItems);
}
