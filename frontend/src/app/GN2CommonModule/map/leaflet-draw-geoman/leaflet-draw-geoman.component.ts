import { Component, Input, OnInit, Output, EventEmitter } from '@angular/core';

import '@geoman-io/leaflet-geoman-free';
import * as L from 'leaflet';
import { AppConfig } from '@geonature_config/app.config';

import { CommonService } from '../../service/common.service';
import { MapService } from '../map.service';
import { map } from 'rxjs-compat/operator/map';

@Component({
  selector: 'pnx-leaflet-draw-geoman',
  templateUrl: 'leaflet-draw-geoman.component.html',
})
export class LeafletDrawGeomanComponent implements OnInit {
  public defaultOptions = {
    drawMarker: false,
    dragMode: false,
    cutPolygon: false,
    rotateMode: false,
    drawCircleMarker: false,
  };
  @Input() options = this.defaultOptions;
  @Input() zoomLevel = AppConfig.MAPCONFIG.ZOOM_LEVEL_RELEVE;
  /** Niveau de zoom à partir du quel on peut dessiner sur la carte */
  @Output() layerDrawed = new EventEmitter<any>();
  @Output() layerDeleted = new EventEmitter<any>();
  constructor(public mapService: MapService, private _commonService: CommonService) {}

  ngOnInit() {
    console.log(this.mapService.leafletDrawFeatureGroup);
    this.mapService.geomanLayerGroup = new L.LayerGroup();
    this.mapService.map.addLayer(this.mapService.geomanLayerGroup);

    // disable to attach all layer to geoman
    L.PM.setOptIn(false);
    const drawOptions = {
      layerGroup: this.mapService.geomanLayerGroup,
      pinning: true,
      snappable: false,
      snappingOrder: ['Marker', 'CircleMarker', 'Circle', 'Line', 'Polygon', 'Rectangle'],
      panes: { vertexPane: 'markerPane', layerPane: 'overlayPane', markerPane: 'markerPane' },
    };
    this.mapService.map.pm.setGlobalOptions(drawOptions);
    this.mapService.map.pm.addControls(this.defaultOptions);
    this.mapService.map.pm.enableGlobalEditMode();

    this.mapService.map.on('pm:drawstart', (layer) => {
      this.mapService.geomanLayerGroup.clearLayers();
      if (!this.mapService.fileLayerEditionMode) {
        this.mapService.fileLayerFeatureGroup.clearLayers();
      }
      // // remove the current marker
      const markerLegend = document.getElementById('markerLegend');
      if (markerLegend) {
        markerLegend.style.backgroundColor = 'white';
      }
      this.mapService.editingMarker = false;
      // TODO : le click est utilisé par la lib
      //this.mapService.map.off('click');
      if (this.mapService.marker) {
        this.mapService.map.removeLayer(this.mapService.marker);
      }
      if (this.mapService.map.getZoom() < this.zoomLevel) {
        this._commonService.translateToaster('warning', 'Map.ZoomWarning');
      }
    });

    this.mapService.map.on('pm:create', (e: any) => {
      if (this.mapService.map.getZoom() < this.zoomLevel) {
        // this._commonService.translateToaster('warning', 'Map.ZoomWarning');
        this.mapService.geomanLayerGroup.clearLayers();
        this.layerDrawed.emit(null);
        return;
      }
      const featureCollection = this.mapService.geomanLayerGroup.toGeoJSON();
      const geojson = (featureCollection as any).features[0];
      if (e.layer && e.layer instanceof L.Circle) {
        geojson.properties.radius = e.layer.getRadius();
      }
      this.layerDrawed.emit(geojson);

      e.layer.on('pm:edit', (e: any) => {
        console.log(e);
      });
    });
  }
}
