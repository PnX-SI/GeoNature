import { Component, Input, OnInit, ViewChild, OnChanges } from '@angular/core';
import { MapService } from './map.service';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { Map, LatLngExpression } from 'leaflet';
import { MAP_CONFIG } from '../../../conf/map.config';
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
    const baseMaps = this.baseMaps || MAP_CONFIG.BASEMAP;
    const zoom = this.zoom || MAP_CONFIG.ZOOM_LEVEL;
    let center: LatLngExpression;
    if (this.center !== undefined) {
      center = L.latLng(this.center[0], this.center[1]);
    } else {
      center = L.latLng(MAP_CONFIG.CENTER[0], MAP_CONFIG.CENTER[1]);
    }

    const map = L.map('map', {
      zoomControl: false,
      center: center,
      zoom: zoom
    });
    this.map = map;
    (map as any)._onResize();

    // (L.Control as any)
    //   .fileLayerLoad({
    //     // Allows you to use a customized version of L.geoJson.
    //     // For example if you are using the Proj4Leaflet leaflet plugin,
    //     // you can pass L.Proj.geoJson and load the files into the
    //     // L.Proj.GeoJson instead of the L.geoJson.
    //     layer: (L as any).geoJson,
    //     // See http://leafletjs.com/reference.html#geojson-options
    //     layerOptions: { style: { color: 'red' } },
    //     // Add to map after loading (default: true) ?
    //     addToMap: true,
    //     // File size limit in kb (default: 1024) ?
    //     fileSizeLimit: 1024,
    //     // Restrict accepted file formats (default: .geojson, .json, .kml, and .gpx) ?
    //     formats: ['.geojson', '.kml']
    //   })
    //   .addTo(this.map);

    L.control.zoom({ position: 'topright' }).addTo(map);
    const baseControl = {};
    MAP_CONFIG.BASEMAP.forEach((basemap, index) => {
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
    this.mapService.initializeReleveFeatureGroup();
  }
}
