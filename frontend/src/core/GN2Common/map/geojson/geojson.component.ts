import { Component, OnInit, Input, OnChanges } from '@angular/core';
import {Map} from 'leaflet';
import { MapService } from '../map.service';
import { MapListService } from '../../map-list/map-list.service';
import * as L from 'leaflet';

@Component({
  selector: 'pnx-geojson',
  templateUrl: 'geojson.component.html'
})

export class GeojsonComponent implements OnInit, OnChanges {
  public map: Map;
  public currentGeojson: any;
  public layerGroup: any;
  @Input() geojson: any;
  @Input() onEachFeature: any;
  @Input() style: any;
  constructor(public mapservice: MapService) { }

  ngOnInit() {
    this.map = this.mapservice.map;
  }

   loadGeojson(geojson) {
    this.currentGeojson = this.mapservice.createGeojson(geojson, this.onEachFeature);
    this.currentGeojson.id = 'mygeojson';
    this.mapservice.layerGroup = new L.LayerGroup();
    this.mapservice.map.addLayer(this.mapservice.layerGroup);
    this.mapservice.layerGroup.addLayer(this.currentGeojson);
   }

   ngOnChanges(changes) {
    if (changes.geojson && changes.geojson.currentValue !== undefined) {
      if (this.currentGeojson !== undefined) {
        this.mapservice.map.removeLayer(this.currentGeojson);
      }
      this.loadGeojson(changes.geojson.currentValue);
    }
   }
}
