import { Component, OnInit, Input } from '@angular/core';
import { AppConfig } from '@geonature_config/app.config';
import { HttpParams } from '@angular/common/http';
import { NgbActiveModal } from '@ng-bootstrap/ng-bootstrap';
import { DataService } from '../../../services/data.service';
import { Observable } from 'rxjs/Observable';

@Component({
  selector: 'pnx-synthese-modal-download',
  templateUrl: 'modal-download.component.html'
})
export class SyntheseModalDownloadComponent implements OnInit {
  public syntheseConfig = AppConfig.SYNTHESE;
  progress$: Observable<number>
  message = "Téléchargement en cours";
  type = 'info';
  animated = true;
  public downloading: boolean = false;
  @Input() queryString: HttpParams;
  @Input() tooManyObs = false;

  constructor(public activeModal: NgbActiveModal, private _dataService: DataService) { }

  ngOnInit() {
    this.progress$ = this._dataService.downloadProgress;
    // this.progress$.subscribe( state =>  {
    //   (state === 100) ? this.done() : null;
    // )};
    this.progress$.subscribe(state => {
      console.log(state);
      if (state === 100) {
        this.done();
      }
    })
  }

  progress() {
    this._dataService.downloadProgress.next(0.0);
    this.message = "Téléchargement en cours";
    this.animated = true;
    this.type = 'info';
  }

  done() {
    this.message = 'Export téléchargé.'
    this.type = 'success';
    this.animated = false;
  }

  downloadData(format) {
    this.downloading = true;
    this.progress();
    const downloadURL = this.queryString.set('export_format', format);
    const url = `${AppConfig.API_ENDPOINT}/synthese/export`;
    this._dataService.downloadData(url, format, downloadURL, 'export_synthese_observations');

  }

  downloadStatus() {
    this.downloading = true;
    this.progress();
    const url = `${AppConfig.API_ENDPOINT}/synthese/statuts`;
    this._dataService.downloadData(url, 'csv', this.queryString, 'export_synthese_statuts');
  }
}
