import { Component, OnInit, Input, EventEmitter, Output } from '@angular/core';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import {
  HttpClient,
  HttpParams,
  HttpEvent,
  HttpHeaders,
  HttpRequest,
  HttpEventType,
  HttpErrorResponse
} from '@angular/common/http';
import { BehaviorSubject } from 'rxjs/BehaviorSubject';
import { CommonService } from '@geonature_common/service/common.service';

export const FormatMapMime = new Map([
  ['csv', 'text/csv'],
  ['json', 'application/json'],
  ['shp', 'application/zip']
]);

@Component({
  selector: 'pnx-modal-download',
  templateUrl: 'modal-download.component.html',
  styleUrls: ['./modal-download.component.scss']
})
export class ModalDownloadComponent implements OnInit {
  @Input() pathDownload: string;
  @Input() queryString: HttpParams;
  @Input() exportFormat: Array<string>;
  @Input() labelButton: string;
  @Input() downloadMessage: string;
  @Output() buttonClicked = new EventEmitter<any>();
  public downloadProgress$: BehaviorSubject<number>;
  public isDownloading: boolean = false;
  private _blob: Blob;
  public message = 'Téléchargement en cours';
  public type = 'info';
  public animated = true;
  public endLoad: boolean = false;
  constructor(
    private _modalService: NgbModal,
    private _api: HttpClient,
    private _commonService: CommonService
  ) {
    this.downloadProgress$ = <BehaviorSubject<number>>new BehaviorSubject(0.0);
    this.downloadProgress$.subscribe(state => {
      if (state === 100) {
        this.done();
        this.endLoad = true;
      }
    });
  }

  ngOnInit() {
    this.labelButton = this.labelButton || 'Télécharger';
    this.queryString = this.queryString || new HttpParams();
  }

  loadData(format) {
    this.isDownloading = true;
    this.progress();
    this.queryString = this.queryString.set('export_format', format);
    document.location.href = `${this.pathDownload}?${this.queryString.toString()}`;
    this.donwloadStatus(this.pathDownload, format, this.queryString);
  }

  openModal(content) {
    this._modalService.open(content);
    this.buttonClicked.emit();
  }

  donwloadStatus(url: string, format: string, queryString: HttpParams) {
    this.isDownloading = true;
    const source = this._api.get(`${url}?${queryString.toString()}`, {
      headers: new HttpHeaders().set('Content-Type', `${FormatMapMime.get(format)}`),
      observe: 'events',
      responseType: 'blob',
      reportProgress: true
    });

    const subscription = source.subscribe(
      event => {
        switch (event.type) {
          case HttpEventType.DownloadProgress:
            if (event.hasOwnProperty('total')) {
              const percentage = Math.round(100 / event.total * event.loaded);
              this.downloadProgress$.next(percentage);
            } else {
              const kb = (event.loaded / 1024).toFixed(2);
              this.downloadProgress$.next(parseFloat(kb));
            }
            break;
          case HttpEventType.Response:
            this._blob = new Blob([event.body], { type: event.headers.get('Content-Type') });
            break;
        }
      },
      (e: HttpErrorResponse) => {
        this._commonService.translateToaster('error', 'ErrorMessage');
        this.isDownloading = false;
      },
      () => {
        this.isDownloading = false;
        subscription.unsubscribe();
      }
    );
  }

  progress() {
    this.downloadProgress$.next(0.0);
    this.message = 'Téléchargement en cours';
    this.type = 'info';
    this.animated = true;
  }

  done() {
    this.message = 'Export téléchargé avec succès ! Veuillez patienter ...  ';
    this.type = 'success';
    this.animated = false;
  }
}
