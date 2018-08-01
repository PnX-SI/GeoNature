import { Component, OnInit } from '@angular/core';
import { GeoJSON } from 'leaflet';
import { DataService } from './services/data.service';
import { MapListService } from '@geonature_common/map-list/map-list.service';

@Component({
  selector: 'pnx-synthese',
  styleUrls: ['synthese.component.scss'],
  templateUrl: 'synthese.component.html'
})
export class SyntheseComponent implements OnInit {
  constructor(public searchService: DataService, private _mapListService: MapListService) {}

  loadAndStoreData(formParams) {
    this.searchService.dataLoaded = false;
    this.searchService.getSyntheseData(formParams).subscribe(data => {
      this._mapListService.geojsonData = data;
      this._mapListService.loadTableData(data);
      this._mapListService.idName = 'id_synthese';
      this.searchService.dataLoaded = true;
    });
  }
  ngOnInit() {
    const initialData = { limit: 100 };
    this.loadAndStoreData(initialData);
  }
}
