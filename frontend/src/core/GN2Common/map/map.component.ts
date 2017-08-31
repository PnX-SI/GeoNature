import { Component, OnInit } from '@angular/core';
import { MapService } from './map.service';
import {Map} from 'leaflet';
import 'leaflet-draw';


@Component({
  selector: 'pnx-map',
  templateUrl: './map.component.html',
  styleUrls: ['./map.component.scss']
})
export class MapComponent implements OnInit {
  public map: Map;
  public Le: any;
  searchLocation: string;
  constructor(public mapService: MapService) {
    this.mapService.editing = false;
    // this.mapService.removing = false;
    this.searchLocation = '';
    this.Le = L as any;
  }

  ngOnInit() {
    this.mapService.initialize();
    //this.mapService.onMapClick();
    this.map = this.mapService.map;

    var editableLayers = new L.FeatureGroup();
    this.map.addLayer(editableLayers);

    var options = {
      position: 'topleft',
      draw: {
          polyline: {
              shapeOptions: {
                  color: '#f357a1',
                  weight: 10
              }
          },
          polygon: {
              allowIntersection: false, // Restricts shapes to simple polygons
              drawError: {
                  color: '#e1e100', // Color the shape will turn when intersects
                  message: '<strong>Oh snap!<strong> you can\'t draw that!' // Message that will show when intersect
              },
              shapeOptions: {
                  color: '#bada55'
              }
          },
          circle: false, // Turns off this drawing tool
          rectangle: {
              shapeOptions: {
                  clickable: false
              }
          },
          marker: {
              icon: L.icon({
                iconUrl: require<any>('../../../../node_modules/leaflet/dist/images/marker-icon.png'),
                iconSize: [24,36],
                iconAnchor: [12,36]
              }),
          }
      },
      edit: {
          featureGroup: editableLayers, //REQUIRED!!
          remove: false
      }
  };

    const drawControl =  new this.Le.Control.Draw(options);
    this.map.addControl(drawControl);

    this.map.on(this.Le.Draw.Event.CREATED, (e) => {
      console.log(e);
      
    })

  }

    gotoLocation() {
        if (!this.searchLocation) { return; }
        this.mapService.search(this.searchLocation);
    }

}
