import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Map, GeoJSON, Layer, FeatureGroup, Marker, LatLng } from 'leaflet';
import { Subject, Observable } from 'rxjs';
import { find } from 'lodash';

import * as L from 'leaflet';
import 'leaflet.markercluster';
import { AppConfig } from '@geonature_config/app.config';
import { CommonService } from '../service/common.service';
import { Feature } from 'geojson';
@Injectable()
export class MapService {
  public map: Map;
  public baseMaps: any;
  private currentLayer: GeoJSON;
  public marker: Marker;
  public editingMarker = true;
  public leafletDrawFeatureGroup: FeatureGroup;
  public fileLayerFeatureGroup: FeatureGroup;
  // object {'zoom': int, 'center': {lat:int, lng: 'int}} in order to keep map extend between windows
  public currentExtend: any;
  // boolean to control if we delete filelyaer layer when leaflet draw start
  public fileLayerEditionMode = false;
  public modalContent: any;
  private _geojsonCoord = new Subject<any>();
  public gettingGeojson$: Observable<any> = this._geojsonCoord.asObservable();
  private _isEditingMarker = new Subject<boolean>();
  public isMarkerEditing$: Observable<any> = this._isEditingMarker.asObservable();
  public layerGroup: any;
  public layerControl: L.Control.Layers;
  // Leaflet reference for external module
  public L = L;

  selectedStyle = {
    color: '#ff0000',
    weight: 3,
  };

  originStyle = {
    color: '#3388ff',
    fill: false,
    fillOpacity: 0.2,
    weight: 3,
  };

  searchStyle = {
    color: 'green',
  };

  constructor(private _httpClient: HttpClient, private _commonService: CommonService) {
    this.fileLayerFeatureGroup = new L.FeatureGroup();
  }

  getAreas = (params) => {
    let queryString: HttpParams = new HttpParams();
    for (let key in params) {
      queryString = queryString.set(key, params[key]);
    }

    return this._httpClient.get<any>(`${AppConfig.API_ENDPOINT}/geo/areas`, {
      params: queryString,
    });
  };

  setMap(map) {
    this.map = map;
  }

  getMap() {
    return this.map;
  }

  initializeLeafletDrawFeatureGroup() {
    this.leafletDrawFeatureGroup = new L.FeatureGroup();
    this.map.addLayer(this.leafletDrawFeatureGroup);
  }

  initializefileLayerFeatureGroup() {
    this.map.addLayer(this.fileLayerFeatureGroup);
  }

  setGeojsonCoord(geojsonCoord) {
    this._geojsonCoord.next(geojsonCoord);
  }

  zoomOnMarker(coordinates, zoomLevel = 15) {
    this.map.setView(new L.LatLng(coordinates[1], coordinates[0]), zoomLevel);
  }

  /**
   * Function who disable marker editing (click event and control) mode via an observable
   * @param isEditing : boolean
   */
  setEditingMarker(isEditing: boolean): void {
    this._isEditingMarker.next(isEditing);
  }

  // ***** UTILS *****
  addCustomLegend(position, id, logoUrl?, func?) {
    const LayerControl = L.Control.extend({
      options: {
        position: position,
      },
      onAdd: (map) => {
        const customLegend = L.DomUtil.create(
          'div',
          'leaflet-bar leaflet-control leaflet-control-custom'
        );
        customLegend.id = id;
        customLegend.style.width = '34px';
        customLegend.style.height = '34px';
        customLegend.style.lineHeight = '30px';
        customLegend.style.backgroundColor = 'white';
        customLegend.style.cursor = 'pointer';
        customLegend.style.border = '2px solid rgba(0,0,0,0.2)';
        customLegend.style.backgroundImage = logoUrl;
        customLegend.style.backgroundRepeat = 'no-repeat';
        customLegend.style.backgroundPosition = '7px';
        customLegend.onclick = () => {
          if (func) {
            func();
          }
        };
        return customLegend;
      },
    });
    return LayerControl;
  }

  addSearchBar() {
    const control = L.Control.extend({
      options: {
        position: 'topright',
      },
      onAdd: (map) => {
        const customLegend = L.DomUtil.create(
          'input',
          'leaflet-bar leaflet-control leaflet-control-custom'
        );
        return customLegend;
      },
    });
    return control;
  }

  createMarker(x, y, isDraggable) {
    return L.marker([y, x], {
      icon: L.icon({
        iconUrl: 'assets/marker-icon.png',
        shadowUrl: 'assets/marker-shadow.png',
        iconSize: [24, 36],
        iconAnchor: [12, 36],
      }),
      draggable: isDraggable,
    });
  }

  lineStyle(color = '#3388ff', weight = 3) {
    return {
      color: color || '#3388ff',
      weight: weight || 3,
    };
  }

  defaultStyle(color = '#3388ff', fill = true, fillOpacity = 0.2, weight = 3) {
    return {
      color: color,
      fill: fill,
      fillOpacity: fillOpacity,
      weight: weight,
    };
  }

  createGeojson(geojson, asCluster: boolean, onEachFeature?, style?): GeoJSON {
    const geojsonLayer = L.geoJSON(geojson?.features || geojson, {
      style: (feature) => {
        switch (feature.geometry.type) {
          // No color nor opacity for linestrings
          case 'LineString':
            return style || this.lineStyle();
          default:
            return style || this.defaultStyle();
        }
      },
      pointToLayer: (feature, latlng) => {
        return L.circleMarker(latlng);
      },
      onEachFeature: onEachFeature,
    });
    if (asCluster) {
      return (L as any).markerClusterGroup().addLayer(geojsonLayer);
    }
    return geojsonLayer;
  }

  createWMS(layerCfg) {
    return L.tileLayer.wms(layerCfg.url, {
      ...layerCfg.params,
      crs: layerCfg.params?.crs ? L.CRS[layerCfg.params.crs.replace(':', '')] : null,
    });
  }

  removeAllLayers(map, featureGroup) {
    if (featureGroup) {
      featureGroup.eachLayer((layer) => {
        featureGroup.removeLayer(layer);
      });
    }
  }
  removeLayerFeatureGroups(featureGroups: Array<any>) {
    featureGroups.forEach((featureGroup) => {
      if (featureGroup) {
        featureGroup.eachLayer((layer) => {
          featureGroup.removeLayer(layer);
        });
      }
    });
  }

  loadGeometryReleve(data, isDraggable) {
    const coordinates = data.geometry.coordinates;
    if (data.geometry.type === 'Point') {
      this.marker = this.createMarker(coordinates[0], coordinates[1], isDraggable);
      // send observable
      let markerCoord = this.marker.getLatLng();
      let geojson = {
        geometry: { type: 'Point', coordinates: [markerCoord.lng, markerCoord.lat] },
      };
      this.setGeojsonCoord(geojson);
      this.marker.on('moveend', (event: L.LeafletMouseEvent) => {
        if (this.map.getZoom() < AppConfig.MAPCONFIG.ZOOM_LEVEL_RELEVE) {
          this._commonService.translateToaster('warning', 'Map.ZoomWarning');
        } else {
          markerCoord = this.marker.getLatLng();
          geojson = {
            geometry: { type: 'Point', coordinates: [markerCoord.lng, markerCoord.lat] },
          };
          // send observable
          this.setGeojsonCoord(geojson);
        }
      });

      this.map.addLayer(this.marker);
      // zoom to the layer
      this.map.setView(this.marker.getLatLng(), 15);
    } else {
      let layer;
      if (data.geometry.type === 'LineString') {
        const myLatLong = coordinates.map((point) => {
          return L.latLng(point[1], point[0]);
        });
        layer = L.polyline(myLatLong);
        this.leafletDrawFeatureGroup.addLayer(layer);
      }
      if (data.geometry.type === 'Polygon') {
        const myLatLong = coordinates[0].map((point) => {
          return L.latLng(point[1], point[0]);
        });
        layer = L.polygon(myLatLong);
        this.leafletDrawFeatureGroup.addLayer(layer);
      }
      this.map.fitBounds(layer.getBounds());
      // disable point event on the map
      this.setEditingMarker(false);
      // send observable
      let geojson = this.leafletDrawFeatureGroup.toGeoJSON();
      geojson = (geojson as any).features[0];
      this.setGeojsonCoord(geojson);
    }
  }

  /**
   * init layer by type and create empty layer for WFS and GeoJson
   * @param type  string
   * @returns
   */
  getLayerCreator = (type) =>
    find(
      [
        {
          geojson: (cfg) => this.createGeojson([], false, null, cfg?.style),
        },
        {
          wfs: (cfg) => this.createGeojson([], false, null, cfg?.style),
        },
        {
          wms: this.createWMS,
        },
        {
          area: (cfg) => this.createGeojson([], false, null, cfg?.style),
        },
      ],
      type
    )[type];

  /**
   * Method to custom controler.layers layers name with legend and name
   * @param title string
   * @param fill string
   * @param stroke string
   * @returns
   */
  getLegendBox({ title, fillColor, fillOpacity, color, weight, legendUrl }) {
    let padding = 'padding-left:10px';
    if (!fillColor && !color && !legendUrl) {
      return title;
    }
    if (legendUrl) {
      return `<span class="title-overlay" >${title}</span> </br> <img style="${padding}" src="${legendUrl}">`;
    }
    fillColor = fillColor || 'rgba(255,255,255)';
    fillOpacity = fillOpacity || 1;
    color = color || 'grey';
    weight = weight + 2 || 3;

    let svgSquare = `<svg width="16" height="16">
      <rect width="300" height="100" style="fill:${fillColor};fill-opacity:${fillOpacity};stroke-width:${weight};stroke:${color}" />
    </svg>`;
    return `<span data-qa="title-overlay">${title}</span> <br/> <span style="${padding}">${svgSquare}</span>`;
  }

  /**
   * will create overlays layers -> L.control.overlays
   * @returns
   */
  createOverLayers(map) {
    const OVERLAYERS = JSON.parse(JSON.stringify(AppConfig.MAPCONFIG.REF_LAYERS));
    const overlaysLayers = {};
    OVERLAYERS.map((lyr) => [lyr, this.getLayerCreator(lyr.type)(lyr)])
      .filter((l) => l[1])
      .forEach((lyr) => {
        let title = lyr[0]?.label || '';
        let style = lyr[0]?.style || {};

        // this code create dict for L.controler.layers
        // key is name display as checkbox label
        // value is layer
        let layerLeaf = lyr[1];
        let legendUrl = '';
        layerLeaf.configId = lyr[0].code;
        if (layerLeaf?.options?.service === 'wms' && layerLeaf._url) {
          legendUrl = `${layerLeaf._url}?TRANSPARENT=TRUE&VERSION=1.3.0&REQUEST=GetLegendGraphic&LAYER=${layerLeaf.options.layers}&FORMAT=image%2Fpng&LEGEND_OPTIONS=forceLabels%3Aon%3BfontAntiAliasing%3Atrue`;
        }
        // leaflet layers controler required object
        if (AppConfig.MAPCONFIG?.REF_LAYERS_LEGEND) {
          overlaysLayers[this.getLegendBox({ title: title, ...style, legendUrl: legendUrl })] =
            lyr[1];
        } else {
          overlaysLayers[`<span data-qa="title-overlay">${title}</span>`] = lyr[1];
        }
        if (lyr[0].activate) {
          map.addLayer(layerLeaf);
          this.loadOverlay(layerLeaf);
        }
      });
    return overlaysLayers;
  }

  /**
   * Will load WFS and GeoJson only if empty and only on added to map event
   * @param overlay leaflet layer
   * @returns
   */
  loadOverlay(overlay) {
    let overlayer = overlay?.layer || overlay;
    let cfgLayer = JSON.parse(JSON.stringify(AppConfig.MAPCONFIG.REF_LAYERS));
    let layerAdded = cfgLayer.filter((o) => o.code === overlayer.configId)[0];

    if (['wms'].includes(layerAdded.type) || overlayer.getLayers().length) return;

    // Load geojson file or WFS - application/json only
    if (['geojson', 'wfs'].includes(layerAdded.type)) {
      this._httpClient.get<any>(layerAdded.url).subscribe((res = { features: [] }) => {
        overlayer.addData(res);
      });
    }

    // Load ref_geo data
    if (['area'].includes(layerAdded.type)) {
      let params = { type_code: layerAdded.code, format: 'geojson', ...layerAdded.params };
      this.getAreas(params).subscribe((res) => {
        let geojson = {
          type: 'FeatureCollection',
          name: layerAdded.label,
          features: res.map((r) => ({ ...r, geometry: JSON.parse(r.geometry) })),
        };
        overlayer.addData(geojson);
      });
    }
  }
}
