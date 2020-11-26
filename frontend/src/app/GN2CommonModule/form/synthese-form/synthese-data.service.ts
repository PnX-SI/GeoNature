import { Injectable } from '@angular/core';
import {
  HttpClient,
  HttpParams,
  HttpHeaders,
  HttpEventType,
  HttpErrorResponse,
  HttpEvent
} from '@angular/common/http';
import { GeoJSON } from 'leaflet';
import { AppConfig } from '@geonature_config/app.config';
import { isArray } from 'util';
import { BehaviorSubject } from 'rxjs/BehaviorSubject';
import { CommonService } from '@geonature_common/service/common.service';
import { Observable } from 'rxjs';

export const FormatMapMime = new Map([
  ['csv', 'text/csv'],
  ['json', 'application/json'],
  ['shp', 'application/zip']
]);

@Injectable()
export class SyntheseDataService {
  public dataLoaded: Boolean = false;
  public isDownloading: Boolean = false;
  public downloadProgress: BehaviorSubject<number>;
  private _blob: Blob;
  constructor(private _api: HttpClient, private _commonService: CommonService) {
    this.downloadProgress = <BehaviorSubject<number>>new BehaviorSubject(0.0);
  }

  buildQueryUrl(params): HttpParams {
    let queryUrl = new HttpParams();
    for (let key in params) {
      if (isArray(params[key])) {
        params[key].forEach(value => {
          queryUrl = queryUrl.append(key, value);
        });
      } else {
        queryUrl = queryUrl.set(key, params[key]);
      }
    }
    return queryUrl;
  }

  getTaxons() {
    return this._api.get<any>(`${AppConfig.API_ENDPOINT}/occtax/releves`);
  }

  getSyntheseData(params) {
    return this._api.post<any>(`${AppConfig.API_ENDPOINT}/synthese/for_web`, params);
  }

  getSyntheseGeneralStat() {
    return this._api.get<any>(`${AppConfig.API_ENDPOINT}/synthese/general_stats`);
  }

  getOneSyntheseObservation(id_synthese) {
    return this._api.get<any>(`${AppConfig.API_ENDPOINT}/synthese/vsynthese/${id_synthese}`);
  }

  // validation data
  getDefinitionData() {
    return this._api.get<any>(`${AppConfig.API_ENDPOINT}/validation/definitions`);
  }

  getStatusNames() {
    return this._api.get<any>(`${AppConfig.API_ENDPOINT}/validation/statusNames`);
  }

  getTaxonTree() {
    return this._api.get<any>(`${AppConfig.API_ENDPOINT}/synthese/taxons_tree`);
  }

  downloadObservations(idSyntheseList: Array<number>, format: string) {
    this.isDownloading = true;
    const queryString = new HttpParams().set('export_format', format);

    const source = this._api.post(
      `${AppConfig.API_ENDPOINT}/synthese/export_observations`,
      idSyntheseList,
      {
        params: queryString,
        headers: new HttpHeaders().set('Content-Type', 'application/json'),
        observe: 'events',
        responseType: 'blob',
        reportProgress: true
      }
    );

    this.subscribeAndDownload(source, 'synthese_observations', format);
  }

  downloadTaxons(idSyntheseList: Array<number>, format: string, filename: string) {
    this.isDownloading = true;

    const source = this._api.post(
      `${AppConfig.API_ENDPOINT}/synthese/export_taxons`,
      idSyntheseList,
      {
        headers: new HttpHeaders().set('Content-Type', 'application/json'),
        observe: 'events',
        responseType: 'blob',
        reportProgress: true
      }
    );

    this.subscribeAndDownload(source, filename, format);
  }

  downloadStatusOrMetadata(url: string, format: string, postParams: any, filename: string) {
    this.isDownloading = true;

    const source = this._api.post(`${url}`, postParams, {
      headers: new HttpHeaders().set('Content-Type', `${FormatMapMime.get(format)}`),
      observe: 'events',
      responseType: 'blob',
      reportProgress: true
    });
    this.subscribeAndDownload(source, filename, format);
  }

  downloadUuidReport(filename: string, args: { [key: string]: string }) {
    let queryString: HttpParams = new HttpParams();
    // tslint:disable-next-line:forin
    for (const key in args) {
      queryString = queryString.set(key, args[key].toString());
    }
    const source = this._api.get(`${AppConfig.API_ENDPOINT}/meta/uuid_report`, {
      headers: new HttpHeaders().set('Content-Type', 'text/csv'),
      observe: 'events',
      responseType: 'blob',
      reportProgress: true,
      params: queryString
    });
    this.subscribeAndDownload(source, filename, "csv", false);
  }

  downloadSensiReport(filename: string, args: { [key: string]: string }) {
    let queryString: HttpParams = new HttpParams();
    // tslint:disable-next-line:forin
    for (const key in args) {
      queryString = queryString.set(key, args[key].toString());
    }
    const source = this._api.get(`${AppConfig.API_ENDPOINT}/meta/sensi_report`, {
      headers: new HttpHeaders().set('Content-Type', 'text/csv'),
      observe: 'events',
      responseType: 'blob',
      reportProgress: true,
      params: queryString
    });
    this.subscribeAndDownload(source, filename, "csv", false);
  }

  subscribeAndDownload(
    source: Observable<HttpEvent<Blob>>,
    fileName: string,
    format: string,
    addDateToFilename: boolean = true
  ): void {
    const subscription = source.subscribe(
      event => {
        if (event.type === HttpEventType.Response) {
          this._blob = new Blob([event.body], { type: event.headers.get('Content-Type') });
        }
      },
      (e: HttpErrorResponse) => {
        this._commonService.translateToaster('error', 'ErrorMessage');
        this.isDownloading = false;
      },
      // response OK
      () => {
        this.isDownloading = false;
        const date = new Date();
        const extension = format === 'shapefile' ? 'zip' : format;
        this.saveBlob(this._blob,
          `${fileName}${addDateToFilename ? '_' + date.toISOString() : ''}.${extension}`
        );
        subscription.unsubscribe();
      }
    );
  }

  saveBlob(blob, filename) {
    const link = document.createElement('a');
    link.href = URL.createObjectURL(blob);
    link.setAttribute('visibility', 'hidden');
    link.download = filename;
    link.onload = () => {
      URL.revokeObjectURL(link.href);
    };
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  }
}
