import { Component, OnInit, Input, OnChanges } from '@angular/core';
import { Map } from 'leaflet';
import { MapService } from '../map.service';
import * as L from 'leaflet';
import { Observable } from 'rxjs';
import { Subject } from 'rxjs/Subject';

@Component({
  selector: 'pnx-geojson',
  templateUrl: 'geojson.component.html'
})
export class GeojsonComponent implements OnInit, OnChanges {
  public map: Map;
  public currentGeojson: L.Layer;
  public layerGroup: any;
  @Input() geojson: any;
  @Input() onEachFeature: any;
  @Input() style: any;
  // display the geojsons as cluster or not
  @Input() asCluster = false;
  public geojsonCharged = new Subject<any>();
  public currentGeoJson$: Observable<L.Layer> = this.geojsonCharged.asObservable();

  constructor(public mapservice: MapService) {}

  ngOnInit() {
    this.map = this.mapservice.map;
  }

  loadGeojson(geojson) {
    this.currentGeojson = this.mapservice.createGeojson(
      geojson,
      this.asCluster,
      this.onEachFeature
    );
    this.geojsonCharged.next(this.currentGeojson);
    this.mapservice.layerGroup = new L.FeatureGroup();
    this.mapservice.map.addLayer(this.mapservice.layerGroup);
    this.mapservice.layerGroup.addLayer(this.currentGeojson);
  }

  ngOnChanges(changes) {
    if (changes.geojson && changes.geojson.currentValue !== undefined) {
      if (this.currentGeojson !== undefined) {
        this.mapservice.map.removeLayer(this.currentGeojson);
      }
      this.loadGeojson(changes.geojson.currentValue);
      // zoom on layer extend after fisrt search
      if (changes.geojson.previousValue !== undefined) {
        // try to fit bound on layer. catch error if no layer in feature group

        try {
          this.map.fitBounds(this.mapservice.layerGroup.getBounds());
        } catch (error) {
          console.log('no layer in featuregroup');
        }
        //
      }
    }
  }
}
