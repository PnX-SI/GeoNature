import { Injectable } from '@angular/core';
import {Http} from '@angular/http';
import { Map, GeoJSON } from 'leaflet';

@Injectable()
export class MapService {
  public map: Map;
  public baseMaps: any;

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
}
