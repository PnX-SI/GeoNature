import { Component, OnInit, Input, ViewChild } from '@angular/core';
import { GeoJSON } from 'leaflet';
import { MapListService } from '@geonature_common/map-list/map-list.service';
import { SYNTHESE_CONFIG } from '../../synthese.config';
import { SearchService } from '../../search.service';


@Component({
    selector: 'pnx-synthese-list',
    templateUrl: 'synthese-list.component.html',
    styleUrls: ['synthese-list.component.scss']
})

export class SyntheseListComponent implements OnInit {
    public SYNTHESE_CONFIG = SYNTHESE_CONFIG;
    @ViewChild('table') table: any;
    @Input() inputSyntheseData: GeoJSON;
    constructor(
        public mapListService: MapListService,
        public searchService: SearchService
    ) { }

    ngOnInit() { }

    toggleExpandRow(row) {
        // console.log('Toggled Expand Row!', row);
        this.table.rowDetail.toggleExpandRow(row);
    }
}
