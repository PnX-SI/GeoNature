/**
 * Reach the list in an API response when it is not at the root.
 * @param dataPath path separated by slashes, ex: ``data/liste``
 */
export function extractByPath(data: any, dataPath?: string): any {
  if (!dataPath) {
    return data;
  }
  let values = data;
  for (const path of dataPath.split('/')) {
    values = values[path];
  }
  return values;
}

/** Turn a list of raw values (ex: strings) into a list of ``{label, value}`` objects */
export function normalizeValues(data: Array<any> | null | undefined): Array<any> {
  return data ? data.map((v) => (typeof v !== 'object' ? { label: v, value: v } : v)) : [];
}
