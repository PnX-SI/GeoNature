import { Component, OnInit, OnChanges, ViewChild, ElementRef } from '@angular/core';
import { Map } from 'leaflet';
import { MapService } from '../map.service';
import { MapListService } from '../../map-list/map-list.service';
import { AppConfig } from '@geonature_config/app.config';
import { CommonService } from '../../service/common.service';
import { LocateControl }  from '@librairies/leaflet-locatecontrol';
import * as L from 'leaflet';
import 'leaflet-locatecontrol';

@Component({
  selector: 'pnx-geolocation-button',
  templateUrl: 'geolocation.component.html'
})
export class GeolocationComponent implements OnInit, control {
  @ViewChild('map') public mapElement: ElementRef;
  map: L.Map;

  constructor(
    public mapservice: MapService,
    public commonService: CommonService,
    private _mapListServive: MapListService
  ) {
  }

  ngOnInit() {
    this.map = this.mapservice.map;
    this.setMarkerGeolocation();
  }

  setMarkerGeolocation() {
    // Defaults
    L.control.locate().addTo(this.map);

    // Locate Control
    var lc = L.control.locate({
      position: 'topleft',
      drawCircle: true,
      follow: true,
      setView: true,
      keepCurrentZoomLevel: false,
      markerStyle: {
        weight: 1,
        opacity: 0.8,
        fillOpacity: 0.8
      },
      circleStyle: {
        weight: 1,
        clickable: false
      },
      icon: 'fa fa-location-arrow',
      metric: true,
      strings: {
        title: 'Show me where I am',
        popup: 'You are within {distance} {unit} from this point',
        outsideMapBoundsMsg: 'You seem located outside the boundaries of the map'
      },
      locateOptions: {
        maxZoom: 18,
        watch: true,
        enableHighAccuracy: true,
        maximumAge: 10000,
        timeout: 10000
      }
    }).addTo(this.map);
  }

  ngAfterViewInit() {
    this.map = L.map(this.mapElement.nativeElement).setView([47.21837, -1.55362], 13); // initialisation de la carte
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: 'OpenStreetMap'
    }).addTo(this.map);
  }
}
