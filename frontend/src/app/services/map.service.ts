import { Injectable } from '@angular/core';
import {Http} from '@angular/http';
import { Map, GeoJSON } from 'leaflet';
import { ToastrService, ToastrConfig } from 'ngx-toastr';

@Injectable()
export class MapService {
    public map: Map;
    public baseMaps: any;
    private currentLayer: GeoJSON;
    public editing: boolean;
    public marker: any;
    toastrConfig: ToastrConfig;

    constructor(private http: Http, private toastrService: ToastrService) {
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
        this.editing = false;
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

    onMapClick() {
        this.map.on('click', (e: any) => {
                if (this.editing) {
                    if ( this.marker != null )
                            this.marker.remove();

                    this.marker = L.marker(e.latlng, {
                        icon: L.icon({
                                iconUrl: require<any>('../../../node_modules/leaflet/dist/images/marker-icon.png'),
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
                    });
                }
        });
    }

    toggleEditing() {
        this.editing = !this.editing;
        if ( this.marker != null )
             this.map.removeLayer(this.marker);
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
}
