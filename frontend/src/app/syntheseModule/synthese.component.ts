import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';

import * as cloneDeep from 'lodash/cloneDeep';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { ToastrService } from 'ngx-toastr';

import { ConfigService } from '@geonature/services/config.service';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { MapListService } from '@geonature_common/map-list/map-list.service';
import { SyntheseFormService } from '@geonature_common/form/synthese-form/synthese-form.service';

import { EventDisplayCriteria, SyntheseCriteriaService } from './services/criteria.service';
import { SyntheseInfoObsComponent } from '../shared/syntheseSharedModule/synthese-info-obs/synthese-info-obs.component';
import { SyntheseStoreService } from './services/store.service';
import { SyntheseModalDownloadComponent } from './synthese-results/synthese-list/modal-download/modal-download.component';

@Component({
  selector: 'pnx-synthese',
  styleUrls: ['synthese.component.scss'],
  templateUrl: 'synthese.component.html',
  providers: [MapListService],
})
export class SyntheseComponent implements OnInit {
  private idsByFeature: Set<number>;
  public firstLoad = true;
  private noGeomMessage: boolean;

  public isSearchBarReduced = false;
  private criteriaByFeature: Set<any>;

  constructor(
    public config: ConfigService,
    public searchService: SyntheseDataService,
    public mapListService: MapListService,
    private modalService: NgbModal,
    private formService: SyntheseFormService,
    private syntheseStore: SyntheseStoreService,
    private toasterService: ToastrService,
    private route: ActivatedRoute,
    private ngModal: NgbModal,
    private changeDetector: ChangeDetectorRef,
    private router: Router,
    private criteriaService: SyntheseCriteriaService
  ) {}

  ngOnInit() {
    this.formService.selectors = this.formService.selectors.set(
      'limit',
      this.config.SYNTHESE.NB_LAST_OBS
    );

    this.route.queryParamMap.subscribe((params) => {
      if (params.get('id_dataset')) {
        this.formService.searchForm.patchValue({ id_dataset: params.get('id_dataset') });
      }

      if (params.get('id_acquisition_framework')) {
        this.formService.searchForm.patchValue({
          id_acquisition_framework: params.get('id_acquisition_framework'),
        });
      }

      const idSynthese = this.route.snapshot.paramMap.get('id_synthese');
      if (idSynthese) {
        this.formService.searchForm.patchValue({ id_synthese: params.get('idSynthese') });
        this.openInfoModal(idSynthese);
      }

      this.initializeForm();
      this.applyDefaultFormValues(params);
    });
  }

  private initializeForm() {
    this.formService.selectedCdRefFromTree = [];
    this.formService.selectedTaxonFromRankInput = [];
    this.formService.selectedtaxonFromComponent = [];
    this.formService.selectedRedLists = [];
    this.formService.selectedStatus = [];
    this.formService.selectedTaxRefAttributs = [];
  }

  private applyDefaultFormValues(params) {
    this.formService
      .processDefaultFilters(this.config.SYNTHESE.DEFAULT_FILTERS)
      .subscribe((processedDefaultFilters) => {
        if (params.get('id_import')) {
          processedDefaultFilters['id_import'] = params.get('id_import');
        }
        this.formService.searchForm.patchValue(processedDefaultFilters);
        this.formService.processedDefaultFilters = processedDefaultFilters;
        this.changeDetector.detectChanges();

        this.loadData();
      });
  }

  loadData() {
    let formParams = this.formService.formatParams();
    this.searchService.dataLoaded = false;
    this.formService.searchForm.markAsPristine();

    this.searchService.getSyntheseData(formParams, this.formService.selectors).subscribe(
      (data) => {
        this.syntheseStore.setData(this.getCurrentStoreType(), data);
        this.parseGeoJson(data);
        this.displayMessageLimitNumberObservationsReached(formParams);
        this.searchService.dataLoaded = true;
      },
      () => {
        this.searchService.dataLoaded = true;
      }
    );

    this.displayMessageLastObsLimit();
  }

  private parseGeoJson(rawGeojson) {
    this.initializeStores();

    let geojson = cloneDeep(rawGeojson);
    geojson.features.forEach((feature) => {
      this.idsByFeature = new Set();
      this.checkGeomAbsence(feature);

      feature.properties.observations.forEach((obs) => {
        this.extractIds(obs);
        this.extractCriteria(obs);
        this.addObservationToDataTable(cloneDeep(obs));
      });

      // WARNING: needs to return the updated object here !
      feature.properties.observations = this.buildObservationsProperty();

      // Store map display criteria values
      this.storeCriteriaValues(feature);
    });

    this.displayMessageGeomAbsence();
    this.orderDataTableByDates();
    this.mapListService.geojsonData = geojson;
  }

  private initializeStores() {
    this.mapListService.idName = 'id_synthese';
    this.mapListService.tableData = [];
    this.noGeomMessage = false;
    this.criteriaByFeature = new Set();
  }

  private getCurrentStoreType() {
    return this.criteriaService.getCurrentCode();
  }

  private extractIds(observation) {
    if (observation['id_synthese']) {
      const id = observation['id_synthese'];
      if (this.syntheseStore.idSyntheseList.has(id) === false) {
        this.syntheseStore.idSyntheseList.add(id);
      }

      if (this.idsByFeature.has(id) === false) {
        this.idsByFeature.add(id);
      }
    }
  }

  private extractCriteria(observation) {
    if (this.criteriaService.isCriteriaDisplay()) {
      const criteriaField = this.criteriaService.getCurrentField();
      if (observation[criteriaField]) {
        const criteriaValue = observation[criteriaField];
        if (this.criteriaByFeature && this.criteriaByFeature.has(criteriaValue) === false) {
          this.criteriaByFeature.add(criteriaValue);
        }
      }
    }
  }

  private addObservationToDataTable(observation) {
    if (observation['id_synthese']) {
      if (this.mapListService.tableData.includes(observation.id_synthese) === false) {
        this.mapListService.tableData.push(observation);
      }
    }
  }

  private storeCriteriaValues(feature) {
    if (this.criteriaByFeature && this.criteriaByFeature.size > 0) {
      const criteriaField = this.criteriaService.getCurrentField();
      feature.properties.observations[criteriaField] = Array.from(this.criteriaByFeature);
    }
  }

  private checkGeomAbsence(feature) {
    if (!feature.geometry) {
      this.noGeomMessage = true;
    }
  }

  private buildObservationsProperty() {
    return { id_synthese: Array.from(this.idsByFeature) };
  }

  private displayMessageLimitNumberObservationsReached(formParams) {
    if (this.syntheseStore.idSyntheseList.size >= this.config.SYNTHESE.NB_MAX_OBS_MAP) {
      const modalRef = this.modalService.open(SyntheseModalDownloadComponent, {
        size: 'lg',
      });
      modalRef.componentInstance.queryString = this.searchService.buildQueryUrl(formParams);
      modalRef.componentInstance.tooManyObs = true;
    }
  }

  private displayMessageGeomAbsence() {
    if (this.noGeomMessage) {
      this.toasterService.warning(
        "Certaine(s) observation(s) n'ont pas pu être affiché(es) sur la carte car leur maille d’aggrégation n'est pas disponible"
      );
    }
  }

  private displayMessageLastObsLimit() {
    if (this.firstLoad && this.formService.selectors.has('limit')) {
      let limit = this.formService.selectors.get('limit');
      this.toasterService.info(`Les ${limit} dernières observations de la synthèse`, '');
    }
    this.firstLoad = false;
  }

  private orderDataTableByDates() {
    this.mapListService.tableData = this.mapListService.tableData.sort((a, b) => {
      return (new Date(b.date_min).valueOf() as any) - new Date(a.date_min).valueOf();
    });
  }

  fetchOrRenderData(event: EventDisplayCriteria) {
    // if the form has change reload data
    // else load data from cache if already loaded
    if (this.formService.searchForm.dirty || this.syntheseStore.hasData(event.name) === false) {
      this.loadData();
    } else {
      let storedData = this.syntheseStore.getData(event.name);
      this.parseGeoJson(storedData);
    }
  }

  onSearchEvent() {
    // Remove limit
    this.formService.selectors = this.formService.selectors.delete('limit');
    // By clicking the search button, clean the cache and call the data loading
    this.syntheseStore.clearData();
    this.loadData();
  }

  openInfoModal(idSynthese) {
    const modalRef = this.ngModal.open(SyntheseInfoObsComponent, {
      size: 'lg',
      windowClass: 'large-modal',
    });
    modalRef.componentInstance.idSynthese = idSynthese;
    modalRef.componentInstance.header = true;
    modalRef.componentInstance.useFrom = 'synthese';

    let tabRoute = this.route.snapshot.paramMap.get('tab');
    if (tabRoute != null) {
      modalRef.componentInstance.selectedTab = tabRoute;
    }

    modalRef.result
      .then((result) => {})
      .catch((_) => {
        this.router.navigate([modalRef.componentInstance.useFrom]);
      });
  }
}
