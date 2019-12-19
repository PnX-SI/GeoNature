import { Component, OnInit, OnChanges, Input } from '@angular/core';
import { MapService } from '../map.service';
import * as L from 'leaflet';

@Component({
  selector: 'pnx-map-overlays',
  template: ''
})
export class MapOverLaysComponent implements OnInit, OnChanges {
  /** List de geojson à ajouter à la carte */
  @Input() layers: Array<any>;
  constructor(private _mapService: MapService) {}

  ngOnInit() {}

  ngOnChanges(changes) {
    if (changes.layers && changes.layers.currentValue) {
      changes.layers.currentValue.forEach(layer => {
        const geojsonLayer = L.geoJSON(layer.geojson);
        this._mapService.layerControl.addOverlay(geojsonLayer, layer.layerName);
      });
    }
  }
}
