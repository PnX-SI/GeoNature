import { Component, Input, OnInit, ViewChild } from '@angular/core';
import { MapService } from './map.service';
import {NgbModal, NgbActiveModal} from '@ng-bootstrap/ng-bootstrap';
import {Map, LatLngExpression} from 'leaflet';
import { AppConfig } from '../../../conf/app.config';
import 'leaflet-draw';
import * as L from 'leaflet';

@Component({
  selector: 'pnx-map',
  templateUrl: './map.component.html',
  styleUrls: ['./map.component.scss']
})
export class MapComponent implements OnInit {
  @Input() baseMaps:any;
  @Input() center: Array<number>;
  @Input() zoom: number;
  searchLocation: string;
  constructor(public mapService: MapService, private modalService: NgbModal) {
    this.searchLocation = '';
  }

  ngOnInit() {
    const baseMaps = this.baseMaps || AppConfig.MAP.BASEMAP;
    const zoom = this.zoom || AppConfig.MAP.ZOOM_LEVEL;
    let center:LatLngExpression;
    if(this.center !== undefined){
       center = L.latLng(this.center[0],this.center[1])
    }else{
       center = L.latLng(AppConfig.MAP.CENTER[0], AppConfig.MAP.CENTER[1]);
    }
    
    const map = L.map('map', {
        zoomControl: false,
        center: center,
        zoom: zoom,
        layers: [baseMaps[0].layer]
    });
    L.control.zoom({ position: 'topright' }).addTo(map);
    const baseControl = {};
    AppConfig.MAP.BASEMAP.forEach((el)=>{
      baseControl[el.name] = el.layer
    })
    L.control.layers(baseControl).addTo(map);
    L.control.scale().addTo(map);

    this.mapService.setMap(map);
    this.mapService.initializeReleveFeatureGroup();
  }

    gotoLocation() {
      if (!this.searchLocation) { return; }
      this.mapService.search(this.searchLocation);
    }

}
