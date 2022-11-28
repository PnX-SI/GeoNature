import { Component, OnInit, ElementRef } from '@angular/core';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';

import { MapListService } from '@geonature_common/map-list/map-list.service';
import { CommonService } from '@geonature_common/service/common.service';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { SyntheseFormService } from '@geonature_common/form/synthese-form/synthese-form.service';
import { SyntheseStoreService } from './services/store.service';
import { SyntheseModalDownloadComponent } from './synthese-results/synthese-list/modal-download/modal-download.component';
import { AppConfig } from '@geonature_config/app.config';
import { ToastrService } from 'ngx-toastr';
import { ActivatedRoute } from '@angular/router';
import { SyntheseInfoObsComponent } from '../shared/syntheseSharedModule/synthese-info-obs/synthese-info-obs.component';
import * as cloneDeep from 'lodash/cloneDeep';
import { EventToggle } from './synthese-results/synthese-carte/synthese-carte.component';
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
  public CONFIG = AppConfig;

  constructor(
    public searchService: SyntheseDataService,
    public _mapListService: MapListService,
    private _commonService: CommonService,
    private _modalService: NgbModal,
    private _fs: SyntheseFormService,
    private _syntheseStore: SyntheseStoreService,
    private _toasterService: ToastrService,
    private _route: ActivatedRoute,
    private _ngModal: NgbModal
  ) {}

  loadAndStoreData(formParams) {
    this.searchService.dataLoaded = false;
    this._fs.searchForm.markAsPristine();
    this.searchService.getSyntheseData(formParams).subscribe(
      (data) => {
        // mark the form pristine at each search in order to manage store data
        if (this._fs.searchForm.value.with_areas) {
          this._syntheseStore.gridData = data;
        } else {
          this._syntheseStore.pointData = data;
        }
        // Store the list of id_synthese for exports
        this._syntheseStore.idSyntheseList = this.extractSyntheseIds(data);

        // Check if synthese observations limit is reach
        if (this._syntheseStore.idSyntheseList.length >= AppConfig.SYNTHESE.NB_MAX_OBS_MAP) {
          const modalRef = this._modalService.open(SyntheseModalDownloadComponent, {
            size: 'lg',
          });
          const formatedParams = this._fs.formatParams();
          modalRef.componentInstance.queryString = this.searchService.buildQueryUrl(formatedParams);
          modalRef.componentInstance.tooManyObs = true;
        }

        // Store geojson
        this._mapListService.geojsonData = this.simplifyGeoJson(cloneDeep(data));
        this._mapListService.loadTableData(data);
        this._mapListService.idName = 'id';
        this.searchService.dataLoaded = true;
      },
      (error) => {
        this.searchService.dataLoaded = true;

        if (error.status == 400) {
          this._commonService.regularToaster('error', error.error.description);
        }
      }
    );

    if (this.firstLoad && 'limit' in formParams) {
      //toaster
      this._toasterService.info(
        `Les ${AppConfig.SYNTHESE.NB_LAST_OBS} dernières observations de la synthèse`,
        ''
      );
    }
    this.firstLoad = false;
  }

  fetchOrRenderData(event: EventToggle) {
    // if the form has change reload data
    // else load data from cache if already loaded

    if (this._fs.searchForm.dirty) {
      this.loadAndStoreData(this._fs.formatParams());
    } else {
      if (event == 'point') {
        console.log('passe point');
        if (this._syntheseStore.pointData) {
          this._mapListService.geojsonData = this.simplifyGeoJson(
            cloneDeep(this._syntheseStore.pointData)
          );
          this._mapListService.loadTableData(this._syntheseStore.pointData);
        } else {
          this.loadAndStoreData(this._fs.formatParams());
        }
      } else {
        if (this._syntheseStore.gridData) {
          this._mapListService.geojsonData = this.simplifyGeoJson(
            cloneDeep(this._syntheseStore.gridData)
          );
          this._mapListService.loadTableData(this._syntheseStore.gridData);
        } else {
          this.loadAndStoreData(this._fs.formatParams());
        }
      }
    }
  }
  onSearchEvent(form) {
    // on search button click, clean cache and call loadAndStoreData
    this._syntheseStore.gridData = null;
    this._syntheseStore.pointData = null;
    this.loadAndStoreData(form);
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

  ngOnInit() {
    this._route.queryParamMap.subscribe((params) => {
      let initialFilter = {};
      const idSynthese = this._route.snapshot.paramMap.get('id_synthese');
      if (idSynthese) {
        initialFilter['id_synthese'] = idSynthese;
        this.openInfoModal(idSynthese);
      }

      initialFilter['with_areas'] =
        AppConfig.SYNTHESE.ENABLE_AREA_AGGREGATION &&
        AppConfig.SYNTHESE.AREA_AGGREGATION_BY_DEFAULT;
      if (params.get('id_acquisition_framework')) {
        initialFilter['id_acquisition_framework'] = params.get('id_acquisition_framework');
      } else if (params.get('id_dataset')) {
        initialFilter['id_dataset'] = params.get('id_dataset');
      } else {
        initialFilter['limit'] = AppConfig.SYNTHESE.NB_LAST_OBS;
      }

      // reinitialize the form
      this._fs.searchForm.reset();
      this._fs.selectedCdRefFromTree = [];
      this._fs.selectedTaxonFromRankInput = [];
      this._fs.selectedtaxonFromComponent = [];
      this._fs.selectedRedLists = [];
      this._fs.selectedStatus = [];
      this._fs.selectedTaxRefAttributs = [];
      this.loadAndStoreData(initialFilter);
    });
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
