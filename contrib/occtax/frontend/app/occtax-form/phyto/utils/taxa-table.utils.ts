import { Counting, Occurrence } from './interfaces';

export interface StratumAbundance {
  label: string;
  id: number;
}

export function getStratumAbundance(
  occurrence: Pick<Occurrence, 'cor_counting_occtax'>,
  stratumId: number,
  abundanceNomenclatures: ReadonlyMap<number, { cd_nomenclature?: string | null }>
): StratumAbundance {
  const abundanceIds = (occurrence.cor_counting_occtax || [])
    .filter(
      (counting: Counting) =>
        counting.id_nomenclature_vegetation_stratum === stratumId &&
        counting.id_nomenclature_phytosociological_abundance != null
    )
    .map((counting) => counting.id_nomenclature_phytosociological_abundance);

  const text = abundanceIds
    .map((id) => abundanceNomenclatures.get(id)?.cd_nomenclature)
    .filter((code): code is string => !!code)
    .join(', ');

  return {
    label: text,
    id: abundanceIds.length === 1 ? abundanceIds[0] : -1,
  };
}

export function compareValues<T extends string | number>(
  a: T,
  b: T,
  isAscending: boolean
): number {
  const comparison = a === b ? 0 : a < b ? -1 : 1;
  return isAscending ? comparison : -comparison;
}
