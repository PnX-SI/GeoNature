import { Component, OnInit} from '@angular/core';
import { MapService } from '../map/map.service';
import {MapListService} from '../map-list/map-list.service';
import { GeoJSON } from 'leaflet';


@Component({
  selector: 'pnx-map-list',
  templateUrl: './map-list.component.html',
  styleUrls: ['./map-list.component.scss'],
  providers: [MapService, MapListService]
})
export class MapListComponent implements OnInit {
  public geojson: GeoJSON;
  public layerDict: any;
  public selectedLayer: any;
  originStyle = {
    'color': '#3388ff',
    'fill': true,
    'fillOpacity': 0.2,
    'weight': 3
};

 selectedStyle = {
  'color': '#ff0000',
   'weight': 3
};

  constructor(private _ms: MapService, private _mapListService: MapListService) {
  }

  ngOnInit() {
    this.layerDict = {};
    this._mapListService.getReleves()
      .subscribe(res => this.geojson = res);
  }

  onEachFeature(feature, layer) {
    this.layerDict[feature.id] = layer;
     layer.on({
       click : (e) => {
         // remove selected style
         if (this.selectedLayer !== undefined) {
           this.selectedLayer.setStyle(this.originStyle);
         }
         // set selected style
         this.selectedLayer = layer;
         layer.setStyle(this.selectedStyle);
         // popup
         const taxonsList = feature.properties.occurrences.map(occ => {
            return occ.nom_cite;
         }).join(', ');
         const observersList = feature.properties.observers.map(obs => {
          return obs.prenom_role + ' ' + obs.nom_role;
       }).join(', ');
         const popupContent = `<b> Id relevé: </b>: ${feature.id} <br>
                               <b> Observateur(s): </b> ${observersList} <br>
                               <b> Taxon(s): </b> ${taxonsList}`;
        this.selectedLayer.bindPopup(popupContent).openPopup();
         // observable
        this._mapListService.setCurrentLayerId(feature.id);
       }
     });
  }
}
