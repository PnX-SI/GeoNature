import { Component, OnInit, Input, Output, EventEmitter, OnChanges } from '@angular/core';
import { Map } from 'leaflet';

import { MapService } from '../map.service';
import { CommonService } from '../../service/common.service';
import { leafletDrawOption } from '@geonature_common/map/leaflet-draw.options';
import { CustomIcon } from '@geonature/utils/leaflet-icon';

import 'leaflet-draw';
import * as L from 'leaflet';
import { ConfigService } from '@geonature/services/config.service';

delete L.Icon.Default.prototype['_getIconUrl'];

L.Icon.Default.mergeOptions(CustomIcon);

/**
 * Ce composant permet d'activer le `plugin leaflet-draw <https://github.com/Leaflet/Leaflet.draw>`_
 */
@Component({
  selector: 'pnx-leaflet-draw',
  templateUrl: 'leaflet-draw.component.html',
})
export class LeafletDrawComponent implements OnInit, OnChanges {
  public map: Map;
  private _currentDraw: any;
  private _currentGeojson: any;
  private _Le: any;
  public drawnItems: any;
  // save the current layer type because the edite event do not send it...
  public currentLayerType: string;
  /** Coordonnées de l'entité à dessiner */
  public drawControl;
  /* pour pouvoir cacher / afficher le composant */
  @Input() bEnable = true; //
  @Input() geojson: any;
  /* Boolean qui controle le zoom au point*/
  @Input() bZoomOnPoint = true;
  @Input() zoomLevelOnPoint = 8;
  /**
   *  Objet permettant de paramettrer le plugin et les différentes formes dessinables (point, ligne, cercle etc...)
   *
   * Par défault le fichier ``leaflet-draw.option.ts`` est passé au composant.
   * Il est possible de surcharger l'objet pour activer/désactiver certaines formes.
   * Voir `exemple
   * <https://github.com/PnX-SI/GeoNature/blob/develop/frontend/src/modules/occtax/occtax-map-form/occtax-map-form.component.ts#L27>`_
   */
  @Input() options = leafletDrawOption;
  @Input() zoomLevel = null;
  /** Niveau de zoom à partir du quel on peut dessiner sur la carte */
  @Output() layerDrawed = new EventEmitter<any>();
  @Output() layerDeleted = new EventEmitter<any>();

  constructor(
    public mapservice: MapService,
    private _commonService: CommonService,
    public config: ConfigService
  ) {}

  ngOnInit() {
    // HACK for leaflet draw compatibility
    (window as any).type = true;
    this.map = this.mapservice.map;
    this.zoomLevel = this.zoomLevel || this.config.MAPCONFIG.ZOOM_LEVEL_RELEVE;
    this._Le = L as any;
    this.enableLeafletDraw();
  }

  ngOnDestroy() {
    (window as any).type = undefined;
  }

  enableLeafletDraw() {
    this.options.edit['featureGroup'] = this.drawnItems;
    this.options.edit['featureGroup'] = this.mapservice.leafletDrawFeatureGroup;
    this.drawControl = new this._Le.Control.Draw(this.options);
    this.map.addControl(this.drawControl);

    if (!this.bEnable) {
      this.disableDrawControl();
    }

    this.map.on(this._Le.Draw.Event.DRAWSTART, (e) => {
      this._currentGeojson =
        this._currentGeojson == null ? { geometry: this.geojson } : this._currentGeojson;
      this.mapservice.removeAllLayers(this.map, this.mapservice.fileLayerFeatureGroup);
      if (this.map.getZoom() < this.zoomLevel) {
        this._commonService.translateToaster('warning', 'Map.Messages.ZoomWarning');
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
    this.map.on(this._Le.Draw.Event.CREATED, (e) => {
      this.mapservice.removeAllLayers(this.map, this.mapservice.leafletDrawFeatureGroup);
      if (this.map.getZoom() < this.zoomLevel) {
        this._commonService.translateToaster('warning', 'Map.Messages.ZoomWarning');
        this.layerDrawed.emit({ geojson: null });
      } else {
        this._currentDraw = (e as any).layer;

        this.currentLayerType = (e as any).layerType;
        this.mapservice.leafletDrawFeatureGroup.addLayer(this._currentDraw);
        const geojson = this.getGeojsonFromFeatureGroup(this.currentLayerType);
        this.mapservice.setGeojsonCoord(geojson);
        this._currentGeojson = geojson;
        this.layerDrawed.emit(geojson);
      }
    });

    // on draw edited
    this.mapservice.map.on(this._Le.Draw.Event.EDITED, (e) => {
      const geojson = this.getGeojsonFromFeatureGroup(this.currentLayerType);
      this.mapservice.setGeojsonCoord(geojson);
      this._currentGeojson = geojson;
      this.layerDrawed.emit(geojson);
    });

    // on layer deleted
    this.map.on(this._Le.Draw.Event.DELETED, (e) => {
      this.layerDeleted.emit();
    });

    this.map.on(this._Le.Draw.Event.DELETESTOP, (e) => {
      const geojson = this.getGeojsonFromFeatureGroup(this.currentLayerType);
      if (geojson) {
        this.layerDrawed.emit(geojson);
        this.mapservice.setGeojsonCoord(geojson);
      }
    });

    this.map.on(this._Le.Draw.Event.DRAWSTOP, (e) => {
      const geojson = this._currentGeojson?.geometry || this.geojson;

      if (this._currentDraw) {
        this.handleDrawStopWithCurrentDraw(geojson);
      } else {
        this.handleDrawStopWithoutCurrentDraw(geojson);
      }
    });
  }
  handleDrawStopWithCurrentDraw(geojson: any): void {
    if (!this.mapservice.leafletDrawFeatureGroup.hasLayer(this._currentDraw) && geojson) {
      this.loadDrawfromGeoJson(geojson);
    }
  }

  handleDrawStopWithoutCurrentDraw(geojson: any): void {
    this.mapservice.removeAllLayers(this.map, this.mapservice.fileLayerFeatureGroup);
    const layer: L.Layer = this.mapservice.createGeojson(geojson, false);

    if (!this.mapservice.leafletDrawFeatureGroup.hasLayer(layer)) {
      this.loadDrawfromGeoJson(geojson);
    }
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
    // load leaflet draw from an existing geojson
    // no refire events
    if (!geojson) {
      return;
    }
    let layer;
    if (geojson.type === 'LineString' || geojson.type === 'MultiLineString') {
      const latLng = L.GeoJSON.coordsToLatLngs(
        geojson.coordinates,
        geojson.type === 'LineString' ? 0 : 1
      );
      layer = L.polyline(latLng);
      this.mapservice.leafletDrawFeatureGroup.addLayer(layer);
    }
    if (geojson.type === 'Polygon' || geojson.type === 'MultiPolygon') {
      const latLng = L.GeoJSON.coordsToLatLngs(
        geojson.coordinates,
        geojson.type === 'Polygon' ? 1 : 2
      );
      layer = L.polygon(latLng);
      this.mapservice.leafletDrawFeatureGroup.addLayer(layer);
      this.mapservice.map.fitBounds(layer.getBounds());
    } else if (geojson.type === 'Point') {
      // marker
      layer = L.marker(new L.LatLng(geojson.coordinates[1], geojson.coordinates[0]), {});
      this.mapservice.leafletDrawFeatureGroup.addLayer(layer);
      if (this.bZoomOnPoint) {
        this.map.setView(layer.getLatLng(), 15);
      }
    }

    if (layer.getBounds) {
      this.mapservice.map.fitBounds(layer.getBounds());
    } else {
      if (this.mapservice.map['_zoom'] === 0 || this.bZoomOnPoint) {
        this.mapservice.map.setView(
          layer._latlng,
          this.zoomLevelOnPoint,
          this.mapservice.map['_zoom']
        );
      } else {
        this.mapservice.map.panTo(layer._latlng);
      }
    }
    // disable point event on the map
    this.mapservice.setEditingMarker(false);
  }

  // cache le draw control
  disableDrawControl() {
    if (!this.drawControl) {
      return;
    }
    this.mapservice.leafletDrawFeatureGroup.clearLayers();
    this._currentGeojson = null;
    this.drawControl.remove();
  }

  // fait apparaitre le draw control
  enableDrawControl() {
    if (!this.drawControl) {
      return;
    }
    this.mapservice.leafletDrawFeatureGroup.addTo(this.map);
    this.drawControl._toolbars.draw.setOptions(this.options.draw);
    this.drawControl.addTo(this.map);
  }

  ngOnChanges(changes) {
    if (changes.geojson && changes.geojson.currentValue) {
      this.loadDrawfromGeoJson(changes.geojson.currentValue);
    }
    if (changes.bEnable || (changes.options && changes.options.currentValue)) {
      if (this.bEnable) {
        this.enableDrawControl();
      } else {
        this.disableDrawControl();
      }
    }
  }
}
