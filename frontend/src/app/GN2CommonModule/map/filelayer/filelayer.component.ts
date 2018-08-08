import { Component, OnInit } from '@angular/core';
import { MapService } from '../map.service';
import { Map } from 'leaflet';
// import * as L from 'leaflet';
// import * as T from 'leaflet-filelayer/src/leaflet.filelayer';
import 'leaflet';

@Component({
  selector: 'pnx-leaflet-filelayer',
  templateUrl: './filelayer.component.html'
})
export class LeafletFileLayerComponent implements OnInit {
  public map: Map;
  public Le: any;
  constructor(public mapService: MapService) {}

  ngOnInit() {
    console.log((window as any).L);
    //console.log(L);
    this.map = this.mapService.getMap();
    //this.Le = L;

    //   (L.Control as any)
    //     .fileLayerLoad({
    //       // Allows you to use a customized version of L.geoJson.
    //       // For example if you are using the Proj4Leaflet leaflet plugin,
    //       // you can pass L.Proj.geoJson and load the files into the
    //       // L.Proj.GeoJson instead of the L.geoJson.
    //       layer: (L as any).geoJson,
    //       // See http://leafletjs.com/reference.html#geojson-options
    //       layerOptions: { style: { color: 'red' } },
    //       // Add to map after loading (default: true) ?
    //       addToMap: true,
    //       // File size limit in kb (default: 1024) ?
    //       fileSizeLimit: 1024,
    //       // Restrict accepted file formats (default: .geojson, .json, .kml, and .gpx) ?
    //       formats: ['.gpx', '.geojson', '.kml']
    //     })
    //     .addTo(this.map);
  }
}
