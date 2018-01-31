import { Injectable} from '@angular/core';
import { Subject } from 'rxjs/Subject';
import { HttpClient, HttpParams } from '@angular/common/http';
import { AppConfig } from '../../../conf/app.config';
import { Observable } from 'rxjs';
import { CommonService } from '@geonature_common/service/common.service';
import * as L from 'leaflet';
@Injectable()
export class MapListService {
  private _layerId = new Subject<any>();
  private _tableId = new Subject<any>();
  public data: any;
  public tableData = new Array();
  public geojsonData: any;
  public idName: string;
  public columns = [];
  public layerDict= {};
  public selectedLayer: any;
  public gettingLayerId$: Observable<number> = this._layerId.asObservable();
  public gettingTableId$: Observable<number> = this._tableId.asObservable();
  public urlQuery: HttpParams = new HttpParams ();
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
    constructor(
      private _http: HttpClient,
      private _commonService: CommonService
    ) {
      this.columns = [];
      this.page.pageNumber = 0;
      this.page.size = 15;
      this.urlQuery.set('limit', '15');
      this.urlQuery.set('offset', '0');

  }

  getData(endPoint, param?) {
    if (param) {
      if (param.param === 'offset') {
        this.urlQuery = this.urlQuery.set('offset', param.value);
      }else {
        this.urlQuery = this.urlQuery.append(param.param, param.value);
      }
    }
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/${endPoint}`, {params: this.urlQuery});
  }

  refreshData(apiEndPoint, params?) {
    this.getData(apiEndPoint, params)
      .subscribe(
        res => {
          this.page.totalElements = res.total_filtered;
          this.geojsonData = res.items;
          this.loadTableData(res.items);
        },
        err => {
          console.log(err.error.error);
          this._commonService.regularToaster('error', err.error.error);
          this._commonService.translateToaster('error', 'InvalidTypeError');
        }
    );
  }

  deleteAndRefresh(apiEndPoint, param) {
    this.urlQuery = this.urlQuery.delete(param);
    this.refreshData(apiEndPoint);
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
    this.tableData = [];
    data.features.forEach(feature => {
      this.tableData.push(feature.properties);
    });
  }

  deleteObs(idDelete) {
    this.tableData = this.tableData.filter(row => {
      return row[this.idName] !==  idDelete;
    });

    this.geojsonData.features = this.geojsonData.features.filter(row => {
       return row.properties[this.idName] !==  idDelete;
     });

     this.geojsonData = JSON.parse(JSON.stringify(this.geojsonData));

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