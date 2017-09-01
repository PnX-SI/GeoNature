import { Injectable } from '@angular/core';
import {Http} from '@angular/http';
import { Map, GeoJSON, Layer, FeatureGroup } from 'leaflet';
import { ToastrService, ToastrConfig } from 'ngx-toastr';
import { Subject } from 'rxjs/Subject';
import { Observable } from 'rxjs';
import { leafletDrawOptions } from './leaflet-draw-options'

@Injectable()
export class MapService {
    public map: Map;
    public baseMaps: any;
    private currentLayer: GeoJSON;
    public editingMarker: boolean;
    public marker: any;
    private _drawFeatureGroup:FeatureGroup;
    private _currentDraw: Layer;
    toastrConfig: ToastrConfig;
    private _Le: any;
    private _coord = new Subject<any>();
    public gettingCoord$:Observable<any> = this._coord.asObservable();

    constructor(private http: Http, private toastrService: ToastrService) {
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
    }

    enableMarkerOnClick() {
        this.map.on('click', (e: any) => {
                    if ( this.marker != null )
                            this.marker.remove();

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

                    this.marker.on('move', (event: MouseEvent) => {
                        this.marker.bindPopup('GPS ' + this.marker.getLatLng(), {
                        offset: L.point(0, -30)
                        }).openPopup();
                      // observable if marker move
                      this.setCoord(this.marker.getLatLng());
                    });
                // observable if map click
                this.setCoord(this.marker.getLatLng());

        });
    }

    toggleEditing() {
        this.editingMarker = !this.editingMarker;
        if ( this.marker !== null ){
          this.map.removeLayer(this.marker);
        }
        if (this._currentDraw !== null ){
          this._drawFeatureGroup.removeLayer(this._currentDraw)
        }
        this.enableMarkerOnClick();
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

    clear() {
        if (this.currentLayer) {
        this.map.removeLayer(this.currentLayer);
        this.currentLayer = undefined;
        }
    }

    getGeometry() {
        if( this.marker != null ){
            return this.marker.getLatLng();
        }
    }

    setCoord(coord){        
      this._coord.next(coord);
    }

    enableLeafletDraw(){
      this._drawFeatureGroup = new L.FeatureGroup();
      this.map.addLayer(this._drawFeatureGroup);
      leafletDrawOptions.edit['featureGroup'] = this._drawFeatureGroup;

  
      const drawControl =  new this._Le.Control.Draw(leafletDrawOptions);
      this.map.addControl(drawControl);

      this.map.on(this._Le.Draw.Event.DRAWSTART, (e) => {
        // remove the current draw
        if(this._currentDraw !== null){
          this._drawFeatureGroup.removeLayer(this._currentDraw);
        }
        // remove the current marker
        this.editingMarker = false;
        this.map.off('click');
        if(this.marker)
          this.map.removeLayer(this.marker);
      });

      // Create the draw layer
      this.map.on(this._Le.Draw.Event.CREATED, (e) => {
        this._currentDraw = (e as any).layer;
        this._drawFeatureGroup.addLayer(this._currentDraw);
        // observable

      })
    }
}
