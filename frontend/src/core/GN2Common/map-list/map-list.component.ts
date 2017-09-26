import { Component, OnInit, Input} from '@angular/core';
import { MapService } from '../map/map.service';
import {MapListService} from '../map-list/map-list.service';
import { GeoJSON, Layer } from 'leaflet';


@Component({
  selector: 'pnx-map-list',
  templateUrl: './map-list.component.html',
  styleUrls: ['./map-list.component.scss'],
  providers: [MapService]
})
export class MapListComponent implements OnInit {
  public layerDict: any;
  public selectedLayer: any;
  public geojsonData: GeoJSON;
  public  tableData = [];
  public formatedColumns = [];
  @Input() apiEndPoint: string;
  @Input() columns: Array<string>;


  constructor(private _ms: MapService, private _mapListService: MapListService) {
  }

  ngOnInit() {
    this._mapListService.getData(this.apiEndPoint)
      .subscribe(res => {
        this.geojsonData = res;
        res.features.forEach(feature => {
          const obj = feature.properties;
          obj['id'] = feature.id;
          this.tableData.push(obj);
        });
      });

    // event from the list
    this._mapListService.gettingLayerId$.subscribe(res => {
      const selectedLayer = this._mapListService.layerDict[res];
      this._mapListService.toggleStyle(selectedLayer);
      this._mapListService.zoomOnSelectedLayer(this._ms.map, selectedLayer);
    });
  }

  onEachFeature(feature, layer) {
    // event from the map
    this._mapListService.layerDict[feature.id] = layer;
    layer.on({
      click : (e) => {
        // toggle style
        this._mapListService.toggleStyle(layer);
        // observable
        this._mapListService.setCurrentTableId(feature.id);
        // open popup
        console.log(feature);

        layer.bindPopup(feature.properties.leaflet_popup).openPopup();
      }
    });
  }




}
