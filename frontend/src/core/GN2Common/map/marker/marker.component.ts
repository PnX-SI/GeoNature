import { Component, OnInit, Input, Output, EventEmitter } from '@angular/core';
import {Map, Marker} from 'leaflet';
import { MapService } from '../map.service';
import { MapUtils } from '../map.utils';
import * as L from 'leaflet';

@Component({
  selector: 'pnx-marker',
  templateUrl: 'marker.component.html'
})

export class MarkerComponent implements OnInit {
  public map: Map;
  public marker: Marker;
  public editingMarker = true;
  @Input() onclick: any;
  @Output() onMarkerChange = new EventEmitter<any>();
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
        if (this.marker !== undefined ) {
          this.marker.remove();
          this.marker = this._maputils.createMarker(e.latlng.lng, e.latlng.lat).addTo(this.map);
          this.markerMoveEvent(this.marker);
        } else {
          this.marker = this._maputils.createMarker(e.latlng.lng, e.latlng.lat).addTo(this.map);
          this.markerMoveEvent(this.marker);
        }
      // observable if map click
      this.onMarkerChange.emit(this.markerToGeojson(this.marker.getLatLng()));
      });
    }

  markerMoveEvent(marker: Marker) {
    marker.on('moveend', (event: MouseEvent) => {
      this.onMarkerChange.emit(this.markerToGeojson(this.marker.getLatLng()));
      });
  }

  toggleEditing() {
    this.editingMarker = !this.editingMarker;
    document.getElementById('markerLegend').style.backgroundColor = this.editingMarker ? '#c8c8cc' : 'white';
    if (!this.editingMarker) {
      // disable event
      this.map.off('click');
      this.marker.off('moveend');
      if ( this.marker !== undefined ) {
        this.map.removeLayer(this.marker);
      }
    } else {
      this.enableMarkerOnClick();
    }
  }

  markerToGeojson(latLng) {
    return {'geometry': {'type': 'Point', 'coordinates': [latLng.lng, latLng.lat]}};
  }

}
