import { Component, OnInit, Input} from '@angular/core';
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
  public layerDict: any;
  public selectedLayer: any;
  @Input() data: GeoJSON;


  constructor(private _ms: MapService, private _mapListService: MapListService) {
  }

  ngOnInit() {
    this._mapListService.gettingLayerId$.subscribe(res => {
      console.log('from map');
      console.log(res);
      console.log(this._mapListService.layerDict[res]);
      
      this._mapListService.layerDict[res].setStyle(this._mapListService.selectedLayer);
    });
  }
  onEachFeature(feature, layer) {
    this._mapListService.layerDict[feature.id] = layer;
    layer.on({
      click : (e) => {
        // remove selected style
        if (this._mapListService.selectedLayer !== undefined) {
          this._mapListService.selectedLayer.setStyle(this._mapListService.originStyle);
        }
        // set selected style
        this._mapListService.selectedLayer = layer;
        layer.setStyle(this._mapListService.selectedStyle);
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
        this._mapListService.selectedLayer.bindPopup(popupContent).openPopup();
        // observable
        this._mapListService.setCurrentLayerId(feature.id);
      }
    });
  }



}
