import { Component, Input, OnInit } from '@angular/core';
import { MapService } from './map.service';
import {Map} from 'leaflet';
import 'leaflet-draw';
import * as L from 'leaflet';


@Component({
  selector: 'pnx-map',
  templateUrl: './map.component.html',
  styleUrls: ['./map.component.scss']
})
export class MapComponent implements OnInit {
  @Input()editable: any;
  public map: Map;
  public Le: any;
  searchLocation: string;
  constructor(public mapService: MapService) {
    this.searchLocation = '';
    this.Le = L as any;
  }

  ngOnInit() {
    this.mapService.initialize();
    this.map = this.mapService.map;
    if (this.editable !== undefined){
      this.mapService.enableMarkerOnClick();
      this.mapService.enableEditMap();
    }


  }

    gotoLocation() {
        if (!this.searchLocation) { return; }
        this.mapService.search(this.searchLocation);
    }

}
