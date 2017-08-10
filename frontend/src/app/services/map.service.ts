import { Injectable } from '@angular/core';
import {Http} from '@angular/http';
import { Map, GeoJSON } from 'leaflet';

@Injectable()
export class MapService {
    public map: Map;
    public baseMaps: any;
    private currentLayer: GeoJSON;
    public editing: boolean;
    public removing: boolean;
    public marker: any;

    constructor(private http: Http) {
        this.baseMaps = {
        OpenStreetMap: L.tileLayer('http://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png', {
            attribution: '&copy OpenStreetMap'
        }),
        OpenTopoMap: L.tileLayer('http://a.tile.opentopomap.org/{z}/{x}/{y}.png', {
            attribution: '&copy; OpenTopoMap'
        }),
        Esri: L.tileLayer('http://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}', {
            attribution: 'Tiles &copy Esri Japan, METI, Esri China (Hong Kong), and the GIS User Community'
        })
        };
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
                        if ( this.marker != null ) {
                        this.marker.remove();
                        }
                    this.marker = L.marker(e.latlng, {
                        icon: L.icon({
                            iconUrl: '../../images/marker-icon.png',
                            shadowUrl: '../../images/marker-shadow.png',
                        }),
                        draggable: true,
                    })
                    .bindPopup('Marker at ' + e.latlng, {
                        offset: L.point(12, 6)
                    })
                    .addTo(this.map)
                    .openPopup();
                    this.marker.on('click', (event: MouseEvent) => {
                        if (this.removing) {
                                this.map.removeLayer(this.marker);
                        }
                    });

                    this.marker.on('move', (event: MouseEvent) => {
                        this.marker.bindPopup('Marker at ' + this.marker.getLatLng(), {
                        offset: L.point(12, 6)
                        });
                    });
                }
        });
    }

    toggleEditing() {
        this.editing = !this.editing;
        if (this.editing && this.removing) {
            this.removing = false;
        }
    }

    toggleRemoving() {
        this.removing = !this.removing;

        if (this.editing && this.removing) {
            this.editing = false;
        }
    }


    clear() {
        if (this.currentLayer) {
        this.map.removeLayer(this.currentLayer);
        this.currentLayer = undefined;
        }
    }

    disableMouseEvent(elementId: string) {
            const element = <HTMLElement>document.getElementById(elementId);
            // stops the bubbling of an event to parent elements,
            // preventing any parent event handlers from being executed.
            L.DomEvent.disableClickPropagation(element);
            L.DomEvent.disableScrollPropagation(element);
        }

}
