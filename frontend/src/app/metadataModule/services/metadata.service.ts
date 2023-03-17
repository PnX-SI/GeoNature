import { Injectable } from '@angular/core';
import { UntypedFormGroup, UntypedFormBuilder, UntypedFormControl } from '@angular/forms';
import { NgbDateParserFormatter } from '@ng-bootstrap/ng-bootstrap';
import { BehaviorSubject } from 'rxjs';
import { tap } from 'rxjs/operators';

import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { ConfigService } from '@geonature/services/config.service';

type DataSetObsCount = {
  count: number;
  id_dataset: number;
};

const SELECTORS = { datasets: 0, creator: 1, actors: 1 };

@Injectable()
export class MetadataService {
  public form: UntypedFormGroup;

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

    this.config.METADATA.METADATA_AREA_FILTERS.forEach((area) => {
      const control_name = 'area_' + area['type_code'].toLowerCase();
      this.form.addControl(control_name, new UntypedFormControl(new Array()));
      const control = this.form.controls[control_name];
      area['control'] = control;
    });
    this.formBuilded = true;
  }

  // FIXME: remove any!!!
  search(formValue: any) {
    return this.getMetadataObservable(formValue).subscribe(
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
    return this.dataFormService
      .getAcquisitionFrameworksList(selectors, params)
      .pipe(tap(() => (this.isLoading = false)));
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
