import { Component, OnInit, Output, EventEmitter, AfterViewInit } from '@angular/core';
import { MapService } from '../map.service';
import { Map } from 'leaflet';
import * as L from 'leaflet';
import * as ToGeojson from 'togeojson';
import * as FileLayer from 'leaflet-filelayer';
import 'leaflet';
@Component({
  selector: 'pnx-leaflet-filelayer',
  templateUrl: './filelayer.component.html'
})
export class LeafletFileLayerComponent implements OnInit, AfterViewInit {
  public map: Map;
  public Le: any;
  public layer: any;
  public onLoad = new EventEmitter<any>();
  constructor(public mapService: MapService) {}

  ngOnInit() {}

  ngAfterViewInit() {
    this.map = this.mapService.getMap();
    FileLayer(null, L, ToGeojson);
    const fileLayerControl = (L.Control as any)
      .fileLayerLoad({
        // Allows you to use a customized version of L.geoJson.
        // For example if you are using the Proj4Leaflet leaflet plugin,
        // you can pass L.Proj.geoJson and load the files into the
        // L.Proj.GeoJson instead of the L.geoJson.
        layer: (L as any).geoJson,
        // See http://leafletjs.com/reference.html#geojson-options
        layerOptions: { style: { color: 'red' } },
        // Add to map after loading (default: true) ?
        addToMap: true,
        // File size limit in kb (default: 1024) ?
        fileSizeLimit: 1024,
        // Restrict accepted file formats (default: .geojson, .json, .kml, and .gpx) ?
        formats: ['.gpx', '.geojson', '.kml']
      })
      .addTo(this.map);

    fileLayerControl.loader.on('data:loaded', function(event) {
      // tslint:disable-next-line:forin
      for (let layer in event.layer._layers) {
        // emit the geometry as an output
        this.onLoad.emit(event.layer._layers[layer]['feature']);
      }
      this.onLoad.emit(event.layer);
      // remove the previous layer of the map
      if (this.layer) {
        fileLayerControl._map.removeLayer(this.layer);
      }
      this.layer = event.layer;
    });
  }
}
