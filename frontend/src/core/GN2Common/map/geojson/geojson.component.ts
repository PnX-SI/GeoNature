import { Component, OnInit, Input, OnChanges } from '@angular/core';
import {Map} from 'leaflet';
import { MapService } from '../map.service';
import * as L from 'leaflet';

@Component({
  selector: 'pnx-geojson',
  templateUrl: 'geojson.component.html'
})

export class GeojsonComponent implements OnInit, OnChanges {
  public map: Map;
  public currentGeojson: any;
  @Input() geojson: any;
  @Input() onEachFeature: any;
  @Input() style: any;
  constructor(public mapservice: MapService) { }

  ngOnInit() {
    this.map = this.mapservice.map;
  }

   loadGeojson(geojson) {
    this.currentGeojson = L.geoJSON(geojson, {
      pointToLayer: function (feature, latlng) {
        return L.circleMarker(latlng);
      },
      style: this.style,
      onEachFeature: this.onEachFeature
    });
    this.currentGeojson.addTo(this.map);
   }

   ngOnChanges(changes) {
    if (changes.geojson && changes.geojson.currentValue !== undefined) {
      if (this.currentGeojson !== undefined) {
        this.map.removeLayer(this.currentGeojson);
      }
      this.loadGeojson(changes.geojson.currentValue);
    }
   }
}
