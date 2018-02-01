import { Component, OnInit, Input, OnChanges, Output, EventEmitter, AfterViewInit} from '@angular/core';
import { MapService } from '../map/map.service';
import {MapListService} from '../map-list/map-list.service';
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
  providers: [MapService],
})
export class MapListComponent implements OnInit, OnChanges, AfterViewInit {
  public layerDict: any;
  public selectedLayer: any;
  @Input() height: string;
  @Input() geojsonData: GeoJSON;
  @Input() idName: string;
  // configuration for action in the table
  public tableData = new Array();
  allColumns = [];


  constructor(private _ms: MapService, private mapListService: MapListService) {
  }

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
    layer.on({
      click : (e) => {
        // toggle style
        this.mapListService.toggleStyle(layer);
        // observable
        this.mapListService.mapSelected.next(feature.id);
        // open popup
        layer.bindPopup(feature.properties.leaflet_popup).openPopup();
      }
    });
  }

  ngOnChanges(changes) {
    if (changes.geojsonData.currentValue !== undefined) {
      this.mapListService.geojsonData = changes.geojsonData.currentValue;
      this.mapListService.loadTableData(changes.geojsonData.currentValue);
      const features = changes.geojsonData.currentValue.features;
    }
  }

}
