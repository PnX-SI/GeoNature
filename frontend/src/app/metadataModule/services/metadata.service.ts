import { Injectable } from '@angular/core';
import { FormGroup, FormBuilder, FormControl } from '@angular/forms';
import { NgbDateParserFormatter } from '@ng-bootstrap/ng-bootstrap';
import { forkJoin, Observable, BehaviorSubject, combineLatest } from 'rxjs';
import {
  tap,
  map,
  startWith,
  distinctUntilChanged,
  debounceTime,
  filter,
  pairwise,
} from 'rxjs/operators';
import { forkJoin, Observable, BehaviorSubject } from 'rxjs';
import { tap, map, distinctUntilChanged, debounceTime } from 'rxjs/operators';
import { PageEvent, MatPaginator } from '@angular/material/paginator';

import { AppConfig } from '@geonature_config/app.config';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { DataFormService } from '@geonature_common/form/data-form.service';

@Injectable()
export class MetadataService {
  public form: FormGroup;
  public rapidSearchControl: FormControl = new FormControl();

  /* données receptionnées par l'API */
  private _acquisitionFrameworks: BehaviorSubject<any[]> = new BehaviorSubject([]);
  /* getter this._acquisitionFrameworks */
  get acquisitionFrameworks() {
    return this._acquisitionFrameworks.getValue();
  }

  /* resultat du filtre sur _acquisitionFrameworks */
  public filteredAcquisitionFrameworks: Observable<any[]>;
  public isLoading: boolean = false;
  public expandAccordions: boolean = false;

  public formBuilded = false;

  pageSizeOptions: number[] = [10, 25, 50, 100];
  pageSize: BehaviorSubject<number> = new BehaviorSubject(AppConfig.METADATA.NB_AF_DISPLAYED);
  pageIndex: BehaviorSubject<number> = new BehaviorSubject(0);
  activePage: BehaviorSubject<number> = new BehaviorSubject(0);

  constructor(
    private _fb: FormBuilder,
    public dateParser: NgbDateParserFormatter,
    private dataFormService: DataFormService,
    private _syntheseDataService: SyntheseDataService
  ) {
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
    this.filteredAcquisitionFrameworks = this._acquisitionFrameworks.asObservable();
    this.rapidSearchControl.valueChanges
      .pipe(debounceTime(1000), distinctUntilChanged())
      .subscribe((term) => {
        if (term !== null) {
          this.search(term);
          this.pageIndex.next(0);
        }
      });
  }

  search(term: string) {
    //TODO: add advanced search query strings here
    const formValue = this.formatFormValue(Object.assign({}, this.form.value));
    const params = {
      ...(term !== '' ? { search: term } : {}),
      ...APIPARAMS,
      // formValue will always has selector as a non null property: need to
      // filter out when only selector is null
      ...(Object.keys(formValue).length > 1 ? formValue : {}),
    };

    return this.getMetadataObservable(params)
      .pipe(
        map((afs: any[]): any[] =>
          term === '' ? afs : this._filterAcquisitionFrameworks(afs, term)
        ),
        tap(() => {
          this.expandAccordions = term !== '';
        })
      )
      .subscribe(
        (afs) => {
          this._acquisitionFrameworks.next(afs);
        },
        (err) => (this.isLoading = false)
      );
  }
  //recuperation cadres d'acquisition
  getMetadata(params = {}, selectors = { datasets: 1, creator: 1, actors: 1 }) {
    this.isLoading = true;
    this._acquisitionFrameworks.next([]);

    //forkJoin pour lancer les 2 requetes simultanément
    return forkJoin({
      afs: this.dataFormService.getAcquisitionFrameworksList(apiParams),
      datasetNbObs: this._syntheseDataService.getObsCountByColumn('id_dataset'),
    }).pipe(
      tap(() => (this.isLoading = false)),
      map((val) => {
        //val: {afs: CA[], datasetNbObs: {id_dataset: number, count: number}[]}
        //boucle sur les CA pour attribuer le nombre de données au JDD et création de la clé datasetsTemp
        for (let i = 0; i < val.afs.length; i++) {
          this.setDsObservationCount(val.afs[i]['t_datasets'], val.datasetNbObs);
        }
        //renvoie uniquement les CA
        return val.afs;
      })
    );
  }

  getMetadata(params = {}) {
    this.getMetadataObservable(params).subscribe(
      (afs) => this._acquisitionFrameworks.next(afs),
      (err) => (this.isLoading = false)
    );
  }

  /**
   *  Filtre les éléments CA et JDD selon la valeur de la barre de recherche
   **/
  private _filterAcquisitionFrameworks(afs, filterValue) {
    return afs.filter((af) => {
      if (filterValue.includes(af.acquisition_framework_name)) {
        return true;
      }
      //on filtre les JDD qui matchent eventuellement.
      if (af.t_datasets) {
        const tempDatasets = af.t_datasets.filter((ds) => {
          return (
            ds.id_dataset == filterValue ||
            this._removeAccentAndLower(ds.dataset_name).includes(filterValue) ||
            this._removeAccentAndLower(ds.unique_dataset_id) == filterValue ||
            this._removeAccentAndLower(ds.meta_create_date) == filterValue
          );
        });
        if (tempDatasets.length !== 0) {
          af.t_datasets = tempDatasets;
        }
        return af.datasets.length; //On envoie ce test pour garder le CA si un JDD a matché
      }
      return false;
    });
  }

  private setDsObservationCount(datasets, dsNbObs) {
    datasets.forEach((ds) => {
      let idx = dsNbObs.findIndex((e) => e.id_dataset == ds.id_dataset);
      ds.observation_count = idx > -1 ? dsNbObs[idx]['count'] : 0;
    });
  }

  private _removeAccentAndLower(value): string {
    return String(value)
      .toLocaleLowerCase()
      .trim()
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '');
  }

  formatFormValue(formValue) {
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
