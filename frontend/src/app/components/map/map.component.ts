import { Component, OnInit } from '@angular/core';
import { MapService } from '../../services/map.service';
import {Map} from 'leaflet';

@Component({
  selector: 'app-map',
  templateUrl: './map.component.html',
  styleUrls: ['./map.component.scss']
})
export class MapComponent implements OnInit {
  public map: Map;
  searchLocation: string;
  constructor(public mapService: MapService) {
    this.mapService.editing = false;
    this.mapService.removing = false;
    this.searchLocation = '';
  }

  ngOnInit() {
    this.mapService.initialize();
    this.mapService.onMapClick();
    this.map = this.mapService.map;
  }

    gotoLocation() {
        if (!this.searchLocation) { return; }
        this.mapService.search(this.searchLocation);
    }

}
