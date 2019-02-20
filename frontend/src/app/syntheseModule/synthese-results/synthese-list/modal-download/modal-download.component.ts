import { Component, OnInit, Input } from '@angular/core';
import { AppConfig } from '@geonature_config/app.config';
import { HttpParams } from '@angular/common/http';
import { NgbActiveModal } from '@ng-bootstrap/ng-bootstrap';
import { DataService } from '../../../services/data.service';
import { SyntheseStoreService } from '../../../services/store.service';

@Component({
  selector: 'pnx-synthese-modal-download',
  templateUrl: 'modal-download.component.html'
})
export class SyntheseModalDownloadComponent implements OnInit {
  public syntheseConfig = AppConfig.SYNTHESE;

  @Input() queryString: HttpParams;
  @Input() tooManyObs = false;

  constructor(
    public activeModal: NgbActiveModal,
    private _dataService: DataService,
    private _storeService: SyntheseStoreService
  ) {}

  ngOnInit() {}

  downloadObservations(format) {
    this._dataService.downloadObservations(this._storeService.idSyntheseList, format);
  }

  downloadStatusOrMetadata(url, filename) {
    this.queryString = this.queryString.delete('limit');
    this._dataService.downloadStatusOrMetadata(
      `${AppConfig.API_ENDPOINT}/${url}`,
      'csv',
      this.queryString,
      filename
    );
  }
}
