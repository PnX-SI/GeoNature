import { Component, OnInit, ViewChild } from '@angular/core';
import { PageEvent, MatPaginator, MatPaginatorIntl } from '@angular/material';
import { CruvedStoreService } from '../GN2CommonModule/service/cruved-store.service';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { AppConfig } from '@geonature_config/app.config';
import { Router, NavigationExtras } from "@angular/router";
import { NgbModal } from "@ng-bootstrap/ng-bootstrap";
import { NgbDateStruct } from '@ng-bootstrap/ng-bootstrap';

import { CommonService } from "@geonature_common/service/common.service";
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { MetadataSearchFormService } from "./services/metadata-search-form.service"
import { distinctUntilChanged, debounceTime, filter } from 'rxjs/operators';

export class MetadataPaginator extends MatPaginatorIntl {
  constructor() {
    super();
    this.nextPageLabel = 'Page suivante';
    this.previousPageLabel = 'Page précédente';
    this.itemsPerPageLabel = 'Éléments par page';
    this.getRangeLabel = (page: number, pageSize: number, length: number) => {
      if (length == 0 || pageSize == 0) {
        return `0 sur ${length}`;
      }
      length = Math.max(length, 0);
      const startIndex = page * pageSize;
      const endIndex =
        startIndex < length ? Math.min(startIndex + pageSize, length) : startIndex + pageSize;
      return `${startIndex + 1} - ${endIndex} sur ${length}`;
    };
  }
}
@Component({
  selector: 'pnx-metadata',
  templateUrl: './metadata.component.html',
  styleUrls: ['./metadata.component.scss'],
  providers: [
    {
      provide: MatPaginatorIntl,
      useClass: MetadataPaginator
    },
    MetadataSearchFormService

  ]
})
export class MetadataComponent implements OnInit {
  @ViewChild(MatPaginator) paginator: MatPaginator;
  model: NgbDateStruct;
  datasets = [];
  acquisitionFrameworks = [];
  tempAF = [];
  public history;
  public endPoint: string;
  public empty: boolean = false;
  expandAccordions = false;
  private researchTerm: string = '';
  public organisms: Array<any>;
  public roles: Array<any>;
  public isLoading = false;
  public datasetNbObs = null;

  pageSize: number = AppConfig.METADATA.NB_AF_DISPLAYED;
  activePage: number = 0;
  pageSizeOptions: Array<number> = [10, 25, 50, 100];

  searchTerms: any = {};
  afPublishModalId: number;
  afPublishModalLabel: string;
  afPublishModalContent: string;
  APP_CONFIG = AppConfig;

  constructor(
    public _cruvedStore: CruvedStoreService,
    private _dfs: DataFormService,
    private _router: Router,
    private modal: NgbModal,
    public searchFormService: MetadataSearchFormService,
    private _commonService: CommonService,
    private _syntheseDataService: SyntheseDataService
  ) { }

  ngOnInit() {
    this.getAcquisitionFrameworksAndDatasets();
    this._dfs.getOrganisms().subscribe(data => {
      this.organisms = data;
    });
    this._dfs.getRoles({ 'group': false }).subscribe(data => {
      this.roles = data;
    });
    this.afPublishModalLabel = AppConfig.METADATA.CLOSED_MODAL_LABEL;
    this.afPublishModalContent = AppConfig.METADATA.CLOSED_MODAL_CONTENT;

    // rapid search event
    this.searchFormService.rapidSearchControl.valueChanges.pipe(
      debounceTime(200),
      distinctUntilChanged()
    ).subscribe(value => {
      this.updateSearchbar(value)
    })

  }

  setDsObservationCount(datasets, dsNbObs) {
    datasets.forEach(ds=> {
      let foundDS = dsNbObs.find(d => {                
        return d.id_dataset == ds.id_dataset
      })
      if (foundDS) {
        ds.observation_count = foundDS.count
      }
      else {
        ds.observation_count = 0;
      }
    })
  }

  //recuperation cadres d'acquisition
  getAcquisitionFrameworksAndDatasets(formValue={}, expand=false) {
    this.isLoading = true;
    this._dfs.getAfAndDatasetListMetadata(formValue).subscribe(
      data => {
        this.isLoading = false;
        this.acquisitionFrameworks = data.data;
        this.tempAF = this.acquisitionFrameworks;
        this.datasets = [];
        this.acquisitionFrameworks.forEach(af => {
          af['datasetsTemp'] = af['datasets'];
          this.datasets = this.datasets.concat(af['datasets']);
        })
      if(expand) {
        this.expandAccordions = (this.searchFormService.form.value.selector == 'ds');

      }
      // load stat for ds
      if (!this.datasetNbObs) {        
        this._syntheseDataService.getObsCountByColumn('id_dataset').subscribe(count_ds => {
          this.datasetNbObs = count_ds
          this.setDsObservationCount(this.datasets, this.datasetNbObs);
          
        })
      } else {        
        this.setDsObservationCount(this.datasets, this.datasetNbObs);
      }


    },
    err => {
      this.isLoading = false;
    }
    );
  }


  /**
   *	Filtre les éléments CA et JDD selon la valeur de la barre de recherche
   **/
  updateSearchbar(event) {
    this.researchTerm = event;
    const searchTerm = this.researchTerm.toLocaleLowerCase();
    //recherche des cadres d'acquisition qui matchent
    this.tempAF = this.acquisitionFrameworks.filter(af => {
      //si vide => affiche tout et ferme le panel
      if (this.researchTerm === '') {
        // 'dé-expand' les accodions pour prendre moins de place
        this.expandAccordions = false;
        //af.datasets.filter(ds=>true);
        af.datasetsTemp = af.datasets;
        return true;
      } else {
        
        // expand tous les accordeons recherchés pour voir le JDD des CA
        this.expandAccordions = true;
        if ((af.id_acquisition_framework + ' ').toLowerCase().indexOf(searchTerm) !== -1
          || af.acquisition_framework_name.toLowerCase().indexOf(searchTerm) !== -1
          || af.acquisition_framework_start_date.toLowerCase().indexOf(searchTerm) !== -1
          || af.unique_acquisition_framework_id.toLowerCase().indexOf(searchTerm) !== -1
        ) {
          //si un cadre matche on affiche tous ses JDD
          af.datasetsTemp = af.datasets;
          return true;
        }

        //Sinon on on filtre les JDD qui matchent eventuellement
        if (af.datasets) {
          af.datasetsTemp = af.datasets.filter(
            ds => ((ds.id_dataset + ' ').toLowerCase().indexOf(searchTerm) !== -1
              || ds.dataset_name.toLowerCase().indexOf(searchTerm) !== -1
              || ds.unique_dataset_id.toLowerCase().indexOf(searchTerm) !== -1
              || ds.meta_create_date.toLowerCase().indexOf(searchTerm) !== -1)
          );
          return af.datasetsTemp.length;
        }
        return false;
      }
    });
    //retour à la premiere page du tableau pour voir les résultats
    this.paginator.pageIndex = 0;
    this.activePage = 0;
  }

  updateAdvancedCriteria(event, criteria) {
    if (criteria != 'date')
      this.searchTerms[criteria] = event.target.value.toLowerCase();
    else
      this.searchTerms[criteria] = event.year
        + '-' + (event.month > 10 ? '' : '0') + event.month
        + '-' + (event.day > 10 ? '' : '0') + event.day;
  }

  refreshFilters() {
    this.searchFormService.form.reset();
    this.advancedSearch();
  }

  updateSelector(event) {
    this.searchTerms['selector'] = event.target.value.toLowerCase();
  }

  reinitAdvancedCriteria() {
    this.searchTerms = {};
  }

  advancedSearch() {

    const formValue = this.searchFormService.formatFormValue(
      Object.assign({}, this.searchFormService.form.value)
    );



    // this._dfs.getAfAndDatasetListMetadata(formValue).subscribe(data => {
    //   this.tempAF = data.data;
    //   this.datasets = [];
    //   this.tempAF.forEach(af => {
    //     af['datasetsTemp'] = af['datasets'];
    //     this.datasets = this.datasets.concat(af['datasets']);
    //   })
    // });

    this.getAcquisitionFrameworksAndDatasets(formValue, true);
  }

  openSearchModal(searchModal) {
    this.searchFormService.resetForm();

    this.modal.open(searchModal);
  }

  closeSearchModal() {
    this.modal.dismissAll();
  }

  isDisplayed(idx: number) {
    //numero du CA à partir de 1
    let element = idx + 1;
    //calcul des tranches active à afficher
    let idxMin = this.pageSize * this.activePage;
    let idxMax = this.pageSize * (this.activePage + 1);

    return idxMin < element && element <= idxMax;
  }

  changePaginator(event: PageEvent) {
    this.pageSize = event.pageSize;
    this.activePage = event.pageIndex;
  }

  deleteAf(af_id) {
    this._dfs.deleteAf(af_id).subscribe(
      res => this.getAcquisitionFrameworksAndDatasets()
    );
  }

  syntheseAf(af_id) {
    let navigationExtras: NavigationExtras = {
      queryParams: {
        "id_acquisition_framework": af_id
      }
    };
    this._router.navigate(['/synthese'], navigationExtras);
  }

  openPublishModalAf(e, af_id, publishModal) {
    this.afPublishModalId = af_id;
    this.modal.open(publishModal, { size: 'lg' });
    e.stopPropagation();
  }

  publishAf() {
    this._dfs.publishAf(this.afPublishModalId).subscribe(
      res => this.getAcquisitionFrameworksAndDatasets(),
      error => {
        if(error.error.name == 'mailError') {
          this._commonService.regularToaster(
            'warning', "Erreur lors de l'envoi de l'email de confirmation. Le cadre d'acquisition a bien été fermé"
            )
        } else {
          this._commonService.regularToaster(
            'error', "Une erreur s'est produite lors de la fermeture du cadre d'acquisition. Contactez l'administrateur"
            )
        }
        

    }
    )

    this.modal.dismissAll();
  }

  deleteDs(ds_id) {
    if (window.confirm('Etes-vous sûr de vouloir supprimer ce jeu de données ?')) {
      this._dfs.deleteDs(ds_id).subscribe(
        res => this.getAcquisitionFrameworksAndDatasets()
      );
    }

  }

  syntheseDs(ds_id, data_number, syntheseNoneModal) {
    if (data_number == 0) {
      this.modal.open(syntheseNoneModal);
    } else {
      let navigationExtras: NavigationExtras = {
        queryParams: {
          "id_dataset": ds_id
        }
      };
      this._router.navigate(['/synthese'], navigationExtras);
    }

  }

  importDs(ds_id) {
    let navigationExtras: NavigationExtras = {
      queryParams: {
        "datasetId": ds_id,
        "resetStepper": true
      }
    };
    this._router.navigate(['/import/process/step/1'], navigationExtras);
  }



}
