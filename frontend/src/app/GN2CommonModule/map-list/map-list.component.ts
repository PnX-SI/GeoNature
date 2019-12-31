import { Component, OnInit, Input, AfterViewInit } from '@angular/core';
import { MapService } from '../map/map.service';
import { MapListService } from '../map-list/map-list.service';
import { GeoJSON, Layer } from 'leaflet';

export interface ColumnActions {
  editColumn: boolean;
  infoColumn: boolean;
  deleteColumn: boolean;
  validateColumn: boolean;
  unValidateColumn: boolean;
}

@Component({
  selector: 'pnx-map-list',
  templateUrl: './map-list.component.html',
  styleUrls: ['./map-list.component.scss'],
  providers: [MapService]
})
export class MapListComponent implements OnInit, AfterViewInit {
  public layerDict: any;
  public selectedLayer: any;
  @Input() height: string;
  @Input() idName: string;

  constructor(private _ms: MapService, public mapListService: MapListService) {}

  ngOnInit() {
    // set the idName in the service
    this.mapListService.idName = this.idName;
  }

  ngAfterViewInit() {
    // event from the list
    this.mapListService.enableMapListConnexion(this._ms.getMap());
  }

  onEachFeature(feature, layer) {
    // event from the map
    this.mapListService.layerDict[feature.id] = layer;
    layer.setStyle(this.mapListService.originStyle);
    layer.on({
      click: e => {
        // toggle style
        this.mapListService.toggleStyle(layer);
        // observable
        this.mapListService.mapSelected.next(feature.id);
        // open popup
        if (feature.properties.leaflet_popup) {
          layer.bindPopup(feature.properties.leaflet_popup).openPopup();
        }
      }
    });
  }
}
