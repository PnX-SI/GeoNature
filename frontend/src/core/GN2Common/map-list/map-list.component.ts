import { Component, OnInit, Input} from '@angular/core';
import { MapService } from '../map/map.service';
import {MapListService} from '../map-list/map-list.service';
import { GeoJSON, Layer } from 'leaflet';


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

        // observable
        this._mapListService.setCurrentTableId(feature.id);
      }
    });
  }



}
