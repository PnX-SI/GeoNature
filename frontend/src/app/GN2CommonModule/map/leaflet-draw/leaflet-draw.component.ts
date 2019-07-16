import { Component, OnInit, Input, Output, EventEmitter, OnChanges } from '@angular/core';
import { Map } from 'leaflet';
import { MapService } from '../map.service';
import { AppConfig } from '@geonature_config/app.config';
import { CommonService } from '../../service/common.service';
import { leafletDrawOption } from '@geonature_common/map/leaflet-draw.options';
import { GeoJSON } from 'togeojson';

import 'leaflet-draw';
import * as L from 'leaflet';

/**
 * Ce composant permet d'activer le `plugin leaflet-draw <https://github.com/Leaflet/Leaflet.draw>`_
 */
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
  /** Coordonnées de l'entité à dessiner */
  @Input() geojson: GeoJSON;
  /**
   *  Objet permettant de paramettrer le plugin et les différentes formes dessinables (point, ligne, cercle etc...)
   *
   * Par défault le fichier ``leaflet-draw.option.ts`` est passé au composant. Il est possible de surcharger l'objet pour activer/désactiver certaines formes. Voir `exemple <https://github.com/PnX-SI/GeoNature/blob/develop/frontend/src/modules/occtax/occtax-map-form/occtax-map-form.component.ts#L27>`_
   */
  @Input() options = leafletDrawOption;
  @Input() zoomLevel = AppConfig.MAPCONFIG.ZOOM_LEVEL_RELEVE;
  /** Niveau de zoom à partir du quel on peut dessiner sur la carte */
  @Output() layerDrawed = new EventEmitter<GeoJSON>();
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
        // set firLayerFromMap = false because we just draw a layer
        // the boolean change MUST be before the output fire (emit)
        this.mapservice.firstLayerFromMap = false;
        this.layerDrawed.emit(geojson);
      }
    });

    // on draw edited
    this.mapservice.map.on(this._Le.Draw.Event.EDITED, e => {
      // output
      const geojson = this.getGeojsonFromFeatureGroup(this.currentLayerType);
      // set firLayerFromMap = false because we just edit a layer
      // the boolean change MUST be before the output fire (emit)
      this.mapservice.firstLayerFromMap = false;
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

  // else if (geojson.type == 'Polygon' || geojson.type == 'MultiPolygon') {
  //   const latLng = L.GeoJSON.coordsToLatLngs(
  //     geojson.coordinates,
  //     geojson.type === 'Polygon' ? 1 : 2
  //   );
  //   this.setStyleEventAndAdd(new L.Polygon(latLng), geojson.properties.id);
  // } else if (geojson.type == 'LineString' || geojson.type == 'MultiLineString') {
  //   const latLng = L.GeoJSON.coordsToLatLngs(
  //     geojson.coordinates,
  //     geojson.type === 'LineString' ? 0 : 1
  //   );

  loadDrawfromGeoJson(geojson) {
    let layer;
    if (geojson.type === 'LineString' || geojson.type == 'MultiLineString') {
      const latLng = L.GeoJSON.coordsToLatLngs(
        geojson.coordinates,
        geojson.type === 'LineString' ? 0 : 1
      );
      layer = L.polyline(latLng);
      this.mapservice.leafletDrawFeatureGroup.addLayer(layer);
    }
    if (geojson.type === 'Polygon' || geojson.type == 'MultiPolygon') {
      const latLng = L.GeoJSON.coordsToLatLngs(
        geojson.coordinates,
        geojson.type === 'Polygon' ? 1 : 2
      );
      layer = L.polygon(latLng);
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
