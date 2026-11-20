import { SearchFilter } from '@geonature_common/form/synthese-form/confirmation-modal/confirmation-modal.component';

export type SearchParams = Record<string, unknown>;

export interface FilterToRestore {
  field: string;
  values: readonly unknown[] | null;
  confirmOnAbsence: boolean | null;
}

export type TaxonRef = number | string;

export interface Digitiser {
  id_role: number;
  nom_complet?: string;
}

const SCALAR_DATE_FILTERS = new Set(['date_min', 'date_max', 'period_start', 'period_end']);

export function restoreSearchParams(
  params: SearchParams,
  filters: readonly FilterToRestore[]
): SearchParams {
  const restoredParams = { ...params };

  filters.forEach((filter) => {
    const values = filter.values || [];
    const currentValue = restoredParams[filter.field];

    if (filter.confirmOnAbsence) {
      if (Array.isArray(currentValue)) {
        restoredParams[filter.field] = [...currentValue, ...values];
      } else if (SCALAR_DATE_FILTERS.has(filter.field)) {
        restoredParams[filter.field] = values[0] ?? null;
      } else {
        restoredParams[filter.field] = values;
      }
      return;
    }

    if (Array.isArray(currentValue)) {
      const remainingValues = currentValue.filter((value) => !values.includes(value));
      if (remainingValues.length > 0) {
        restoredParams[filter.field] = remainingValues;
      } else {
        delete restoredParams[filter.field];
      }
    } else {
      delete restoredParams[filter.field];
    }
  });

  return restoredParams;
}

export function getTaxonRefs(value: unknown): TaxonRef[] {
  const refs = Array.isArray(value) ? value : value == null ? [] : [value];
  return refs.map((ref) => {
    if (typeof ref !== 'number' && typeof ref !== 'string') {
      throw new Error(`Invalid taxon reference: ${String(ref)}`);
    }
    return ref;
  });
}

export function hasValueToConfirm(filter: SearchFilter, value: unknown): boolean {
  if (typeof filter.field !== 'string' || filter.field.length === 0) {
    console.warn(`Empty field value in SYNTHESE.CONFIRM_SEARCH_FILTERS: ${JSON.stringify(filter)}`);
    return false;
  }
  const configuredValues = Array.isArray(filter.values) ? filter.values : [];
  const selectedValues = (Array.isArray(value) ? value : value == null ? [] : [value]).filter(
    (item) => item != null && !(typeof item === 'string' && item.trim() === '')
  );

  // Without specific trigger values, confirm when this filter has a value when confirmOnAbsence.
  // And confirm when no value is selected when confirmOnAbsence is true
  if (configuredValues.length === 0) {
    return filter.confirmOnAbsence ? selectedValues.length === 0 : selectedValues.length > 0;
  }

  const isIntersected = selectedValues.some((item) => configuredValues.includes(item));
  return filter.confirmOnAbsence ? !isIntersected : isIntersected;
}
