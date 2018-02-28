import { Component, OnInit, Input } from '@angular/core';
import { GeoJSON } from 'leaflet';
import { MapListService } from '@geonature_common/map-list/map-list.service';


@Component({
    selector: 'pnx-synthese-list',
    templateUrl: 'synthese-list.component.html',
    styleUrls: ['synthese-list.component.scss']
})

export class SyntheseListComponent implements OnInit {
    @Input() inputSyntheseData: GeoJSON;
    constructor(public mapListService: MapListService) { }

    ngOnInit() { }
}