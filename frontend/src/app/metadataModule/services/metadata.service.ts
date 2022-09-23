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
import { PageEvent, MatPaginator } from '@angular/material/paginator';

import { AppConfig } from '@geonature_config/app.config';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { DataFormService } from '@geonature_common/form/data-form.service';

type DataSetObsCount = {
  count: number;
  id_dataset: number;
};

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

  private _datasetNbObs: DataSetObsCount[] = [];

  /* resultat du filtre sur _acquisitionFrameworks */
  public filteredAcquisitionFrameworks: Observable<any[]>;

  public isLoading: boolean = false;
  public expandAccordions: boolean = false;

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
    this.filteredAcquisitionFrameworks = combineLatest(
      this.rapidSearchControl.valueChanges.pipe(
        startWith(''),
        debounceTime(200),
        distinctUntilChanged(),
        map((term) => this._removeAccentAndLower(term))
      ),
      this._acquisitionFrameworks.asObservable()
    ).pipe(
      //hack de reprise de la valeur du rapidSearch si changement de page et retour ici
      map(([term, afs]: [string, any[]]): [string, any[]] => {
        if (this.rapidSearchControl.value !== null && term !== this.rapidSearchControl.value) {
          return [this._removeAccentAndLower(this.rapidSearchControl.value), afs];
        }
        return [term, afs];
      }),
      map(([term, afs]: [string, any[]]): [string, any[]] => {
        //restaure les datasets avant les filtres
        //afs.map((af) => (af['datasetsTemp'] = af['t_datasets']));
        return [term, afs];
      }),
      //filtre des éléments selon le texte, retourne les AF filtrés
      map(([term, afs]: [string, any[]]): any[] =>
        term === '' ? afs : this._filterAcquisitionFrameworks(term)
      )
    );

    //retour à la premiere page du tableau pour voir les résultats du filtre rapide
    this.rapidSearchControl.valueChanges
      .pipe(
        //ouverture ou fermeture de l'accordion selon s'il y a une recherche ou non
        tap((term) => (this.expandAccordions = term !== ''))
      )
      .subscribe(() => this.pageIndex.next(0));
  }

  //recuperation cadres d'acquisition

  getMetadata(params = {}) {
    params['datasets'] = false;
    params['creator'] = 1;
    params['actors'] = 1;
    this.isLoading = true;
    this._acquisitionFrameworks.next([]);

    //forkJoin pour lancer les 2 requetes simultanément
    forkJoin({
      afs: this.dataFormService.getAcquisitionFrameworksList(params),
      datasetNbObs: this._syntheseDataService.getObsCountByColumn('id_dataset'),
    })
      .pipe(
        tap(() => (this.isLoading = false)),
        map((val) => {
          this._datasetNbObs = val.datasetNbObs;
          //val: {afs: CA[], datasetNbObs: {id_dataset: number, count: number}[]}
          //boucle sur les CA pour attribuer le nombre de données au JDD et création de la clé datasetsTemp
          // for (let i = 0; i < val.afs.length; i++) {
          //   this.setDsObservationCount(val.afs[i]['t_datasets'], val.datasetNbObs);
          // }
          //renvoie uniquement les CA
          return val.afs;
        })
      )
      .subscribe(
        (afs) => this._acquisitionFrameworks.next(afs),
        (err) => (this.isLoading = false)
      );
  }

  /**
   *  Filtre les éléments CA et JDD selon la valeur de la barre de recherche
   **/
  private _filterAcquisitionFrameworks(filterValue) {
    return this.acquisitionFrameworks.filter((af) => {
      //recherche des cadres d'acquisition qui matchent
      if (
        af.id_acquisition_framework == filterValue ||
        this._removeAccentAndLower(af.unique_acquisition_framework_id) == filterValue ||
        this._removeAccentAndLower(af.acquisition_framework_name).includes(filterValue) ||
        this._removeAccentAndLower(af.acquisition_framework_start_date) == filterValue
      ) {
        return true;
      }
      //Sinon on filtre les JDD qui matchent eventuellement.
      if (af.t_datasets) {
        af.datasetsTemp = af.t_datasets.filter((ds) => {
          return (
            ds.id_dataset == filterValue ||
            this._removeAccentAndLower(ds.dataset_name).includes(filterValue) ||
            this._removeAccentAndLower(ds.unique_dataset_id) == filterValue ||
            this._removeAccentAndLower(ds.meta_create_date) == filterValue
          );
        });
        return af.datasetsTemp.length; //On envoie ce test pour garder le CA si un JDD a matché
      }
      return false;
    });
  }

  addDatasetToAcquisitionFramework(id_af: number) {
    // current_af is either the af corresponding to id_af
    // or undefined
    const current_af = this.acquisitionFrameworks.filter(
      (af) => af.id_acquisition_framework === id_af
    )[0];
    if (current_af !== undefined && !('datasetsTemp' in current_af)) {
      this.dataFormService
        .getDatasets({ id_acquisition_frameworks: [id_af] })
        .toPromise()
        .then((datasets) => {
          this.setDsObservationCount(datasets, this._datasetNbObs);
          current_af.datasetsTemp = datasets;
        });
    }
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
