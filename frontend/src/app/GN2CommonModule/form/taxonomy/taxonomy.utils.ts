/** URL of the TaxHub API searching the names of a taxa list (all names without list) */
export function taxonSearchEndPoint(taxhubApi: string, idList?: string | number): string {
  return idList
    ? `${taxhubApi}/taxref/allnamebylist/${idList}`
    : `${taxhubApi}/taxref/allnamebylist`;
}
