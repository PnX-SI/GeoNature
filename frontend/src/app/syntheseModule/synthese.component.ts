import { Component, OnInit } from '@angular/core';
import { DataService } from './services/data.service';
import { MapListService } from '@geonature_common/map-list/map-list.service';
import { CommonService } from '@geonature_common/service/common.service';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { SyntheseFormService } from './services/form.service';
import { SyntheseStoreService } from './services/store.service';
import { SyntheseModalDownloadComponent } from './synthese-results/synthese-list/modal-download/modal-download.component';
import { AppConfig } from '@geonature_config/app.config';

@Component({
  selector: 'pnx-synthese',
  styleUrls: ['synthese.component.scss'],
  templateUrl: 'synthese.component.html'
})
export class SyntheseComponent implements OnInit {
  public searchBarHidden = false;
  public marginButton: number;

  constructor(
    public searchService: DataService,
    private _mapListService: MapListService,
    private _commonService: CommonService,
    private _modalService: NgbModal,
    private _fs: SyntheseFormService,
    private _syntheseStore: SyntheseStoreService
  ) {}

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
        if (error.status !== 403) {
          this._commonService.translateToaster('error', 'ErrorMessage');
        }
      }
    );
  }

  ngOnInit() {
    const initialFilter = { limit: AppConfig.SYNTHESE.NB_LAST_OBS };
    this.loadAndStoreData(initialFilter);
  }

  mooveButton() {
    this.searchBarHidden = !this.searchBarHidden;
  }
}
