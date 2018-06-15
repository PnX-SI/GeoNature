import { Component, OnInit, Input, Output, EventEmitter } from '@angular/core';
import { Map, FeatureGroup } from 'leaflet';
import { MapService } from '../map.service';
import { MAP_CONFIG } from '../../../../conf/map.config';
import { CommonService } from '../../service/common.service';

import 'leaflet-draw';
import * as L from 'leaflet';

@Component({
  selector: 'pnx-leaflet-draw',
  templateUrl: 'leaflet-draw.component.html'
})
export class LeafletDrawComponent implements OnInit {
  public map: Map;
  private _currentDraw: any;
  private _Le: any;
  public drawnItems: any;
  @Input() options: any;
  @Input() zoomLevel: number;
  @Output() layerDrawed = new EventEmitter<any>();

  constructor(public mapservice: MapService, private _commonService: CommonService) {}

  ngOnInit() {
    this.map = this.mapservice.map;
    this.zoomLevel = this.zoomLevel || MAP_CONFIG.ZOOM_LEVEL_RELEVE;
    this._Le = L as any;
    this.enableLeafletDraw();
  }

  enableLeafletDraw() {
    this.options.edit['featureGroup'] = this.drawnItems;
    this.options.edit['featureGroup'] = this.mapservice.releveFeatureGroup;
    const drawControl = new this._Le.Control.Draw(this.options);
    this.map.addControl(drawControl);

    this.map.on(this._Le.Draw.Event.DRAWSTART, e => {
      // remove the current draw
      if (this._currentDraw !== null) {
        this.mapservice.removeAllLayers(this.map, this.mapservice.releveFeatureGroup);
      }
      // remove the current marker
      const markerLegend = document.getElementById('markerLegend');
      if (markerLegend) {
        markerLegend.style.backgroundColor = 'white';
      }
      this.mapservice.editingMarker = false;
      this.map.off('click');
      if (this.mapservice.marker) {
        this.map.removeLayer(this.mapservice.marker);
      }
    });

    // on draw layer created
    this.map.on(this._Le.Draw.Event.CREATED, e => {
      if (this.map.getZoom() < this.zoomLevel) {
        this._commonService.translateToaster('warning', 'Map.ZoomWarning');
      } else {
        this._currentDraw = (e as any).layer;
        const layerType = (e as any).layerType;
        const latlngTab = this._currentDraw._latlngs;
        this.mapservice.releveFeatureGroup.addLayer(this._currentDraw);
        let geojson = this.mapservice.releveFeatureGroup.toGeoJSON();
        geojson = (geojson as any).features[0];
        // output
        this.layerDrawed.emit(geojson);
      }
    });

    // on draw edited
    this.mapservice.map.on('draw:edited', e => {
      let geojson = this.mapservice.releveFeatureGroup.toGeoJSON();
      geojson = (geojson as any).features[0];
      // output
      this.layerDrawed.emit(geojson);
    });
  }
}
