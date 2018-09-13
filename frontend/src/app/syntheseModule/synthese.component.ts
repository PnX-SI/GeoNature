import { Component, OnInit, ViewChild, ElementRef } from '@angular/core';
import { DataService } from './services/data.service';
import { MapListService } from '@geonature_common/map-list/map-list.service';
import { CommonService } from '@geonature_common/service/common.service';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { SyntheseFormService } from './services/form.service';
import { SyntheseModalDownloadComponent } from './synthese-results/synthese-list/modal-download/modal-download.component';

@Component({
  selector: 'pnx-synthese',
  styleUrls: ['synthese.component.scss'],
  templateUrl: 'synthese.component.html'
})
export class SyntheseComponent implements OnInit {
  @ViewChild('toManyObsModal') toManyObsModal: ElementRef;
  constructor(
    public searchService: DataService,
    private _mapListService: MapListService,
    private _commonService: CommonService,
    private _modalService: NgbModal,
    private _fs: SyntheseFormService
  ) { }

  loadAndStoreData(formParams) {
    this.searchService.dataLoaded = false;
    this.searchService.getSyntheseData(formParams).subscribe(
      result => {
        console.log(result);
        if (result['nb_obs_limited']) {
          const modalRef = this._modalService.open(SyntheseModalDownloadComponent, {
            size: 'lg'
          });
          const formatedParams = this._fs.formatParams();
          modalRef.componentInstance.queryString = this.searchService.buildQueryUrl(formatedParams);
          modalRef.componentInstance.tooManyObs = true;
        }
        this._mapListService.geojsonData = result['data'];
        this._mapListService.loadTableData(result['data'], this.customColumns.bind(this));
        this._mapListService.idName = 'id_synthese';
        this.searchService.dataLoaded = true;
      },
      error => {
        this.searchService.dataLoaded = true;
        if (error.status === 403) {
          this._commonService.translateToaster('error', 'NotAllowed');
        } else {
          this._commonService.translateToaster('error', 'ErrorMessage');
        }
      }
    );
  }
  ngOnInit() {
    const initialData = { limit: 100 };
    this.loadAndStoreData(initialData);
  }

  formatDate(unformatedDate) {
    const date = new Date(unformatedDate);
    return date.toLocaleDateString('fr-FR');
  }

  customColumns(feature) {
    // function pass to the LoadTableData maplist service function to format date
    // on the table
    // must return a feature
    if (feature.properties.date_min) {
      feature.properties.date_min = this.formatDate(feature.properties.date_min);
    }
    if (feature.properties.date_max) {
      feature.properties.date_max = this.formatDate(feature.properties.date_max);
    }
    return feature;
  }
}
