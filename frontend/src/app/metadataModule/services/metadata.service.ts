import { Injectable } from '@angular/core';
import { UntypedFormGroup, UntypedFormBuilder, UntypedFormControl } from '@angular/forms';
import { NgbDateParserFormatter } from '@ng-bootstrap/ng-bootstrap';
import { BehaviorSubject, of } from 'rxjs';
import { tap, catchError } from 'rxjs/operators';

import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { DataFormService, ParamsDict } from '@geonature_common/form/data-form.service';
import { ConfigService } from '@geonature/services/config.service';
import { PageEvent } from '@angular/material/paginator';
import { valueOrDefault } from 'chart.js/helpers';
import { FormService } from '@geonature_common/form/form.service';

// Filters applying to the datasets or to the AF itself, depending on the selector
const ENTITY_CRITERIA = ['uuid', 'name', 'date', 'organism', 'person'];

export type MetadataSelector = 'ds' | 'af';

/** A filter of the advanced form, displayed as a pill once applied. */
export interface MetadataFilterPill {
  key: string;
  label: string;
}

/**
 * The quick search (`term`, full text on the metadata) and the filters (precise criteria) are
 * combined: results must match both.
 */
export interface MetadataSearch {
  term: string | null;
  selector: MetadataSelector;
  /** API values of the filters, by criterion (`areas` holds a list of area ids). */
  criteria: { [key: string]: any };
  pills: MetadataFilterPill[];
}

@Injectable()
export class MetadataService {
  public form: UntypedFormGroup;

  /* données receptionnées par l'API */
  public acquisitionFrameworks: BehaviorSubject<any[]> = new BehaviorSubject([]);

  /* resultat du filtre sur _acquisitionFrameworks */
  public isLoading: boolean = false;
  public expandAccordions: boolean = false;

  public formBuilded = false;
  public activeSearch: MetadataSearch = this.emptySearch();

  pageSizeOptions: number[] = [10, 25, 50, 100];
  pageSize: BehaviorSubject<number> = null;
  pageIndex: BehaviorSubject<number> = new BehaviorSubject(0);
  public totalItems: BehaviorSubject<number> = new BehaviorSubject(0);
  public totalPages: BehaviorSubject<number> = new BehaviorSubject(0);
  public currentPage: BehaviorSubject<number> = new BehaviorSubject(1);

  constructor(
    private _fb: UntypedFormBuilder,
    private dataFormService: DataFormService,
    public config: ConfigService,
    private _formService: FormService
  ) {
    this.pageSize = new BehaviorSubject(this.config.METADATA.NB_AF_DISPLAYED);

    this.form = this._fb.group({
      selector: 'ds',
      uuid: [null, _formService.uuidValidator()],
      name: null,
      date: null,
      organism: null,
      person: null,
      areas: [],
    });

    this.config.METADATA.METADATA_AREA_FILTERS.forEach((area) => {
      let control_name: string;
      if (typeof area['type_code'] === 'string') {
        control_name = 'area_' + area['type_code'].toLowerCase();
      } else if (Array.isArray(area['type_code'])) {
        control_name =
          'area_' + area['type_code'].map((code: string) => code.toLowerCase()).join('_');
      }
      this.form.addControl(control_name, new UntypedFormControl(new Array()));
      const control = this.form.controls[control_name];
      area['control'] = control;
    });
    this.formBuilded = true;
  }

  private emptySearch(): MetadataSearch {
    return { term: null, selector: 'ds', criteria: {}, pills: [] };
  }

  /** Filters currently applied to the results, to display as pills. */
  get filterPills(): MetadataFilterPill[] {
    return this.activeSearch.pills;
  }

  /** Quick search: the filters stay applied. */
  setQuickTerm(term: string | null) {
    this.activeSearch.term = term || null;
  }

  /** Apply the filters of the advanced form: the quick search stays applied. */
  setFilters(
    selector: MetadataSelector,
    criteria: { [key: string]: any },
    pills: MetadataFilterPill[]
  ) {
    this.activeSearch = { ...this.activeSearch, selector, criteria, pills };
  }

  /** Stop applying one filter, and empty the matching field of the advanced form. */
  removeFilter(key: string) {
    const { [key]: _removed, ...criteria } = this.activeSearch.criteria;
    this.activeSearch = {
      ...this.activeSearch,
      criteria,
      pills: this.activeSearch.pills.filter((pill) => pill.key !== key),
    };
    if (key === 'areas') {
      this.areaControls().forEach((control) => control.reset([]));
    } else {
      this.form.get(key)?.reset();
    }
  }

  /** Remove the quick search and every filter. */
  clearSearch() {
    this.resetForm();
    this.activeSearch = this.emptySearch();
  }

  private areaControls(): UntypedFormControl[] {
    return Object.keys(this.form.controls)
      .filter((key) => key.startsWith('area_'))
      .map((key) => this.form.get(key) as UntypedFormControl);
  }

  /**
   * Search acquisition frameworks according to the quick search and the filters (all of them if
   * none). The results are emitted through the acquisitionFrameworks observable.
   * The total number of items and the total number of pages are also updated.
   * @returns An observable emitting the search results.
   */
  search() {
    return this.getMetadataObservable(this.buildSearchParams()).pipe(
      tap((response) => {
        this.acquisitionFrameworks.next(response.items);
        this.totalItems.next(response.total);
        this.totalPages.next(response.total_pages);
        this.pageSize.next(response.per_page);
        this.changePage(0);
      })
    );
  }

  /**
   * Build the AF API payload: filters are nested under `datasets` when they apply to the
   * datasets, and flat when they apply to the AF. The quick search term is always flat.
   */
  private buildSearchParams(): { [key: string]: any } {
    const { term, selector, criteria } = this.activeSearch;
    const { areas, ...entityCriteria } = criteria;
    const params: { [key: string]: any } = {
      ...(term && { search: term }),
      ...(areas && { areas }),
    };
    if (selector !== 'ds') {
      return { ...params, ...entityCriteria };
    }
    const datasets = {};
    ENTITY_CRITERIA.forEach((key) => {
      if (key in entityCriteria) {
        datasets[key] = entityCriteria[key];
      }
    });
    return Object.keys(datasets).length ? { ...params, datasets } : params;
  }

  /** Payload to list the datasets of an AF, consistent with the quick search and the filters. */
  datasetSearchParams(): { [key: string]: any } {
    const { term, selector, criteria } = this.activeSearch;
    return {
      ...(term && { search: term }),
      ...(selector === 'ds' && criteria),
    };
  }

  changePage(page_index: number, page_size: number = this.pageSize.value) {
    this.currentPage.next(page_index + 1);
    this.pageSize.next(page_size);
    this.pageIndex.next(page_index);
  }

  changePageEvent(pageEvent: PageEvent) {
    this.changePage(pageEvent.pageIndex, pageEvent.pageSize);
    this.search().subscribe(() => {
      return;
    });
  }

  //recuperation cadres d'acquisition
  getMetadataObservable(params = {}) {
    this.isLoading = true;
    this.acquisitionFrameworks.next([]);
    return this.dataFormService
      .getAcquisitionFrameworksList({}, params, this.currentPage.value, this.pageSize.value)
      .pipe(
        catchError(() =>
          of({
            items: [],
            total: 0,
            page: 1,
            per_page: this.pageSize.value,
            total_pages: 0,
          })
        ),
        tap(() => (this.isLoading = false))
      );
  }

  getMetadata(params = {}) {
    this.getMetadataObservable(params).subscribe(
      (response) => this.acquisitionFrameworks.next(response.items),
      (err) => (this.isLoading = false)
    );
  }

  addDatasetToAcquisitionFramework(af, params, queryString: ParamsDict = {}) {
    //TODO: keep in mind that acquisistionframeworks is
    // a behaviour subject and so filter it with rxjs and
    // pipe the getDatasets then subscribe at the end
    this.dataFormService
      .getDatasets(
        {
          id_acquisition_frameworks: [af.id_acquisition_framework],
          ...params,
        },
        queryString
      )
      .subscribe((datasets) => {
        af.t_datasets = datasets;
        for (const dataset of af.t_datasets) {
          this.dataFormService
            .getDatasetStats(dataset.id_dataset)
            .subscribe((stats) => (dataset.dict_stats = stats));
        }
      });
  }

  private resetForm() {
    this.form.reset();
    this.form.patchValue({ selector: 'ds' });
    this.expandAccordions = false;
  }
}
