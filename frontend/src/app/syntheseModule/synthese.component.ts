import { Component, OnInit, ElementRef } from '@angular/core';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';

import { MapListService } from '@geonature_common/map-list/map-list.service';
import { CommonService } from '@geonature_common/service/common.service';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { SyntheseFormService } from '@geonature_common/form/synthese-form/synthese-form.service';
import { SyntheseStoreService } from '@geonature_common/form/synthese-form/synthese-store.service';
import { SyntheseModalDownloadComponent } from './synthese-results/synthese-list/modal-download/modal-download.component';
import { AppConfig } from '@geonature_config/app.config';
import { ToastrService } from 'ngx-toastr';
import { ActivatedRoute } from '@angular/router';

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
    private _commonService: CommonService,
    private _modalService: NgbModal,
    private _fs: SyntheseFormService,
    private _syntheseStore: SyntheseStoreService,
    private _toasterService: ToastrService,
    private _route: ActivatedRoute
  ) { }

  loadAndStoreData(formParams) {
    this.searchService.dataLoaded = false;
    this.searchService.getSyntheseData(formParams).subscribe(
      result => {
        if (result['nb_obs_limited']) {
          const modalRef = this._modalService.open(SyntheseModalDownloadComponent, {
            size: 'lg'
          });
          const formatedParams = this._fs.formatParams();
          modalRef.componentInstance.queryString = this.searchService.buildQueryUrl(formatedParams);
          modalRef.componentInstance.tooManyObs = true;
        }
        this._mapListService.geojsonData = result['data'];
        this._mapListService.tableData = result['data'];
        this._mapListService.loadTableData(result['data']);
        this._mapListService.idName = 'id';
        this.searchService.dataLoaded = true;
        // store the list of id_synthese for exports
        this._syntheseStore.idSyntheseList = result['data']['features'].map(row => {
          return row['properties']['id'];
        });
      },
      error => {
        this.searchService.dataLoaded = true;
        console.log(error);
        
        if(error.status == 400) {
          this._commonService.regularToaster('error', error.error.description)
        } else {
          this._commonService.translateToaster('error', 'ErrorMessage');
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

  ngOnInit() {
    this._route.queryParamMap.subscribe(params => {
      let initialFilter = {};
      if (params.get('id_acquisition_framework')) {
        initialFilter['id_acquisition_framework'] = params.get('id_acquisition_framework');
      }
      else if (params.get('id_dataset')) {
        initialFilter['id_dataset'] = params.get('id_dataset');
      } else {
        initialFilter = { limit: AppConfig.SYNTHESE.NB_LAST_OBS };
      }

      // reinitialize the form
      this._fs.searchForm.reset();
      this._fs.selectedCdRefFromTree = [];
      this._fs.selectedTaxonFromRankInput = [];
      this._fs.selectedtaxonFromComponent = [];
      this.loadAndStoreData(initialFilter);
    })

  }

  mooveButton() {
    this.searchBarHidden = !this.searchBarHidden;
  }

  closeInfo(infoAlert: HTMLElement) {
    infoAlert.hidden = true;
  }
}
