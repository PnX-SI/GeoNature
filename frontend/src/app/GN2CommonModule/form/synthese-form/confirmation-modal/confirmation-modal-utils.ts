type SearchParams = Record<string, unknown>;

export interface SearchFilter {
  field: string;
  message: string | null;
  confirmOnAbsence: boolean | null;
  values: unknown[] | null;
}

const UNSUPPORTED_FIELDS = new Set([
  'cd_ref',
  'cd_ref_parent',
  'date_min',
  'date_max',
  'period_start',
  'period_end',
]);

export function isParamToConfirm(param: unknown, configuredFilter: SearchFilter): boolean {
  if (typeof configuredFilter.field !== 'string' || configuredFilter.field.length === 0) {
    console.warn(
      `Empty field value in SYNTHESE.CONFIRM_SEARCH_FILTERS: ${JSON.stringify(configuredFilter)}`
    );
    return false;
  }

  if (UNSUPPORTED_FIELDS.has(configuredFilter.field)) {
    console.warn(
      `Unsuported field value in SYNTHESE.CONFIRM_SEARCH_FILTERS: ${JSON.stringify(configuredFilter)}`
    );
    return false;
  }

  const configuredValues = Array.isArray(configuredFilter.values) ? configuredFilter.values : [];
  const selectedParams = (Array.isArray(param) ? param : param == null ? [] : [param]).filter(
    (el) => el != null && !(typeof el === 'string' && el.trim() === '')
  );

  if (configuredValues.length === 0) {
    return configuredFilter.confirmOnAbsence
      ? selectedParams.length === 0
      : selectedParams.length > 0;
  }

  const isIntersected = selectedParams.some((el) => configuredValues.includes(el));
  return configuredFilter.confirmOnAbsence ? !isIntersected : isIntersected;
}

export function restoreSearchParams(
  params: SearchParams,
  filtersToConfirm: SearchFilter[]
): SearchParams {
  const restoredParams = { ...params };

  filtersToConfirm.forEach((filter) => {
    const filterValues = filter.values || [];
    const currentRestoredParam = restoredParams[filter.field];

    if (filter.confirmOnAbsence) {
      if (Array.isArray(currentRestoredParam)) {
        restoredParams[filter.field] = [...currentRestoredParam, ...filterValues];
      } else {
        restoredParams[filter.field] = filterValues[0] ?? null;
      }
    } else {
      if (Array.isArray(currentRestoredParam)) {
        if (filterValues.length === 0) {
          delete restoredParams[filter.field];
        } else {
          const filteredParam = currentRestoredParam.filter(
            (param) => !filterValues.includes(param)
          );
          if (filteredParam.length > 0) {
            restoredParams[filter.field] = filteredParam;
          } else {
            delete restoredParams[filter.field];
          }
        }
      } else {
        delete restoredParams[filter.field];
      }
    }
  });
  return restoredParams;
}
