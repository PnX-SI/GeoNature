import { Nomenclature } from '@geonature_common/interfaces';
import { VegetationStratum } from './interfaces';

export interface VegetationStratumRow {
  id: number;
  label: string;
  mnemonique: string;
  stratum: VegetationStratum & { id_nomenclature_vegetation_stratum: number };
}

export function getEligibleVegetationStratumRows(
  strata: VegetationStratum[],
  nomenclatures: Nomenclature[]
): VegetationStratumRow[] {
  const nomenclatureById = new Map(
    nomenclatures.map((nomenclature) => [nomenclature.id_nomenclature, nomenclature])
  );
  const rows: VegetationStratumRow[] = [];

  for (const stratum of strata) {
    if (!hasStratumData(stratum)) {
      continue;
    }

    const id = stratum.id_nomenclature_vegetation_stratum;
    const nomenclature = nomenclatureById.get(id);
    if (!nomenclature?.label_default) {
      continue;
    }

    rows.push({
      id,
      label: nomenclature.label_default,
      mnemonique: nomenclature.mnemonique || '',
      stratum,
    });
  }

  return rows.sort((a, b) => a.id - b.id);
}

function hasStratumData(
  stratum: VegetationStratum
): stratum is VegetationStratum & { id_nomenclature_vegetation_stratum: number } {
  return (
    stratum.id_nomenclature_vegetation_stratum != null &&
    (stratum.percentage_cover_vegetation_stratum != null ||
      stratum.average_height != null ||
      stratum.min_height != null ||
      stratum.max_height != null)
  );
}
