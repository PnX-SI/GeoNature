import { Injectable } from '@angular/core';
import { Subject, Observable } from 'rxjs';
import { HttpClient, HttpParams } from '@angular/common/http';
import { CommonService } from '@geonature_common/service/common.service';
import * as L from 'leaflet';
import { UntypedFormControl } from '@angular/forms';
import { MapService } from '@geonature_common/map/map.service';
import { Map } from 'leaflet';
import { delay, finalize } from 'rxjs/operators';
import { ConfigService } from '@geonature/services/config.service';

@Injectable()
export class MapListService {
  public tableSelected = new Subject<any>();
  public mapSelected = new Subject<any>();
  public onMapClik$: Observable<string> = this.mapSelected.asObservable();
  public onTableClick$: Observable<number> = this.tableSelected.asObservable();
  public currentIndexRow = new Subject<number>();
  public currentIndexRow$: Observable<number> = this.currentIndexRow.asObservable();

  public selectedRow = [];
  public data: any;
  public tableData = new Array();
  public geojsonData: any;
  public idName: string;
  public columns = [];
  public layerDict = {};
  public selectedLayer: any;
  public endPoint: string;

  public urlQuery: HttpParams = new HttpParams();
  public page = new Page();
  public genericFilterInput = new UntypedFormControl();
  public isLoading = false;
  public zoomOnLayer = false;
  filterableColumns: Array<any>;
  availableColumns: Array<any>;
  displayColumns: Array<any>;
  colSelected: any;
  allColumns: Array<any>;
  customCallBack: any;

  originStyle = {
    color: '#3388ff',
    fill: false,
    fillOpacity: 0.2,
    weight: 3,
  };

  selectedStyle = {
    color: '#ff0000',
    weight: 3,
    fill: true,
  };

  constructor(
    private _http: HttpClient,
    private _ms: MapService,
    public config: ConfigService
  ) {
    this.columns = [];
    this.page.pageNumber = 0;
    this.page.size = 12;
    this.urlQuery.set('limit', '12');
    this.urlQuery.set('offset', '0');
    this.colSelected = { prop: '', name: '' };
  }

  onTableClick(map: Map): void {
    // On table click, change style layer and zoom
    this.onTableClick$.subscribe((id) => {
      const selectedLayer = this.layerDict[id];
      this.toggleStyle(selectedLayer);
      this.zoomOnSelectedLayer(map, selectedLayer);
      selectedLayer.bringToFront();
    });
  }

  onMapClick(): void {
    this.onMapClik$.subscribe((id) => {
      this.selectedRow = []; // clear selected list

      const integerId = parseInt(id);
      // const integerId = parseInt(id);
      let i;
      for (i = 0; i < this.tableData.length; i++) {
        if (this.tableData[i][this.idName] === integerId) {
          this.selectedRow.push(this.tableData[i]);
          break;
        }
      }
      this.currentIndexRow.next(i);
    });
  }

  enableMapListConnexion(map: Map): void {
    // do the connexion between map and list
    this.onTableClick(map);
    this.onMapClick();
  }

  onRowSelect(row) {
    // row can be an object from ngx-datatable or an integer
    if (row instanceof Object && row.selected.length > 0) {
      this.tableSelected.next(row.selected[0][this.idName]);
    } else {
      this.tableSelected.next(row);
    }
  }

  /** Search a row in the table data and return its page */
  foundARowAndPage(id, rowNumber) {
    this.selectedRow = []; // clear selected list

    const integerId = parseInt(id);
    let i;
    for (i = 0; i < this.tableData.length; i++) {
      if (this.tableData[i]['id'] === integerId) {
        this.selectedRow.push(this.tableData[i]);
        break;
      }
    }
    return Math.trunc(i / rowNumber);
  }

  getRowClass() {
    return 'clickable';
  }

  setTablePage(pageInfo, endPoint) {
    this.page.pageNumber = pageInfo.offset;
    this.urlQuery = this.urlQuery.set('offset', pageInfo.offset);
    this.refreshData(endPoint, 'set');
  }

  // fetch the data
  dataService() {
    this.isLoading = true;
    return this._http
      .get<any>(`${this.config.API_ENDPOINT}/${this.endPoint}`, { params: this.urlQuery })
      .pipe(
        delay(200),
        finalize(() => (this.isLoading = false))
      );
  }

  loadData() {
    this.dataService().subscribe((data) => {
      this.page.totalElements = data.total;
      this.page.itemPerPage = parseInt(this.urlQuery.get('limit'));
      this.page.pageNumber = data.page;
      this.geojsonData = data.items;
      this.loadTableData(data.items, this.customCallBack);
    });
  }

  getData(endPoint, param?: Array<any>, customCallBack?) {
    //  params: parameter to filter on the api
    //  customCallBack: function which return a feature to custom the content of the table
    this.manageUrlQuery('set', param);
    this.customCallBack = customCallBack;
    this.endPoint = endPoint;
    this.loadData();
  }

  refreshData(apiEndPoint, method, params?: Array<any>) {
    this.manageUrlQuery(method, params);
    if (apiEndPoint !== null && this.endPoint !== apiEndPoint) {
      this.endPoint = apiEndPoint;
    }
    this.loadData();
  }

  manageUrlQuery(method, params?: Array<any>) {
    // set or append a param to urlQuery
    if (params) {
      if (method === 'set') {
        params.forEach((param) => {
          this.setHttpParam(param.param, param.value);
        });
      } else {
        params.forEach((param) => {
          this.appendHttpParam(param.param, param.value);
        });
      }
    }
  }

  setHttpParam(param, value) {
    this.urlQuery = this.urlQuery.set(param, value);
  }

  appendHttpParam(param, value) {
    this.urlQuery = this.urlQuery.append(param, value);
  }

  deleteHttpParam(param, value = undefined) {
    this.urlQuery = this.urlQuery.delete(param, value);
  }

  refreshUrlQuery(limit?: number) {
    this.urlQuery = new HttpParams();
    if (limit) {
      this.urlQuery = this.urlQuery.set('limit', limit.toString());
    }
  }

  deleteAndRefresh(apiEndPoint, param) {
    this.urlQuery = this.urlQuery.delete(param);
    this.refreshData(apiEndPoint, 'set');
  }

  deleteObsFront(idDelete: number) {
    // supprimer une observation sur la carte et la liste en front seulement
    this.tableData = this.tableData.filter((row) => {
      return row[this.idName] !== idDelete;
    });

    this.geojsonData.features = this.geojsonData.features.filter((row) => {
      return row['id'] !== idDelete.toString();
    });
    this.geojsonData = Object.assign({}, this.geojsonData);
  }

  toggleStyle(selectedLayer) {
    // togle the style of selected layer

    if (this.selectedLayer !== undefined) {
      this.selectedLayer.setStyle(this.originStyle);
      this.selectedLayer.closePopup();
    }
    this.selectedLayer = selectedLayer;

    this.selectedStyle.fill =
      this.selectedLayer.feature.geometry.type === 'LineString' ||
      this.selectedLayer.feature.geometry.type === 'MultiLineString'
        ? false
        : true;
    this.selectedLayer.setStyle(this.selectedStyle);
  }

  zoomOnSelectedLayer(map, layer) {
    const tempFeatureGroup = new L.FeatureGroup();
    tempFeatureGroup.addLayer(layer);
    map.fitBounds(tempFeatureGroup.getBounds(), { maxZoom: 15 });
  }

  zoomOnSeveralSelectedLayers(map, layers) {
    let group = new L.FeatureGroup();
    layers.forEach((layer) => {
      this.layerDict[layer];
      group.addLayer(this.layerDict[layer]);
    });

    this._ms.getMap().fitBounds(group.getBounds());
  }

  /**
   * Use in synthese where layer are not GeoJson but PolyLigne, Polygon ...
   * @param map
   * @param layer
   */
  zoomOnSelectedLayerNotGeojson(map, layer) {
    if (layer) {
    }
  }

  deFaultCustomColumns(feature) {
    return feature;
  }

  loadTableData(data, customCallBack?) {
    this.tableData = [];
    if (customCallBack) {
      data.features.forEach((feature) => {
        let newFeature = null;
        if (customCallBack) {
          newFeature = customCallBack(feature);
        }
        this.tableData.push(newFeature.properties);
      });
    } else {
      data.features.forEach((feature) => {
        this.tableData.push(feature.properties);
      });
    }
    this.tableData = [...this.tableData];
  }
}

export class Page {
  // The number of elements in the page
  size: number = 5;
  // The total number of elements
  totalElements: number = 0;
  // The total number of elements
  itemPerPage: number = 0;
  // The total number of pages
  totalPages: number = 2;
  // The current page number
  pageNumber: number = 0;
}
