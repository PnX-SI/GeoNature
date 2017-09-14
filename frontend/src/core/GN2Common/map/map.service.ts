import { Injectable } from '@angular/core';
import {Http} from '@angular/http';
import { Map, GeoJSON, Layer, FeatureGroup, Marker, LatLng } from 'leaflet';
import { ToastrService, ToastrConfig } from 'ngx-toastr';
import { Subject } from 'rxjs/Subject';
import { Observable } from 'rxjs';
import { mapOptions } from './map.options';
import * as L from 'leaflet';
import { AppConfig } from '../../../conf/app.config';
import { MapUtils } from './map.utils';
import {NgbModal, NgbActiveModal} from '@ng-bootstrap/ng-bootstrap';
import {TranslateService} from '@ngx-translate/core';

@Injectable()
export class MapService {
    public map: Map;
    public baseMaps: any;
    private currentLayer: GeoJSON;
    public editingMarker: boolean;
    public marker: Marker;
    public releveFeatureGroup : FeatureGroup;
    toastrConfig: ToastrConfig;
    private _geojsonCoord = new Subject<any>();
    public modalContent: any;
    public gettingGeojson$: Observable<any> = this._geojsonCoord.asObservable();

    constructor(private http: Http, private toastrService: ToastrService, private maputils: MapUtils,
      private modalService: NgbModal, private translate: TranslateService) {
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
        this.releveFeatureGroup = new L.FeatureGroup();
        this.map.addLayer(this.releveFeatureGroup);
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
              error => {
                this.translate.get('Map.LocationError', {value: 'Map.ZoomWarning'})
                  .subscribe(res => {
                    this.toastrService.error(res, '', this.toastrConfig);
                  });
              }
          );
    }

    gotoLocation(geometry) {
      const style:any = {
        "weight": 3,
        "fillOpacity": 0,
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
      this.currentLayer = L.geoJSON(featureCollection,{
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
      this._geojsonCoord.next(geojsonCoord);
    }

    enableGps() {
      const GPSLegend = this.maputils.addCustomLegend('topleft', 'GPSLegend');
      this.map.addControl(new GPSLegend());
      const gpsElement: HTMLElement = document.getElementById('GPSLegend');
      L.DomEvent.disableClickPropagation(gpsElement);
      gpsElement.innerHTML = '<span> <b> GPS </span> <b>';
      gpsElement.style.paddingLeft = '3px';
      gpsElement.onclick = () => {
        this.modalService.open(this.modalContent);
      };
    }

}