import { Component, OnInit, Input, Output, EventEmitter } from '@angular/core';
import {Map, Marker} from 'leaflet';
import { MapService } from '../map.service';
import { AppConfig } from '../../../../conf/app.config';
import * as L from 'leaflet';

@Component({
  selector: 'pnx-marker',
  templateUrl: 'marker.component.html'
})

export class MarkerComponent implements OnInit {
  public map: Map;
  public editingMarker = true;
  @Output() markerChanged = new EventEmitter<any>();
  constructor(public mapservice: MapService) { }

  ngOnInit() {
    this.map = this.mapservice.map;
    this.setMarkerLegend();
    this.enableMarkerOnClick();

    this.mapservice.isMarkerEditing$
      .subscribe(isEditing => {
        this.toggleEditing();
      });
   }

   setMarkerLegend() {
    // Marker
    const MarkerLegend = this.mapservice.addCustomLegend('topleft', 'markerLegend', 'url(assets/images/location-pointer.png)');
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
      } else {
        this.generateMarkerAndEvent(e.latlng.lng, e.latlng.lat);
      }
      });
    }
  generateMarkerAndEvent(x, y) {
    if (this.mapservice.marker !== undefined ) {
      this.mapservice.marker.remove();
      this.mapservice.marker = this.mapservice.createMarker(x,y).addTo(this.map);
      this.markerMoveEvent(this.mapservice.marker);
    } else {
      this.mapservice.marker = this.mapservice.createMarker(x, y).addTo(this.map);
      this.markerMoveEvent(this.mapservice.marker);
    }
    // observable if map click
    this.markerChanged.emit(this.markerToGeojson(this.mapservice.marker.getLatLng())); 
  }

  markerMoveEvent(marker: Marker) {
    marker.on('moveend', (event: MouseEvent) => {
      if (this.map.getZoom() < AppConfig.MAP.ZOOM_LEVEL_RELEVE) {
        this.mapservice.sendWarningMessage();
      } else {
        this.markerChanged.emit(this.markerToGeojson(this.mapservice.marker.getLatLng()));
      }
    });
  }

  toggleEditing() {
    this.editingMarker = !this.editingMarker;
    document.getElementById('markerLegend').style.backgroundColor = this.editingMarker ? '#c8c8cc' : 'white';
    if (!this.editingMarker) {
      // disable event
      this.mapservice.map.off('click');
      if ( this.mapservice.marker !== undefined ) {
        this.mapservice.marker.off('moveend');
        this.map.removeLayer(this.mapservice.marker);
      }
    } else {
      this.mapservice.removeAllLayers(this.map, this.mapservice.releveFeatureGroup);
      this.enableMarkerOnClick();
    }
  }

  markerToGeojson(latLng) {
    return {'geometry': {'type': 'Point', 'coordinates': [latLng.lng, latLng.lat]}};
  }

}
