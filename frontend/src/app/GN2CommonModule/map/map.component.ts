import { Component, Input, OnInit, ViewChild, OnChanges } from '@angular/core';
import { MapService } from './map.service';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { Map, LatLngExpression } from 'leaflet';
import { AppConfig } from '@geonature_config/app.config';
import * as L from 'leaflet';

import 'leaflet-draw';
@Component({
  selector: 'pnx-map',
  templateUrl: './map.component.html',
  styleUrls: ['./map.component.scss']
})
export class MapComponent implements OnInit {
  @Input() baseMaps: any;
  @Input() center: Array<number>;
  @Input() zoom: number;
  @Input() height: string;
  searchLocation: string;
  public map: Map;
  constructor(private mapService: MapService, private modalService: NgbModal) {
    this.searchLocation = '';
  }

  ngOnInit() {
    this.initialize();
  }

  gotoLocation() {
    if (!this.searchLocation) {
      return;
    }
    this.mapService.search(this.searchLocation);
  }

  initialize() {
    const zoom = this.zoom || AppConfig.MAPCONFIG.ZOOM_LEVEL;
    let center: LatLngExpression;
    if (this.center !== undefined) {
      center = L.latLng(this.center[0], this.center[1]);
    } else {
      center = L.latLng(AppConfig.MAPCONFIG.CENTER[0], AppConfig.MAPCONFIG.CENTER[1]);
    }

    const map = L.map('map', {
      zoomControl: false,
      center: center,
      zoom: zoom,
      preferCanvas: true
    });
    this.map = map;
    (map as any)._onResize();

    L.control.zoom({ position: 'topright' }).addTo(map);
    const baseControl = {};
    AppConfig.MAPCONFIG.BASEMAP.forEach((basemap, index) => {
      const configObj = (basemap as any).subdomains
        ? { attribution: basemap.attribution, subdomains: (basemap as any).subdomains }
        : { attribution: basemap.attribution };
      baseControl[basemap.name] = L.tileLayer(basemap.layer, configObj);
      if (index === 0) {
        map.addLayer(baseControl[basemap.name]);
      }
    });
    L.control.layers(baseControl).addTo(map);
    L.control.scale().addTo(map);

    this.mapService.setMap(map);
    this.mapService.initializeLeafletDrawFeatureGroup();
  }
}
