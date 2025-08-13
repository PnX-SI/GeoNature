import {Injectable} from "@angular/core";
import {ConfigService} from "@geonature/services/config.service";
import {HttpClient} from "@angular/common/http";

@Injectable({
  providedIn: 'root',
})
export class UtilsService {

  constructor(
    private _http: HttpClient,
    public config: ConfigService
  ) {
  }

  getRefVersion() {
    return this._http.get<any>(`${this.config.API_ENDPOINT}/gn_commons/ref_info`);
  }
}
