import { Component, OnInit } from '@angular/core';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';

import { MapListService } from '@geonature_common/map-list/map-list.service';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { SyntheseFormService } from '@geonature_common/form/synthese-form/synthese-form.service';
import { SyntheseStoreService } from './services/store.service';
import { SyntheseModalDownloadComponent } from './synthese-results/synthese-list/modal-download/modal-download.component';
import { ToastrService } from 'ngx-toastr';
import { ActivatedRoute } from '@angular/router';
import { SyntheseInfoObsComponent } from '../shared/syntheseSharedModule/synthese-info-obs/synthese-info-obs.component';
import * as cloneDeep from 'lodash/cloneDeep';
import { EventToggle } from './synthese-results/synthese-carte/synthese-carte.component';
import { ConfigService } from '@geonature/services/config.service';

@Component({
  selector: 'pnx-synthese',
  styleUrls: ['synthese.component.scss'],
  templateUrl: 'synthese.component.html',
  providers: [MapListService],
})
export class SyntheseComponent implements OnInit {
  public searchBarHidden = false;
  public marginButton: number;
  public firstLoad = true;
  public CONFIG = null;

  constructor(
    public searchService: SyntheseDataService,
    public _mapListService: MapListService,
    private _modalService: NgbModal,
    private _fs: SyntheseFormService,
    private _syntheseStore: SyntheseStoreService,
    private _toasterService: ToastrService,
    private _route: ActivatedRoute,
    private _ngModal: NgbModal,
    public cs: ConfigService
  ) {
    this.CONFIG = this.cs;
  }

  ngOnInit() {
    this._fs.selectors = this._fs.selectors
      .set('limit', this.cs.SYNTHESE.NB_LAST_OBS)
      .set(
        'format',
        this.cs.SYNTHESE.AREA_AGGREGATION_ENABLED &&
        this.cs.SYNTHESE.AREA_AGGREGATION_BY_DEFAULT
          ? 'grouped_geom_by_areas'
          : 'grouped_geom'
      );
    this._route.queryParamMap.subscribe((params) => {
      if (params.get('id_dataset')) {
        this._fs.searchForm.patchValue({ id_dataset: params.get('id_dataset') });
      }
      if (params.get('id_acquisition_framework')) {
        this._fs.searchForm.patchValue({
          id_acquisition_framework: params.get('id_acquisition_framework'),
        });
      }
      const idSynthese = this._route.snapshot.paramMap.get('id_synthese');

      if (idSynthese) {
        this._fs.searchForm.patchValue({ id_synthese: params.get('idSynthese') });
        this.openInfoModal(idSynthese);
      }

      this._fs.selectedCdRefFromTree = [];
      this._fs.selectedTaxonFromRankInput = [];
      this._fs.selectedtaxonFromComponent = [];
      this._fs.selectedRedLists = [];
      this._fs.selectedStatus = [];
      this._fs.selectedTaxRefAttributs = [];
      this.loadAndStoreData(this._fs.formatParams());
      // remove initial parameter passed by url
      this._fs.searchForm.patchValue({
        id_dataset: null,
        id_acquisition_framework: null,
      });
    });
  }

  loadAndStoreData(formParams) {
    this.searchService.dataLoaded = false;
    this._fs.searchForm.markAsPristine();

    this.searchService.getSyntheseData(formParams, this._fs.selectors).subscribe(
      (data) => {
        // mark the form pristine at each search in order to manage store data
        if (this._fs.selectors.get('format') == 'grouped_geom_by_areas') {
          this._syntheseStore.gridData = data;
        } else {
          this._syntheseStore.pointData = data;
        }
        // Store the list of id_synthese for exports
        this._syntheseStore.idSyntheseList = this.extractSyntheseIds(data);

        // Check if synthese observations limit is reach
        if (this._syntheseStore.idSyntheseList.length >= this.cs.SYNTHESE.NB_MAX_OBS_MAP) {
          const modalRef = this._modalService.open(SyntheseModalDownloadComponent, {
            size: 'lg',
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
      (error) => {
        this.searchService.dataLoaded = true;
      }
    );

    if (this.firstLoad && this._fs.selectors.has('limit')) {
      //toaster
      let limit = this._fs.selectors.get('limit');
      this._toasterService.info(`Les ${limit} dernières observations de la synthèse`, '');
    }
    this.firstLoad = false;
  }

  /** table data expect an array obs observation
   * the geojson get from API is a list of features whith an observation list
   */
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
  }

  fetchOrRenderData(event: EventToggle) {
    // if the form has change reload data
    // else load data from cache if already loaded
    if (this._fs.searchForm.dirty) {
      this.loadAndStoreData(this._fs.formatParams());
    } else {
      if (event == 'point') {
        if (this._syntheseStore.pointData) {
          this._mapListService.geojsonData = this.simplifyGeoJson(
            cloneDeep(this._syntheseStore.pointData)
          );
        } else {
          this.loadAndStoreData(this._fs.formatParams());
        }
      } else {
        if (this._syntheseStore.gridData) {
          this._mapListService.geojsonData = this.simplifyGeoJson(
            cloneDeep(this._syntheseStore.gridData)
          );
        } else {
          this.loadAndStoreData(this._fs.formatParams());
        }
      }
    }
  }
  onSearchEvent() {
    // on search button click, clean cache and call loadAndStoreData
    this._syntheseStore.gridData = null;
    this._syntheseStore.pointData = null;
    this.loadAndStoreData(this._fs.formatParams());
  }

  private extractSyntheseIds(geojson) {
    let ids = [];
    for (let feature of geojson.features) {
      feature.properties.observations.forEach((obs) => {
        ids.push(obs['id']);
      });
    }
    return ids;
  }

  private simplifyGeoJson(geojson) {
    for (let feature of geojson.features) {
      let ids = [];
      for (let obs of Object.values(feature.properties.observations)) {
        if (obs['id']) {
          ids.push(obs['id']);
        }
      }
      feature.properties.observations = { id: ids };
    }
    return geojson;
  }

  openInfoModal(idSynthese) {
    const modalRef = this._ngModal.open(SyntheseInfoObsComponent, {
      size: 'lg',
      windowClass: 'large-modal',
    });
    modalRef.componentInstance.idSynthese = idSynthese;
    modalRef.componentInstance.header = true;
    modalRef.componentInstance.useFrom = 'synthese';
  }

  mooveButton() {
    this.searchBarHidden = !this.searchBarHidden;
  }

  closeInfo(infoAlert: HTMLElement) {
    infoAlert.hidden = true;
  }
}
