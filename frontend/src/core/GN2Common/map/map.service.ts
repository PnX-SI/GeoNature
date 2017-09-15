import { Injectable } from '@angular/core';
import {Http} from '@angular/http';
import { Map, GeoJSON, Layer, FeatureGroup, Marker, LatLng } from 'leaflet';
import { ToastrService, ToastrConfig } from 'ngx-toastr';
import { Subject } from 'rxjs/Subject';
import { Observable } from 'rxjs';
<<<<<<< HEAD
=======
import { mapOptions } from './map.options';
>>>>>>> origin/map-list
import * as L from 'leaflet';
import { AppConfig } from '../../../conf/app.config';
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

    constructor(private http: Http, private toastrService: ToastrService,
      private translate: TranslateService) {
        this.toastrConfig = {
            positionClass: 'toast-top-center',
            tapToDismiss: true,
            timeOut: 3000
        };
        this.editingMarker = true;
    }

    setMap(map){
      this.map = map;
    }

    getMap(){
      return this.map
    }

    initializeReleveFeatureGroup() {
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


    sendWarningMessage(){
      this.translate.get('Map.ZoomWarning', {value: 'Map.ZoomWarning'})
      .subscribe(res =>
        this.toastrService.warning(res, '', this.toastrConfig)
      );
    }
    // ***** UTILS *****
    addCustomLegend(position, id, logoUrl?, func?) {
      const LayerControl = L.Control.extend({
        options: {
          position: position
        },
        onAdd: (map) => {
          const customLegend = L.DomUtil.create('div', 'leaflet-bar leaflet-control leaflet-control-custom');
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
  
    createMarker(x, y) {
     return L.marker([y, x], {
        icon: L.icon({
                iconUrl: require<any>('../../../../node_modules/leaflet/dist/images/marker-icon.png'),
                iconSize: [24, 36],
                iconAnchor: [12, 36]
        }),
        draggable: true,
    })
    }
  
    removeAllLayers(map, featureGroup){
      featureGroup.eachLayer((layer)=>{
        map.removeLayer(layer);
      })
    }

}