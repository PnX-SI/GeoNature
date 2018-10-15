import { Injectable } from '@angular/core';
import { Http } from '@angular/http';
import { Map, GeoJSON, Layer, FeatureGroup, Marker, LatLng } from 'leaflet';
import { Subject } from 'rxjs/Subject';
import { Observable } from 'rxjs';

import * as L from 'leaflet';
import { MAP_CONFIG } from '../../../conf/map.config';
import { CommonService } from '../service/common.service';

@Injectable()
export class MapService {
  public map: Map;
  public baseMaps: any;
  private currentLayer: GeoJSON;
  public marker: Marker;
  public editingMarker = true;
  public releveFeatureGroup: FeatureGroup;
  public modalContent: any;
  private _geojsonCoord = new Subject<any>();
  public gettingGeojson$: Observable<any> = this._geojsonCoord.asObservable();
  private _isEditingMarker = new Subject<boolean>();
  public isMarkerEditing$: Observable<any> = this._isEditingMarker.asObservable();
  public layerGroup: any;
  public justLoaded = true;

  selectedStyle = {
    color: '#ff0000',
    weight: 3
  };

  constructor(private http: Http, private _commonService: CommonService) {}

  setMap(map) {
    this.map = map;
  }

  getMap() {
    return this.map;
  }

  initializeReleveFeatureGroup() {
    this.releveFeatureGroup = new L.FeatureGroup();
    this.map.addLayer(this.releveFeatureGroup);
  }

  search(address: string) {
    let results = [];
    this.http
      .get(
        `https://nominatim.openstreetmap.org/search?q=${encodeURIComponent(
          address
        )}&format=json&limit=1&polygon_geojson=1`
      )
      .subscribe(
        res => {
          results = res.json();
          results = results.filter(result => {
            this.gotoLocation(result.geojson);
          });
        },
        error => {
          this._commonService.translateToaster('Warning', 'Map.LocationError');
        }
      );
  }

  gotoLocation(geometry) {
    const style: any = {
      weight: 3,
      fillOpacity: 0
    };
    this.clear();
    const featureCollection: GeoJSON.FeatureCollection<any> = {
      type: 'FeatureCollection',
      features: [
        {
          type: 'Feature',
          geometry: geometry,
          properties: {}
        }
      ]
    };
    this.currentLayer = L.geoJSON(featureCollection, {
      style: style
    }).addTo(this.map);
    this.map.fitBounds(this.currentLayer.getBounds());
  }

  // clear the marker when search
  clear() {
    if (this.currentLayer) {
      this.map.removeLayer(this.currentLayer);
      this.currentLayer = undefined;
    }
  }

  setGeojsonCoord(geojsonCoord) {
    if (!this.justLoaded) {
      this._geojsonCoord.next(geojsonCoord);
    }
  }

  setEditingMarker(isEditing) {
    this._isEditingMarker.next(isEditing);
  }

  // ***** UTILS *****
  addCustomLegend(position, id, logoUrl?, func?) {
    const LayerControl = L.Control.extend({
      options: {
        position: position
      },
      onAdd: map => {
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
      }
    });
    return LayerControl;
  }

  createMarker(x, y, isDraggable) {
    return L.marker([y, x], {
      icon: L.icon({
        iconUrl: require<any>('../../../../node_modules/leaflet/dist/images/marker-icon.png'),
        iconSize: [24, 36],
        iconAnchor: [12, 36]
      }),
      draggable: isDraggable
    });
  }

  createGeojson(geojson, onEachFeature?): GeoJSON {
    return L.geoJSON(geojson, {
      style: (feature) => {
        switch (feature.geometry.type) {
          // No color nor opacity for linestrings
          case 'LineString': return {
            color: '#3388ff',
            weight: 3
          };
          default: return {
            color: '#3388ff',
            fill: true,
            fillOpacity: 0.2,
            weight: 3
          };
        }
      },
      pointToLayer: (feature, latlng) => {
        return L.circleMarker(latlng);
      },
      onEachFeature: onEachFeature
    });
  }

  removeAllLayers(map, featureGroup) {
    featureGroup.eachLayer(layer => {
      featureGroup.removeLayer(layer);
    });
  }

  loadGeometryReleve(data, isDraggable) {
    const coordinates = data.geometry.coordinates;
    if (data.geometry.type === 'Point') {
      this.marker = this.createMarker(coordinates[0], coordinates[1], isDraggable);
      // send observable
      let markerCoord = this.marker.getLatLng();
      let geojson = {
        geometry: { type: 'Point', coordinates: [markerCoord.lng, markerCoord.lat] }
      };
      this.setGeojsonCoord(geojson);
      this.marker.on('moveend', (event: MouseEvent) => {
        if (this.map.getZoom() < MAP_CONFIG.ZOOM_LEVEL_RELEVE) {
          this._commonService.translateToaster('warning', 'Map.ZoomWarning');
        } else {
          markerCoord = this.marker.getLatLng();
          geojson = {
            geometry: { type: 'Point', coordinates: [markerCoord.lng, markerCoord.lat] }
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
        const myLatLong = coordinates.map(point => {
          return L.latLng(point[1], point[0]);
        });
        layer = L.polyline(myLatLong);
        this.releveFeatureGroup.addLayer(layer);
      }
      if (data.geometry.type === 'Polygon') {
        const myLatLong = coordinates[0].map(point => {
          return L.latLng(point[1], point[0]);
        });
        layer = L.polygon(myLatLong);
        this.releveFeatureGroup.addLayer(layer);
      }
      this.map.fitBounds(layer.getBounds());
      // disable point event on the map
      this.setEditingMarker(false);
      // send observable
      let geojson = this.releveFeatureGroup.toGeoJSON();
      geojson = (geojson as any).features[0];
      this.setGeojsonCoord(geojson);
    }
  }
}
