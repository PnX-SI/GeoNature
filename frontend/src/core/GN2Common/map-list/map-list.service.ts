import { Injectable} from '@angular/core';
import { Subject } from 'rxjs/Subject';
import { Http, URLSearchParams } from '@angular/http';
import { AppConfig } from '../../../conf/app.config';

@Injectable()
export class MapListService {
    constructor(private _http: Http) {
  }

getReleves() {
    return this._http.get(`${AppConfig.API_ENDPOINT}contact/releves`)
      .map(res => res.json())
      .map(res => res.features);
  }
}
