import { Component, OnInit } from '@angular/core';
import {GeoJSON} from 'leaflet';
import { SearchService } from './search.service';
import { MapListService } from '../GN2Common/map-list/map-list.service';

@Component({
    selector: 'pnx-synthese',
    templateUrl: 'synthese.component.html',

})

export class SyntheseComponent implements OnInit {
    public syntheseData: GeoJSON;

    constructor(
        public searchService: SearchService,
        private _mapListService: MapListService
    ) {}


    ngOnInit() {
        this.searchService.getSyntheseData({}).subscribe(data => {
            this.syntheseData = data;
            this._mapListService.loadTableData(data);
            this._mapListService.idName = 'id_synthese';
        });
    }

}


