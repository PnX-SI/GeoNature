import { Component, OnInit, Input, Output, EventEmitter, OnChanges } from '@angular/core';
import { Map, FeatureGroup, GeoJSON } from 'leaflet';
import { MapService } from '../map.service';
import { MAP_CONFIG } from '../../../../conf/map.config';
import { CommonService } from '../../service/common.service';
import { leafletDrawOption } from '@geonature_common/map/leaflet-draw.options';

import 'leaflet-draw';
import * as L from 'leaflet';

@Component({
  selector: 'pnx-leaflet-draw',
  templateUrl: 'leaflet-draw.component.html'
})
export class LeafletDrawComponent implements OnInit, OnChanges {
  public map: Map;
  private _currentDraw: any;
  private _Le: any;
  public drawnItems: any;
  // coordinates of the entity to draw
  @Input() geojson: GeoJSON;
  @Input() options = leafletDrawOption;
  @Input() zoomLevel = MAP_CONFIG.ZOOM_LEVEL_RELEVE;
  @Output() layerDrawed = new EventEmitter<any>();
  @Output() layerDeleted = new EventEmitter<any>();

  constructor(public mapservice: MapService, private _commonService: CommonService) {}

  ngOnInit() {
    this.map = this.mapservice.map;
    this._Le = L as any;
    this.enableLeafletDraw();
  }

  enableLeafletDraw() {
    this.options.edit['featureGroup'] = this.drawnItems;
    this.options.edit['featureGroup'] = this.mapservice.releveFeatureGroup;
    const drawControl = new this._Le.Control.Draw(this.options);
    this.map.addControl(drawControl);

    this.map.on(this._Le.Draw.Event.DRAWSTART, e => {
      if (this.map.getZoom() < this.zoomLevel) {
        this._commonService.translateToaster('warning', 'Map.ZoomWarning');
      }
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
        this.layerDrawed.emit({ geojson: null });
      } else {
        this._currentDraw = (e as any).layer.setStyle(this.mapservice.selectedStyle);
        const layerType = (e as any).layerType;
        this.mapservice.releveFeatureGroup.addLayer(this._currentDraw);
        let geojson: any = this.mapservice.releveFeatureGroup.toGeoJSON();

        geojson = geojson.features[0];
        // output
        if (layerType === 'circle') {
          const radius = this._currentDraw.getRadius();
          geojson.properties.radius = radius;
        }
        this.mapservice.justLoaded = false;
        this.layerDrawed.emit(geojson);
      }
    });

    // on draw edited
    this.mapservice.map.on('draw:edited', e => {
      let geojson = this.mapservice.releveFeatureGroup.toGeoJSON();
      geojson = (geojson as any).features[0];
      // output
      this.mapservice.justLoaded = false;
      this.layerDrawed.emit(geojson);
    });

    // on layer deleted
    this.map.on(this._Le.Draw.Event.DELETED, e => {
      this.layerDeleted.emit();
    });
  }

  loadDrawfromGeoJson(geojson) {
    let layer;
    if (geojson.type === 'LineString') {
      const myLatLong = geojson.coordinates.map(point => {
        return L.latLng(point[1], point[0]);
      });
      layer = L.polyline(myLatLong);
      this.mapservice.releveFeatureGroup.addLayer(layer);
    }
    if (geojson.type === 'Polygon') {
      const myLatLong = geojson.coordinates[0].map(point => {
        return L.latLng(point[1], point[0]);
      });
      layer = L.polygon(myLatLong);
      this.mapservice.releveFeatureGroup.addLayer(layer);
    }
    this.mapservice.map.fitBounds(layer.getBounds());
    // disable point event on the map
    this.mapservice.setEditingMarker(false);
    // send observable
    let new_geojson = this.mapservice.releveFeatureGroup.toGeoJSON();
    new_geojson = (new_geojson as any).features[0];
    this.mapservice.setGeojsonCoord(new_geojson);
  }

  ngOnChanges(changes) {
    if (changes.geojson && changes.geojson.currentValue) {
      this.loadDrawfromGeoJson(changes.geojson.currentValue);
    }
  }
}
