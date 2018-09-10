import { Component, OnInit } from '@angular/core';
import { DataService } from './services/data.service';
import { MapListService } from '@geonature_common/map-list/map-list.service';
import { CommonService } from '@geonature_common/service/common.service';

@Component({
  selector: 'pnx-synthese',
  styleUrls: ['synthese.component.scss'],
  templateUrl: 'synthese.component.html'
})
export class SyntheseComponent implements OnInit {
  constructor(
    public searchService: DataService,
    private _mapListService: MapListService,
    private _commonService: CommonService
  ) {}

  loadAndStoreData(formParams) {
    this.searchService.dataLoaded = false;
    this.searchService.getSyntheseData(formParams).subscribe(
      data => {
        this._mapListService.geojsonData = data;
        this._mapListService.loadTableData(data, this.customColumns.bind(this));
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
