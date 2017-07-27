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

  constructor(public mapService: MapService) { }

  ngOnInit() {
    this.mapService.initialize();
    this.map = this.mapService.map;
  }

}
