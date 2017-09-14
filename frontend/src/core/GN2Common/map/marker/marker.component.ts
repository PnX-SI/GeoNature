import { Component, OnInit, Input, Output, EventEmitter } from '@angular/core';
import {Map, Marker} from 'leaflet';
import { MapService } from '../map.service';
import { MapUtils } from '../map.utils';
import { AppConfig } from '../../../../conf/app.config';
import * as L from 'leaflet';

@Component({
  selector: 'pnx-marker',
  templateUrl: 'marker.component.html'
})

export class MarkerComponent implements OnInit {
  public map: Map;
  public editingMarker = true;
  @Input() onclick: any;
  @Output() markerChanged = new EventEmitter<any>();
  constructor(public mapservice: MapService, private _maputils: MapUtils) { }

  ngOnInit() {
    this.map = this.mapservice.map;
    this.setMarkerLegend();
    this.enableMarkerOnClick();
   }

   setMarkerLegend() {
    // Marker
    const MarkerLegend = this._maputils.addCustomLegend('topleft', 'markerLegend', 'url(assets/images/location-pointer.png)');
    this.map.addControl(new MarkerLegend());
    // custom the marker
    document.getElementById('markerLegend').style.backgroundColor = '#c8c8cc';
    L.DomEvent.disableClickPropagation(document.getElementById('markerLegend'));
    document.getElementById('markerLegend').onclick = () => {
      this.toggleEditing();
    };
  }

  enableMarkerOnClick() {
    this.map.on('click', (e: any) => {
      // check zoom level
      if (this.map.getZoom() < AppConfig.MAP.ZOOM_LEVEL_RELEVE) {
        this.mapservice.sendWarningMessage();
      } else{
        if (this.mapservice.marker !== undefined ) {
          this.mapservice.marker.remove();
          this.mapservice.marker = this._maputils.createMarker(e.latlng.lng, e.latlng.lat).addTo(this.map);
          this.markerMoveEvent(this.mapservice.marker);      
        } else {
          this.mapservice.marker = this._maputils.createMarker(e.latlng.lng, e.latlng.lat).addTo(this.map);
          this.markerMoveEvent(this.mapservice.marker);
        }
        // observable if map click
        this.markerChanged.emit(this.markerToGeojson(this.mapservice.marker.getLatLng())); 
        }
      });
    }

  markerMoveEvent(marker: Marker) {
    marker.on('moveend', (event: MouseEvent) => {
      this.markerChanged.emit(this.markerToGeojson(this.mapservice.marker.getLatLng()));
      });
  }

  toggleEditing() {
    this.mapservice.editingMarker = !this.mapservice.editingMarker;
    document.getElementById('markerLegend').style.backgroundColor = this.editingMarker ? '#c8c8cc' : 'white';
    if (!this.editingMarker) {
      // disable event
      this.map.off('click');
      this.mapservice.marker.off('moveend');
      if ( this.mapservice.marker !== undefined ) {
        this.map.removeLayer(this.mapservice.marker);
      }
    } else {
      this._maputils.removeAllLayers(this.map, this.mapservice.releveFeatureGroup);
      this.enableMarkerOnClick();
    }
  }

  markerToGeojson(latLng) {
    return {'geometry': {'type': 'Point', 'coordinates': [latLng.lng, latLng.lat]}};
  }

}
