import { Component, OnInit, Input, Output, EventEmitter, OnChanges } from '@angular/core';
import { Map, GeoJSON } from 'leaflet';
import { MapService } from '../map.service';
import { AppConfig } from '@geonature_config/app.config';
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
  // save the current layer type because the edite event do not send it...
  public currentLayerType: string;
  // coordinates of the entity to draw
  @Input() geojson: GeoJSON;
  @Input() options = leafletDrawOption;
  @Input() zoomLevel = AppConfig.MAPCONFIG.ZOOM_LEVEL_RELEVE;
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
    this.options.edit['featureGroup'] = this.mapservice.leafletDrawFeatureGroup;
    const drawControl = new this._Le.Control.Draw(this.options);
    this.map.addControl(drawControl);

    this.map.on(this._Le.Draw.Event.DRAWSTART, e => {
      this.mapservice.removeAllLayers(this.map, this.mapservice.fileLayerFeatureGroup);
      if (this.map.getZoom() < this.zoomLevel) {
        this._commonService.translateToaster('warning', 'Map.ZoomWarning');
      }
      // remove eventual filelayer layers
      if (this.mapservice.fileLayerFeatureGroup) {
        // delete only if fileLayerEditionMode = false
        // if true we let the filelayer layer to draw it
        if (!this.mapservice.fileLayerEditionMode) {
          this.mapservice.removeAllLayers(this.map, this.mapservice.fileLayerFeatureGroup);
        }
      }
      // remove the current draw
      if (this._currentDraw !== null) {
        this.mapservice.removeAllLayers(this.map, this.mapservice.leafletDrawFeatureGroup);
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
        this._currentDraw = (e as any).layer.setStyle(this.mapservice.searchStyle);
        this.currentLayerType = (e as any).layerType;
        this.mapservice.leafletDrawFeatureGroup.addLayer(this._currentDraw);
        const geojson = this.getGeojsonFromFeatureGroup(this.currentLayerType);
        this.mapservice.justLoaded = false;
        this.layerDrawed.emit(geojson);
      }
    });

    // on draw edited
    this.mapservice.map.on(this._Le.Draw.Event.EDITED, e => {
      // output
      this.mapservice.justLoaded = false;

      const geojson = this.getGeojsonFromFeatureGroup(this.currentLayerType);
      if (geojson) {
        this.layerDrawed.emit(geojson);
      }
      this.layerDrawed.emit(geojson);
    });

    // on layer deleted
    this.map.on(this._Le.Draw.Event.DELETESTART, e => {
      this.layerDeleted.emit();
    });

    this.map.on(this._Le.Draw.Event.DELETESTOP, e => {
      const geojson = this.getGeojsonFromFeatureGroup(this.currentLayerType);
      if (geojson) {
        this.layerDrawed.emit(geojson);
      }
    });
  }

  getGeojsonFromFeatureGroup(layerType) {
    let geojson: any = this.mapservice.leafletDrawFeatureGroup.toGeoJSON();
    geojson = geojson.features[0];

    if (layerType === 'circle') {
      const radius = this._currentDraw.getRadius();
      geojson.properties.radius = radius;
    }
    return geojson;
  }

  loadDrawfromGeoJson(geojson) {
    let layer;
    if (geojson.type === 'LineString') {
      const myLatLong = geojson.coordinates.map(point => {
        return L.latLng(point[1], point[0]);
      });
      layer = L.polyline(myLatLong);
      this.mapservice.leafletDrawFeatureGroup.addLayer(layer);
    }
    if (geojson.type === 'Polygon') {
      const myLatLong = geojson.coordinates[0].map(point => {
        return L.latLng(point[1], point[0]);
      });
      layer = L.polygon(myLatLong);
      this.mapservice.leafletDrawFeatureGroup.addLayer(layer);
    }
    this.mapservice.map.fitBounds(layer.getBounds());
    // disable point event on the map
    this.mapservice.setEditingMarker(false);
    // send observable
    let new_geojson = this.mapservice.leafletDrawFeatureGroup.toGeoJSON();
    new_geojson = (new_geojson as any).features[0];
    this.mapservice.setGeojsonCoord(new_geojson);
  }

  ngOnChanges(changes) {
    if (changes.geojson && changes.geojson.currentValue) {
      this.loadDrawfromGeoJson(changes.geojson.currentValue);
    }
  }
}
