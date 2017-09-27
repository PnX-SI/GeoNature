import { Component, OnInit, Input, OnChanges} from '@angular/core';
import { MapService } from '../map/map.service';
import {MapListService} from '../map-list/map-list.service';
import { GeoJSON, Layer } from 'leaflet';


@Component({
  selector: 'pnx-map-list',
  templateUrl: './map-list.component.html',
  styleUrls: ['./map-list.component.scss'],
  providers: [MapService]
})
export class MapListComponent implements OnInit, OnChanges {
  public layerDict: any;
  public selectedLayer: any;
  @Input() geojsonData: GeoJSON;
  @Input() tableData = [];
  @Input() apiEndPoint: string;
  @Input() columns: Array<string>;
  @Input() pathRedirect: string;

  constructor(private _ms: MapService, private mapListService: MapListService) {
  }

  ngOnInit() {
    // event from the list
    this.mapListService.gettingLayerId$.subscribe(res => {
      const selectedLayer = this.mapListService.layerDict[res];
      this.mapListService.toggleStyle(selectedLayer);
      this.mapListService.zoomOnSelectedLayer(this._ms.map, selectedLayer);
    });
  }

  refreshValue(params) {
    this.mapListService.getData('contact/vrelevecontact', params)
      .subscribe(res => {
        this.mapListService.page.totalElements = res.total;
        this.geojsonData = res.items;
        this.tableData = this.mapListService.loadTableData(res.items);
      });

  }

  onEachFeature(feature, layer) {
    // event from the map
    this.mapListService.layerDict[feature.id] = layer;
    layer.on({
      click : (e) => {
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
      //this.mapListService.page.totalElements = changes.geojsonData.currentValue.features.length;
    }
  }

}
