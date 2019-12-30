import { Component, OnInit, Input } from '@angular/core';
import { AppConfig } from '@geonature_config/app.config';
import { HttpParams } from '@angular/common/http';
import { NgbActiveModal } from '@ng-bootstrap/ng-bootstrap';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { SyntheseStoreService } from '@geonature_common/form/synthese-form/synthese-store.service';

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
    public _dataService: SyntheseDataService,
    private _storeService: SyntheseStoreService
  ) {}

  ngOnInit() {}

  downloadObservations(format) {
    this._dataService.downloadObservations(this._storeService.idSyntheseList, format);
  }

  downloadTaxons(format, filename) {
    this._dataService.downloadTaxons(this._storeService.idSyntheseList, format, filename);
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
