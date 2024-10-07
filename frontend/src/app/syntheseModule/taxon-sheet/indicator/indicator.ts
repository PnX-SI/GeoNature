type IndicatorRawType = 'number' | 'string' | 'date';
export interface IndicatorRaw {
  name: string;
  matIcon: string;
  field: string | Array<string>;
  unit?: string;
  type: IndicatorRawType;
}

export interface Indicator {
  name: string;
  matIcon: string;
  value: string | null;
}

type Stats = Record<string, string>;

const DEFAULT_VALUE = '-';
const DEFAULT_SEPARATOR = '-';

function getValue(field: string, indicatorConfig: IndicatorRaw, stats?: Stats) {
  if (stats && stats[field]) {
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

export function computeIndicatorFromConfig(
  indicatorConfig: IndicatorRaw,
  stats?: Stats
): Indicator {
  let value = DEFAULT_VALUE;
  if (stats) {
    if (Array.isArray(indicatorConfig.field)) {
      const separator = indicatorConfig['separator'] ?? DEFAULT_SEPARATOR;
      value = indicatorConfig.field
        .map((field) => getValue(field, indicatorConfig, stats))
        .join(' ' + separator + ' ');
    } else {
      value = getValue(indicatorConfig.field, indicatorConfig, stats);
    }
  }
  return {
    name: indicatorConfig.name,
    matIcon: indicatorConfig.matIcon,
    value: value,
  };
}
