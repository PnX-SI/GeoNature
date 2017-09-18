import { Injectable} from '@angular/core';
import { Subject } from 'rxjs/Subject';
import { Http, URLSearchParams } from '@angular/http';
import { AppConfig } from '../../../conf/app.config';
import { Observable } from 'rxjs';

@Injectable()
export class MapListService {
  private _layerId = new Subject<any>();
  public layerDict= {};
  public selectedLayer: any;
  public gettingLayerId$: Observable<number> = this._layerId.asObservable();
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
  }

getReleves() {
    return this._http.get(`${AppConfig.API_ENDPOINT}contact/releves`)
      .map(res => res.json());
  }

  setCurrentLayerId(id: number) {
    this._layerId.next(id);
  }
}
