import { Injectable} from '@angular/core';
import { Subject } from 'rxjs/Subject';
import { Http } from '@angular/http';
import { AppConfig } from '../../../conf/app.config';
import { Observable } from 'rxjs';
import * as L from 'leaflet';
import { URLSearchParams } from '@angular/http';
@Injectable()
export class MapListService {
  private _layerId = new Subject<any>();
  private _tableId = new Subject<any>();
  public columns = [];
  public layerDict= {};
  public selectedLayer: any;
  public gettingLayerId$: Observable<number> = this._layerId.asObservable();
  public gettingTableId$: Observable<number> = this._tableId.asObservable();
  public urlQuery: URLSearchParams = new URLSearchParams ();
  public page = new Page();
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
    constructor(private _http: Http) {
      this.columns = [];
      this.page.pageNumber = 0;
      this.page.size = 15;
      this.urlQuery.set('limit', '15');
      this.urlQuery.set('offset', '0');

  }

  getData(endPoint, param?) {
    if (param) {
      console.log(param);
      if (param.param === 'offset') {
        this.urlQuery.set('offset', param.value);
      }else {
        this.urlQuery.append(param.param, param.value);
        console.log(this.urlQuery.toString());

      }

    }
    return this._http.get(`${AppConfig.API_ENDPOINT}${endPoint}`, {search: this.urlQuery})
      .map(res => res.json());
  }


  setCurrentLayerId(id: number) {
    this._layerId.next(id);
  }

  setCurrentTableId(id: number) {
    this._tableId.next(id);
  }

  toggleStyle(selectedLayer) {
    // togle the style of selected layer
    if ( this.selectedLayer !== undefined) {
      this.selectedLayer.setStyle(this.originStyle);
      this.selectedLayer.closePopup();
    }
    this.selectedLayer = selectedLayer;
    this.selectedLayer.setStyle(this.selectedStyle);
  }

  zoomOnSelectedLayer(map, layer) {
    const zoom = map.getZoom();
    // latlng is different between polygons and point
    let latlng;

    if(layer instanceof L.Polygon || layer instanceof L.Polyline){
      latlng = (layer as any)._bounds._northEast;
    }else {
      latlng = layer._latlng;
    }
    if (zoom >= 12) {
      map.setView(latlng, zoom);
    } else {
      map.setView(latlng, 12);
  }
  }

  loadTableData(data) {
    console.log(data);
    const tableData = [];
    data.features.forEach(feature => {
      const obj = feature.properties;
      obj['id'] = feature.id;
      tableData.push(obj);
    });
    return tableData;
  }

}


export class Page {
  // The number of elements in the page
  size: number = 5;
  // The total number of elements
  totalElements: number = 0;
  // The total number of pages
  totalPages: number = 2;
  // The current page number
  pageNumber: number = 0;
}