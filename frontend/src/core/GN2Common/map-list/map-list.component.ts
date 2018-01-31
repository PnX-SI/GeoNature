import { Component, OnInit, Input, OnChanges, Output, EventEmitter, ViewEncapsulation} from '@angular/core';
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
  encapsulation: ViewEncapsulation.None
})
export class MapListComponent implements OnInit, OnChanges {
  public layerDict: any;
  public selectedLayer: any;
  @Input() geojsonData: GeoJSON;
  @Input() idName: string;
  @Input() apiEndPoint: string;
  @Input() displayColumns: Array<any>;
  @Output() onEdit = new EventEmitter<number>();
  @Output() onDetail = new EventEmitter<number>();
  @Input() pathDelete: string;
  // configuration for action in the table
  @Input() columnActions: ColumnActions;
  @Output() onDeleteRow = new EventEmitter<number>();
  public tableData = new Array();
  allColumns = [];

  constructor(private _ms: MapService, private mapListService: MapListService) {
  }

  ngOnInit() {

    // event from the list
    this.mapListService.gettingLayerId$.subscribe(res => {
      const selectedLayer = this.mapListService.layerDict[res];
      this.mapListService.toggleStyle(selectedLayer);
      this.mapListService.zoomOnSelectedLayer(this._ms.map, selectedLayer);
    });
    // set the idName in the service
    this.mapListService.idName = this.idName;
  }

  handleEdit(id) {
    this.onEdit.emit(id);
  }

  handleDetail(id) {
    this.onDetail.emit(id);
  }

  deleteRow(idRow) {
    this.onDeleteRow.emit(idRow);
  }


  onEachFeature(feature, layer) {
    // event from the map
    this.mapListService.layerDict[feature.id] = layer;
    layer.on({
      click : (e) => {
        console.log("click");
        
        // toggle style
        this.mapListService.toggleStyle(layer);
        // observable
        this.mapListService.setCurrentTableId(feature.id);
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
      const keyColumns = [];
      if (features.length > 0) {
      // tslint:disable-next-line
        for (let key in features[0].properties){
          keyColumns.push({prop: key, name: key});
        }
        // sort the columns
        keyColumns.sort(function(a, b) {
          const nameA = a.name.toUpperCase(); // ignore upper and lowercase
          const nameB = b.name.toUpperCase(); // ignore upper and lowercase
          if (nameA < nameB) {
            return -1;
          }
          if (nameA > nameB) {
            return 1;
          }
          // names must be equal
          return 0;
        });
        this.allColumns = keyColumns;
      }

    }
  }

}
