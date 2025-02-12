import { Component, OnInit } from '@angular/core';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';

import { MapListService } from '@geonature_common/map-list/map-list.service';
import { CommonService } from '@geonature_common/service/common.service';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { SyntheseFormService } from '@geonature_common/form/synthese-form/synthese-form.service';
import { SyntheseStoreService } from '@geonature/syntheseModule/services/store.service';
import { AppConfig } from '@geonature_config/app.config';
import { ToastrService } from 'ngx-toastr';
import { ActivatedRoute } from '@angular/router';
import * as cloneDeep from 'lodash/cloneDeep';
import { EventDisplayCriteria, SyntheseCriteriaService } from './services/criteria.service';
import { SyntheseModalMessagesComponent } from './synthese-results/modal-messages/modal-messages.component';

@Component({
  selector: 'pnx-synthese',
  styleUrls: ['synthese.component.scss'],
  templateUrl: 'synthese.component.html',
  providers: [MapListService]
})
export class SyntheseComponent implements OnInit {
  public searchBarHidden = false;
  public marginButton: number;
  public firstLoad = true;
  public CONFIG = AppConfig;

  private idsByFeature: Set<number>;
  private criteriaByFeature: Set<any>;
  private hasNoGeom: boolean;
  private hasBlurredSensitiveObs: boolean;
  private newSearch: boolean;

  constructor(
    public searchService: SyntheseDataService,
    public _mapListService: MapListService,
    private _modalService: NgbModal,
    private _fs: SyntheseFormService,
    private _syntheseStore: SyntheseStoreService,
    private _toasterService: ToastrService,
    private _route: ActivatedRoute,
    private criteriaService: SyntheseCriteriaService,
    private commonService: CommonService
  ) {}

  ngOnInit() {
    this._fs.selectors = this._fs.selectors.set('limit', AppConfig.SYNTHESE.NB_LAST_OBS);

    this._route.queryParamMap.subscribe((params) => {
      if (params.get('id_dataset')) {
        this._fs.searchForm.patchValue({ id_dataset: params.get('id_dataset') });
      }

      if (params.get('id_acquisition_framework')) {
        this._fs.searchForm.patchValue({
          id_acquisition_framework: params.get('id_acquisition_framework'),
        });
      }

      // Reinitialize the form
      this._fs.searchForm.reset();
      this._fs.selectedCdRefFromTree = [];
      this._fs.selectedTaxonFromRankInput = [];
      this._fs.selectedtaxonFromComponent = [];
      this._fs.selectedRedLists = [];
      this._fs.selectedStatus = [];
      this._fs.selectedTaxRefAttributs = [];

      this.loadAndStoreData(this._fs.formatParams());
    });
  }

  loadAndStoreData(formParams) {
    this.searchService.dataLoaded = false;
    // Mark the form pristine at each search in order to manage store data
    this._fs.searchForm.markAsPristine();

    this.searchService.getSyntheseData(formParams, this._fs.selectors).subscribe(
      (data) => {
        this._syntheseStore.data[this.criteriaService.getCurrentCode()] = data;

        this._mapListService.idName = 'id';
        this.parseGeoJson(data);

        this.displayMessages();
        this.newSearch = false;
        this.searchService.dataLoaded = true;
      },
      () => {
        this.searchService.dataLoaded = true;
      }
    );

    if (this.firstLoad && this._fs.selectors.get('limit')) {
      let limit = this._fs.selectors.get('limit');
      this._toasterService.info(`Les ${limit} dernières observations de la synthèse`, '');
    }
    this.firstLoad = false;
  }

  private parseGeoJson(rawGeojson) {
    let geojson = cloneDeep(rawGeojson);
    this.initializeStores();

    geojson.features.forEach((feature) => {
      this.idsByFeature = new Set();
      this.criteriaByFeature = new Set();
      this.checkGeomAbsence(feature);

      feature.properties.observations.forEach((obs) => {
        this.extractIds(obs);
        this.extractCriteria(obs);
        this.addObservationToDataTable(cloneDeep(obs));
        this.checkBlurredGeom(obs);
      });

      // WARNING: needs to return the updated object here !
      feature.properties.observations = this.simplifyGeoJsonProperties(
        feature.properties.observations
      );
    });

    this.displayMessageGeomAbsence();
    this.orderDataTableByDates();
    this._mapListService.geojsonData = geojson;
  }

  private initializeStores() {
    this._syntheseStore.idSyntheseList = new Set();
    this._mapListService.tableData = [];
    this.hasNoGeom = false;
    this.hasBlurredSensitiveObs = false;
  }

  private extractIds(observation) {
    if (observation['id']) {
      const id = observation['id'];
      if (this._syntheseStore.idSyntheseList.has(id) === false) {
        this._syntheseStore.idSyntheseList.add(id);
      }

      if (this.idsByFeature.has(id) === false) {
        this.idsByFeature.add(id);
      }
    }
  }

  private addObservationToDataTable(observation) {
    if (observation['id']) {
      if (this._mapListService.tableData.includes(observation.id) === false) {
        this._mapListService.tableData.push(observation);
      }
    }
  }

  private extractCriteria(observation) {
    if (this.criteriaService.isCriteriaDisplay()) {
      const criteriaField = this.criteriaService.getCurrentField();
      if (observation[criteriaField]) {
        const criteriaValue = observation[criteriaField];
        if (this.criteriaByFeature.has(criteriaValue) === false) {
          this.criteriaByFeature.add(criteriaValue);
        }
      }
    }
  }

  private checkGeomAbsence(feature) {
    if (!feature.geometry) {
      this.hasNoGeom = true;
    }
  }

  private checkBlurredGeom(obs) {
    if (obs['is_blurred'] && obs.is_blurred === true) {
      this.hasBlurredSensitiveObs = true;
    }
  }

  private simplifyGeoJsonProperties(observations) {
    observations = { id: Array.from(this.idsByFeature) };

    // Store map display criteria value
    if (this.criteriaByFeature.size > 0) {
      const criteriaField = this.criteriaService.getCurrentField();
      observations[criteriaField] = Array.from(this.criteriaByFeature);
    }

    return observations;
  }

  private displayMessageGeomAbsence() {
    if (this.hasNoGeom) {
      this.commonService.translateToaster('warning', 'Synthese.NoGeomMessage');
    }
  }

  private orderDataTableByDates() {
    this._mapListService.tableData = this._mapListService.tableData.sort((a, b) => {
      return (new Date(b.date_min).valueOf() as any) - new Date(a.date_min).valueOf();
    });
  }

  private displayMessages() {
    let hasTooManyObs =
      this._syntheseStore.idSyntheseList.size >= AppConfig.SYNTHESE.NB_MAX_OBS_MAP ? true : false;

    if (this.newSearch && (hasTooManyObs || this.hasBlurredSensitiveObs)) {
      const modalRef = this._modalService.open(SyntheseModalMessagesComponent, {
        size: 'lg',
      });
      modalRef.componentInstance.hasTooManyObs = hasTooManyObs;
      modalRef.componentInstance.hasBlurredSensitiveObs = this.hasBlurredSensitiveObs;
    }
  }

  fetchOrRenderData(event: EventDisplayCriteria) {
    // if the form has change reload data
    // else load data from cache if already loaded
    if (this._fs.searchForm.dirty || this._syntheseStore.data.hasOwnProperty(event.name) === false) {
      this.loadAndStoreData(this._fs.formatParams());
    } else {
      this.parseGeoJson(this._syntheseStore.data[event.name]);
    }
  }

  onSearchEvent() {
    this.newSearch = true
    // Remove limit
    this._fs.selectors = this._fs.selectors.delete('limit');
    // On search button click, clean cache and call loadAndStoreData
    this._syntheseStore.data = {};
    this.loadAndStoreData(this._fs.formatParams());
  }

  moveButton() {
    this.searchBarHidden = !this.searchBarHidden;
  }
}
