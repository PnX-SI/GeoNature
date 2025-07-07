import { TaxonStats } from '@geonature_common/form/synthese-form/synthese-data.service';

export interface Indicator {
  name: string;
  matIcon: string;
  value: string | null;
}

type IndicatorRawType = 'number' | 'string' | 'date';
export interface IndicatorDescription {
  name: string;
  matIcon: string;
  field: string | Array<string>;
  unit?: string;
  separator?: string;
  type: IndicatorRawType;
}

const DEFAULT_VALUE = '-';
const DEFAULT_SEPARATOR = '-';

function getValue(field: string, indicatorConfig: IndicatorDescription, stats?: TaxonStats) {
  if (stats && stats[field] != undefined) {
    let valueAsString = '';
    switch (indicatorConfig.type) {
      case 'number':
        valueAsString = stats[field].toLocaleString();
        break;
      case 'date':
        valueAsString = new Date(stats[field]).toLocaleDateString();
        break;
      case 'string':
      default:
        valueAsString = stats[field];
    }
    return valueAsString + (indicatorConfig.unit ?? '');
  }
  return DEFAULT_VALUE;
}

export function computeIndicatorFromDescription(
  indicatorDescription: IndicatorDescription,
  stats: TaxonStats
): Indicator {
  let value = DEFAULT_VALUE;
  if (stats) {
    if (Array.isArray(indicatorDescription.field)) {
      const separator = indicatorDescription.separator ?? DEFAULT_SEPARATOR;
      value = indicatorDescription.field
        .map((field) => getValue(field, indicatorDescription, stats))
        .join(' ' + separator + ' ');
    } else {
      value = getValue(indicatorDescription.field, indicatorDescription, stats);
    }
  }
  return {
    name: indicatorDescription.name,
    matIcon: indicatorDescription.matIcon,
    value: value,
  };
}
