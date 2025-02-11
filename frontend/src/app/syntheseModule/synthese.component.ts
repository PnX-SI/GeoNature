import { Component, OnInit, ElementRef } from '@angular/core';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';

import { MapListService } from '@geonature_common/map-list/map-list.service';
import { CommonService } from '@geonature_common/service/common.service';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { SyntheseFormService } from '@geonature_common/form/synthese-form/synthese-form.service';
import { SyntheseStoreService } from '@geonature/syntheseModule/services/store.service';
import { SyntheseModalDownloadComponent } from './synthese-results/synthese-list/modal-download/modal-download.component';
import { AppConfig } from '@geonature_config/app.config';
import { ToastrService } from 'ngx-toastr';
import { ActivatedRoute } from '@angular/router';
import * as cloneDeep from 'lodash/cloneDeep';
import { EventDisplayCriteria, SyntheseCriteriaService } from './services/criteria.service';

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

  constructor(
    public searchService: SyntheseDataService,
    public _mapListService: MapListService,
    private _modalService: NgbModal,
    private _fs: SyntheseFormService,
    private _syntheseStore: SyntheseStoreService,
    private _toasterService: ToastrService,
    private _route: ActivatedRoute,
    private criteriaService: SyntheseCriteriaService,
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

        // Store the list of id_synthese for exports
        this._syntheseStore.idSyntheseList = this.extractSyntheseIds(data);

        // Check if synthese observations limit is reach
        if (this._syntheseStore.idSyntheseList.length >= AppConfig.SYNTHESE.NB_MAX_OBS_MAP) {
          const modalRef = this._modalService.open(SyntheseModalDownloadComponent, {
            size: 'lg'
          });
          modalRef.componentInstance.queryString = this.searchService.buildQueryUrl(formParams);
          modalRef.componentInstance.tooManyObs = true;
        }

        // Store geojson
        this._mapListService.geojsonData = this.simplifyGeoJson(cloneDeep(data));
        this.formatDataForTable(data);

        this._mapListService.idName = 'id';
        this.searchService.dataLoaded = true;
      },
      () => {
        this.searchService.dataLoaded = true;
      }
    );

    if (this.firstLoad && this._fs.selectors.get('limit')) {
      //toaster
      let limit = this._fs.selectors.get('limit');
      this._toasterService.info(`Les ${limit} dernières observations de la synthèse`, '');
    }
    this.firstLoad = false;
  }

  private extractSyntheseIds(geojson) {
    let ids = [];
    for (let feature of geojson.features) {
      for (let obs of Object.values(feature.properties.observations)) {
        ids.push(obs['id']);
      }
    }
    return ids;
  }

  private simplifyGeoJson(geojson) {
    let noGeomMessage = false;
    for (let feature of geojson.features) {
      if (!feature.geometry) {
        noGeomMessage = true;
      }

      // Extract id_synthese list and critierias values list
      let ids = [];
      let criteriaValuesList = [];
      for (let obs of Object.values(feature.properties.observations)) {
        if (obs['id']) {
          ids.push(obs['id']);
        }

        // Extract map display criteria values list
        if (this.criteriaService.isCriteriaDisplay()) {
          const criteriaField = this.criteriaService.getCurrentField();
          if (obs[criteriaField]) {
            const criteriaValue = obs[criteriaField];
            if (!criteriaValuesList.includes(criteriaValue)) {
              criteriaValuesList.push(criteriaValue);
            }
          }
        }
      }

      feature.properties.observations = { id: ids };

      // Store map display criteria values
      if (criteriaValuesList.length > 0) {
        const criteriaField = this.criteriaService.getCurrentField();
        feature.properties.observations[criteriaField] = criteriaValuesList;
      }
    }

    if (noGeomMessage) {
      this._toasterService.warning(
        "Certaine(s) observation(s) n'ont pas pu être affiché(es) sur la carte car leur maille d’aggrégation n'est pas disponible"
      );
    }

    return geojson;
  }

  /** table data expect an array obs observation
   * the geojson get from API is a list of features whith an observation list
   */
  // TODO: [IMPROVE][PAGINATE] data in datable is formated here
  formatDataForTable(geojson) {
    this._mapListService.tableData = [];
    const idSynthese = new Set();
    geojson.features.forEach((feature) => {
      feature.properties.observations.forEach((obs) => {
        if (!idSynthese.has(obs.id)) {
          this._mapListService.tableData.push(obs);
          idSynthese.add(obs.id);
        }
      });
    });

    // Order by date
    this._mapListService.tableData = this._mapListService.tableData.sort((a, b) => {
      return (new Date(b.date_min).valueOf() as any) - new Date(a.date_min).valueOf();
    });
  }

  fetchOrRenderData(event: EventDisplayCriteria) {
    // if the form has change reload data
    // else load data from cache if already loaded
    if (this._fs.searchForm.dirty) {
      this.loadAndStoreData(this._fs.formatParams());
    } else {
      if (this._syntheseStore.data[event.name]) {
        const cachedData = this._syntheseStore.data[event.name];
        this._mapListService.geojsonData = this.simplifyGeoJson(cloneDeep(cachedData));
        this.formatDataForTable(cachedData);
      } else {
        this.loadAndStoreData(this._fs.formatParams());
      }
    }
  }

  onSearchEvent() {
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
