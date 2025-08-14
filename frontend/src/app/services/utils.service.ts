import {Injectable} from "@angular/core";
import {ConfigService} from "@geonature/services/config.service";
import {HttpClient} from "@angular/common/http";
import {map} from "rxjs/operators";

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
    return this._http.get<any>(`${this.config.API_ENDPOINT}/taxhub${this.config.TAXHUB.API_PREFIX}/taxref/version`)
      .pipe(
        map(data => ({[data.referencial_name]: data.version}))
      );
  }
}
