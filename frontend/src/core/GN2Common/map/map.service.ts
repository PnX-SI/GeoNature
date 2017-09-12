import { Injectable } from '@angular/core';
import {Http} from '@angular/http';
import { Map, GeoJSON, Layer, FeatureGroup, Marker, LatLng } from 'leaflet';
import { ToastrService, ToastrConfig } from 'ngx-toastr';
import { Subject } from 'rxjs/Subject';
import { Observable } from 'rxjs';
import { leafletDrawOptions } from './leaflet-draw-options';
import * as L from 'leaflet';
import { AppConfig } from '../../../conf/app.config'
import { MapUtils } from './map.utils';
import {NgbModal, NgbActiveModal} from '@ng-bootstrap/ng-bootstrap';

@Injectable()
export class MapService {
    public map: Map;
    public baseMaps: any;
    private currentLayer: GeoJSON;
    public editingMarker: boolean;
    public marker: Marker;
    private _drawFeatureGroup: FeatureGroup;
    private _currentDraw: any;
    toastrConfig: ToastrConfig;
    private _Le: any;
    private _geojsonCoord = new Subject<any>();
    public modalContent:any;
    public gettingGeojson$: Observable<any> = this._geojsonCoord.asObservable();

    constructor(private http: Http, private toastrService: ToastrService, private Maputils:MapUtils,
      private modalService: NgbModal) {
        this._Le = L as any;
        this.toastrConfig = {
            positionClass: 'toast-top-center',
            tapToDismiss: true,
            timeOut: 3000
        };
        this.baseMaps = {
        OpenStreetMap: L.tileLayer('http://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png', {
            attribution: '&copy OpenStreetMap'
        }),
        OpenTopoMap: L.tileLayer('http://a.tile.opentopomap.org/{z}/{x}/{y}.png', {
            attribution: '&copy; OpenTopoMap'
        }),
        GoogleSatellite : L.tileLayer('http://{s}.google.com/vt/lyrs=s&x={x}&y={y}&z={z}', {
            subdomains: ['mt0', 'mt1', 'mt2', 'mt3'],
            attribution: '&copy; GoogleMap'
        })
    };
        this.editingMarker = true;
    }

    initialize() {
        const map = L.map('map', {
            zoomControl: false,
            center: L.latLng(46.52863469527167, 2.43896484375),
            zoom: 6,
            layers: [this.baseMaps.OpenTopoMap]
        });
        L.control.zoom({ position: 'topright' }).addTo(map);
        L.control.layers(this.baseMaps).addTo(map);
        L.control.scale().addTo(map);
        this.map = map;
        this.enableGps(); 
    }



    enableMarkerOnClick() {
      this.map.on('click', (e: any) => {
        // check zoom level
        if(this.map.getZoom()< AppConfig.MAP.ZOOM_LEVEL_RELEVE){
          this.toastrService.warning('Veuillez zoomer davantage pour pointer le relevé','Echelle de saisie inadaptée', this.toastrConfig)
        }else{
          if ( this.marker != null ) {
            this.marker.remove();
          }
          this.marker = L.marker(e.latlng, {
              icon: L.icon({
                      iconUrl: require<any>('../../../../node_modules/leaflet/dist/images/marker-icon.png'),
                      iconSize: [24,36],
                      iconAnchor: [12,36]
              }),
              draggable: true,
          })
          .bindPopup('GPS ' + e.latlng, {
              offset: L.point(0, -30)
          })
          .addTo(this.map)
          .openPopup();
        // observable if map click
        this.setGeojsonCoord(this.markerToGeojson(this.marker.getLatLng()));
        }
        if (this.marker != null){
          this.marker.on('moveend', (event: MouseEvent) => {
            this.marker.bindPopup('GPS ' + this.marker.getLatLng(), {
            offset: L.point(0, -30)
            }).openPopup();
          // observable if marker move
          if(this.map.getZoom() < AppConfig.MAP.ZOOM_LEVEL_RELEVE){
            this.toastrService.warning('Veuillez zoomer davantage pour déplacer le relevé','', this.toastrConfig)
          }
          this.setGeojsonCoord(this.markerToGeojson(this.marker.getLatLng()));
          });
        }
      });
    }

    markerToGeojson(latLng) {
      return {'geometry': {'type': 'Point', 'coordinates': [latLng.lng, latLng.lat]}};
    }

    toggleEditing() {
      this.editingMarker = !this.editingMarker;
      document.getElementById('markerLegend').style.backgroundColor = this.editingMarker ? '#c8c8cc' : 'white';
      if (!this.editingMarker) {
        // disable event
        this.map.off('click');
        document.getElementById('markerLegend').style.backgroundColor = 'white;';
        if ( this.marker !== undefined ) {
          this.map.removeLayer(this.marker);
        }
      } else {
        document.getElementById('markerLegend').style.backgroundColor = '#c8c8cc';
        if (this._currentDraw !== undefined ){
          this._drawFeatureGroup.removeLayer(this._currentDraw)
        }
        this.enableMarkerOnClick();
      }
    }

    search(address: string) {
      let results = [];
      this.http
          .get(`https://nominatim.openstreetmap.org/search?q=${encodeURIComponent(address)}&format=json&limit=1&polygon_geojson=1`)
          .subscribe(
              res => {
                  results = res.json();
                  results = results.filter(result => {
                      this.gotoLocation(result.geojson);
                  });
              },
              error => this.toastrService.error('', 'Location not found', this.toastrConfig)
          );
    }

    gotoLocation(geometry) {
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
      this.currentLayer = L.geoJSON(featureCollection).addTo(this.map);
      this.map.fitBounds(this.currentLayer.getBounds());
      this.clear();
    }

    // clear the marker when search
    clear() {
      if (this.currentLayer) {
        this.map.removeLayer(this.currentLayer);
        this.currentLayer = undefined;
      }
    }

    setGeojsonCoord(geojsonCoord) {
      this._geojsonCoord.next(geojsonCoord);
    }

    enableGps() {
      const GPSLegend = this.Maputils.addCustomLegend('topleft','GPSLegend');
      this.map.addControl(new GPSLegend());
      const gpsElement:HTMLElement = document.getElementById('GPSLegend');
      L.DomEvent.disableClickPropagation(gpsElement);
      gpsElement.innerHTML = "<span> <b> GPS </span> <b>";
      gpsElement.style.paddingLeft = '3px';
      gpsElement.onclick = () => {
        this.modalService.open(this.modalContent);
      }
    }

    setMarkerFromGps(x, y){
      if ( this.marker != null ) {
        this.marker.remove();
      }
      this.marker = L.marker([y, x], {
          icon: L.icon({
                  iconUrl: require<any>('../../../../node_modules/leaflet/dist/images/marker-icon.png'),
                  iconSize: [24,36],
                  iconAnchor: [12,36]
          }),
          draggable: true,
      })
      .addTo(this.map)

    }

    enableEditMap() {
      // Marker
      const MarkerLegend = this.Maputils.addCustomLegend('topleft', 'markerLegend','url(assets/images/location-pointer.png)', this.toggleEditing);
      this.map.addControl(new MarkerLegend());
      // custom the marker
      document.getElementById('markerLegend').style.backgroundColor = '#c8c8cc';
      L.DomEvent.disableClickPropagation(document.getElementById('markerLegend'));

      // Leaflet Draw
      this._drawFeatureGroup = new L.FeatureGroup();
      this.map.addLayer(this._drawFeatureGroup);
      leafletDrawOptions.edit['featureGroup'] = this._drawFeatureGroup;

      const drawControl =  new this._Le.Control.Draw(leafletDrawOptions);
      this.map.addControl(drawControl);

      this.map.on(this._Le.Draw.Event.DRAWSTART, (e) => {
        // remove the current draw
        if (this._currentDraw !== null){
          this._drawFeatureGroup.removeLayer(this._currentDraw);
        }
        // remove the current marker
        document.getElementById('markerLegend').style.backgroundColor = 'white';
        //element.style.backgroundColor = 'white';
        this.editingMarker = false;
        this.map.off('click');
        if (this.marker) {
          this.map.removeLayer(this.marker);
        }
      });

      // on draw layer created
      this.map.on(this._Le.Draw.Event.CREATED, (e) => {
        if(this.map.getZoom() < AppConfig.MAP.ZOOM_LEVEL_RELEVE){
        this.toastrService.warning('Veuillez zoomer davantage pour pointer le relevé','Echelle de saisie inadaptée', this.toastrConfig)
        }else{
          this._currentDraw = (e as any).layer;
          const layerType = (e as any).layerType;
          const latlngTab = this._currentDraw._latlngs;
          this._drawFeatureGroup.addLayer(this._currentDraw);
          let geojson = this._drawFeatureGroup.toGeoJSON();
          geojson = (geojson as any).features[0];
          // observable
          this.setGeojsonCoord(geojson);
        }

      });
    }
}