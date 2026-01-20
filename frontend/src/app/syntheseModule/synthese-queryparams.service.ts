import { Injectable } from '@angular/core';
import { ParamMap } from '@angular/router';
import { Observable, forkJoin, of } from 'rxjs';
import { catchError, map } from 'rxjs/operators';

import { DataFormService } from '@geonature_common/form/data-form.service';
import { SyntheseFormService } from '@geonature_common/form/synthese-form/synthese-form.service';
import { Taxon } from '@geonature_common/form/taxonomy/taxonomy.component';

@Injectable()
export class SyntheseQueryParamsService {
  constructor(
    private _formService: SyntheseFormService,
    private _dataFormService: DataFormService
  ) {}

  processQueryParamsFilters(params: ParamMap): Record<string, any> {
    const processedFilters: Record<string, any> = {};
    // Apply query params for advanced fields that are not part of the base form
    const advancedKeys = new Set(
      this._formService.dynamycFormDef.map((formDef) => formDef.attribut_name)
    );

    for (const key of params.keys) {
      const isStandardFilter = this._formService.searchForm.contains(key);
      const isAdvancedFilter = advancedKeys.has(key);
      if (!isStandardFilter && !isAdvancedFilter) {
        continue;
      }
      const values = params.getAll(key).filter((value) => value !== null && value !== '');
      if (!values.length) {
        continue;
      }
      processedFilters[key] = this._parseQueryParamValue(key, values);
    }
    return processedFilters;
  }

  getCdRefsFromQueryParams(params: ParamMap): Array<number> {
    const cdRefs = params
      .getAll('cd_ref')
      .map((value) => Number(value))
      .filter((value) => !isNaN(value));
    return Array.from(new Set(cdRefs));
  }

  getTaxonsFromQueryParams(params: ParamMap): {
    cdRefs: Array<number>;
    taxons$: Observable<Array<Taxon>>;
  } {
    const cdRefs = this.getCdRefsFromQueryParams(params);
    if (!cdRefs.length) {
      return { cdRefs: [], taxons$: of([] as Array<Taxon>) };
    }

    const taxons$ = forkJoin(
      cdRefs.map((cdRef) =>
        this._dataFormService.getTaxonInfo(cdRef).pipe(catchError(() => of(null)))
      )
    ).pipe(
      map((taxons) =>
        taxons.filter(Boolean).map((taxon: Taxon) => ({
          ...taxon,
          nom_valide: taxon.nom_valide ?? taxon.lb_nom,
        }))
      )
    );

    return { cdRefs, taxons$ };
  }

  applyQueryParamsTaxons(
    params: ParamMap,
    onTaxons: (taxons: Array<Taxon>, cdRefs: Array<number>) => void
  ) {
    const { cdRefs, taxons$ } = this.getTaxonsFromQueryParams(params);
    if (!cdRefs.length) {
      return;
    }

    taxons$.subscribe((taxons) => onTaxons(taxons, cdRefs));
  }

  buildQueryParams(formParams: Record<string, any>) {
    // Normalize form values before router serialization (skip empty/unsupported values).
    const queryParams: Record<
      string,
      string | number | boolean | Array<string | number | boolean>
    > = {};

    Object.entries(formParams).forEach(([key, value]) => {
      if (value === null || value === undefined || value === '') {
        return;
      }

      if (Array.isArray(value)) {
        // Keep only primitives so the router can expand arrays into repeated query params.
        const sanitizedValues = value.filter((entry) => this._isQueryParamPrimitive(entry));
        if (sanitizedValues.length) {
          queryParams[key] = sanitizedValues;
        }
        return;
      }

      if (this._isQueryParamPrimitive(value)) {
        queryParams[key] = value;
      }
    });

    return queryParams;
  }

  private _parseQueryParamValue(key: string, values: Array<string>) {
    if (['date_min', 'date_max'].includes(key)) {
      return this._formService.parseDateParam(values[0]);
    }

    if (['period_start', 'period_end'].includes(key)) {
      return this._formService.parsePeriodParam(values[0]);
    }

    if (this._isMultiValueKey(key, values)) {
      return values.map((value) => this._coerceParamValue(value));
    }

    return this._coerceParamValue(values[0]);
  }

  private _isMultiValueKey(key: string, values: Array<string>) {
    if (values.length > 1) {
      return true;
    }

    if (key.startsWith('id_nomenclature_') || key.startsWith('area_')) {
      return true;
    }

    if (['id_acquisition_framework', 'id_dataset', 'id_organism', 'observers_list'].includes(key)) {
      return true;
    }

    if (this._formService.statusFilters.some((status) => status.control_name === key)) {
      return true;
    }

    if (this._formService.redListsFilters.some((redList) => redList.control_name === key)) {
      return true;
    }

    return false;
  }

  private _coerceParamValue(value: string) {
    const trimmedValue = value.trim();
    if (trimmedValue === 'true') {
      return true;
    }
    if (trimmedValue === 'false') {
      return false;
    }

    const numericValue = Number(trimmedValue);
    if (!Number.isNaN(numericValue) && trimmedValue !== '') {
      return numericValue;
    }

    return trimmedValue;
  }

  private _isQueryParamPrimitive(value: unknown): value is string | number | boolean {
    return typeof value === 'string' || typeof value === 'number' || typeof value === 'boolean';
  }
}
