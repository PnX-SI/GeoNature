import { Injectable } from '@angular/core';
import { UntypedFormGroup, UntypedFormBuilder, UntypedFormControl } from '@angular/forms';
import { NgbDateParserFormatter } from '@ng-bootstrap/ng-bootstrap';
import { BehaviorSubject, of } from 'rxjs';
import { tap, catchError } from 'rxjs/operators';

import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { DataFormService, ParamsDict } from '@geonature_common/form/data-form.service';
import { ConfigService } from '@geonature/services/config.service';
import { PageEvent } from '@angular/material/paginator';

const SELECTORS = { datasets: 0, creator: 1, actors: 1 };

interface MetadataSearchForm {
  selector?: string;
  uuid?: string | null;
  name?: string | null;
  date?: string | null;
  organism?: string | null;
  person?: string | null;
  [key: `area_${string}`]: Array<any>;
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

  pageSizeOptions: number[] = [10, 25, 50, 100];
  pageSize: BehaviorSubject<number> = null;
  pageIndex: BehaviorSubject<number> = new BehaviorSubject(0);
  public totalItems: number = 0;
  public totalPages: number = 0;
  public currentPage: number = 1;

  constructor(
    private _fb: UntypedFormBuilder,
    public dateParser: NgbDateParserFormatter,
    private dataFormService: DataFormService,
    private _syntheseDataService: SyntheseDataService,
    public config: ConfigService
  ) {
    this.pageSize = new BehaviorSubject(this.config.METADATA.NB_AF_DISPLAYED);

    this.form = this._fb.group({
      selector: 'ds',
      uuid: null,
      name: null,
      date: null,
      organism: null,
      person: null,
    });

    this.config.METADATA.METADATA_AREA_FILTERS.forEach((area) => {
      const control_name = 'area_' + area['type_code'].toLowerCase();
      this.form.addControl(control_name, new UntypedFormControl(new Array()));
      const control = this.form.controls[control_name];
      area['control'] = control;
    });
    this.formBuilded = true;
  }

  search(formValue: MetadataSearchForm) {
    return this.getMetadataObservable(formValue).pipe(
      tap((response) => {
        this.acquisitionFrameworks.next(response.items);
        this.totalItems = response.total;
        this.totalPages = response.total_pages;
        this.currentPage = response.page;
      })
    );
  }

  changePage(page_index: number, page_size: number = this.pageSize.value) {
    this.currentPage = page_index;
    this.pageSize.next(page_size);
    this.getMetadata();
  }
  changePageEvent(pageEvent: PageEvent) {
    this.changePage(pageEvent.pageIndex + 1, pageEvent.pageSize);
  }

  //recuperation cadres d'acquisition
  getMetadataObservable(params = {}, selectors = SELECTORS) {
    this.isLoading = true;
    this.acquisitionFrameworks.next([]);
    // TODO changer ici aussi
    //forkJoin pour lancer les 2 requetes simultanément
    return this.dataFormService
      .getAcquisitionFrameworksList(selectors, params, this.currentPage, this.pageSize.value)
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

  getMetadata(params = {}, selectors = SELECTORS) {
    this.getMetadataObservable(params, selectors).subscribe(
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
      });
  }

  formatFormValue(formValue): any {
    const formatedForm = {};
    Object.keys(formValue).forEach((key) => {
      if (key == 'date' && formValue['date']) {
        formatedForm['date'] = this.dateParser.format(formValue['date']);
      } else if (formValue[key]) {
        formatedForm[key] = formValue[key];
      }
    });
    return formatedForm;
  }

  resetForm() {
    this.form.reset();
    this.form.patchValue({ selector: 'ds' });
    this.expandAccordions = false;
  }
}
