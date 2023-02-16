import { Injectable } from '@angular/core';
import { UntypedFormGroup, UntypedFormBuilder, UntypedFormControl } from '@angular/forms';
import { NgbDateParserFormatter } from '@ng-bootstrap/ng-bootstrap';
import { forkJoin, BehaviorSubject } from 'rxjs';
import { tap, map, distinctUntilChanged, debounceTime } from 'rxjs/operators';

import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { ConfigService } from '@geonature/services/config.service';

type DataSetObsCount = {
  count: number;
  id_dataset: number;
};

const SELECTORS = { datasets: false, creator: 1, actors: 1 };

@Injectable()
export class MetadataService {
  public form: UntypedFormGroup;
  public rapidSearchControl: UntypedFormControl = new UntypedFormControl();

  /* données receptionnées par l'API */
  public acquisitionFrameworks: BehaviorSubject<any[]> = new BehaviorSubject([]);

  /* resultat du filtre sur _acquisitionFrameworks */
  public isLoading: boolean = false;
  public expandAccordions: boolean = false;

  public formBuilded = false;

  private _datasetNbObs: DataSetObsCount[] = [];

  pageSizeOptions: number[] = [10, 25, 50, 100];
  pageSize: BehaviorSubject<number> = null;
  pageIndex: BehaviorSubject<number> = new BehaviorSubject(0);
  activePage: BehaviorSubject<number> = new BehaviorSubject(0);

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

    this.getMetadata();

    // rapid search event
    //combinaison de la zone de recherche et du chargement des données
    this.rapidSearchControl.valueChanges
      .pipe(debounceTime(1000), distinctUntilChanged())
      .subscribe((term) => {
        if (term !== null) {
          this.search(term);
          this.pageIndex.next(0);
        }
      });
    this.config.METADATA.METADATA_AREA_FILTERS.forEach((area) => {
      const control_name = 'area_' + area['type_code'].toLowerCase();
      this.form.addControl(control_name, new UntypedFormControl(new Array()));
      const control = this.form.controls[control_name];
      area['control'] = control;
    });
    this.formBuilded = true;
  }

  search(term: string) {
    //Add advanced search query strings here but omit the selector since
    // quick search must return AF and DS
    const { selector, ...formValue } = this.formatFormValue({ ...this.form.value });
    const params = {
      ...(term !== '' ? { search: term } : {}),
      // formValue will always has selector as a non null property: need to
      // filter out when only selector is null
      ...formValue,
    };
    return this.getMetadataObservable(params).subscribe(
      (afs) => {
        this.acquisitionFrameworks.next(afs);
      },
      (err) => (this.isLoading = false)
    );
  }
  //recuperation cadres d'acquisition
  getMetadataObservable(params = {}, selectors = SELECTORS) {
    this.isLoading = true;
    this.acquisitionFrameworks.next([]);

    //forkJoin pour lancer les 2 requetes simultanément
    return forkJoin({
      afs: this.dataFormService.getAcquisitionFrameworksList(selectors, params),
      datasetNbObs: this._syntheseDataService.getObsCountByColumn('id_dataset'),
    }).pipe(
      tap(() => (this.isLoading = false)),
      map((val) => {
        this._datasetNbObs = val.datasetNbObs;
        return val.afs;
      })
    );
  }

  getMetadata(params = {}, selectors = SELECTORS) {
    this.getMetadataObservable(params, selectors).subscribe(
      (afs) => this.acquisitionFrameworks.next(afs),
      (err) => (this.isLoading = false)
    );
  }

  addDatasetToAcquisitionFramework(af, params) {
    //TODO: keep in mind that acquisistionframeworks is
    // a behaviour subject and so filter it with rxjs and
    // pipe the getDatasets then subscribe at the end
    this.dataFormService
      .getDatasets({
        id_acquisition_frameworks: [af.id_acquisition_framework],
        ...params,
      })
      .subscribe((datasets) => {
        af.t_datasets = datasets;
        this.setDsObservationCount(datasets, this._datasetNbObs);
      });
  }

  private setDsObservationCount(datasets, dsNbObs) {
    datasets.forEach((ds) => {
      let idx = dsNbObs.findIndex((e) => e.id_dataset == ds.id_dataset);
      ds.observation_count = idx > -1 ? dsNbObs[idx]['count'] : 0;
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
