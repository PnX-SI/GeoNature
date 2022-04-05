import { Component, Input } from '@angular/core';
import { AppConfig } from '@geonature_config/app.config';
import { NgbActiveModal } from '@ng-bootstrap/ng-bootstrap';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { SyntheseStoreService } from '@geonature_common/form/synthese-form/synthese-store.service';
import { SyntheseFormService } from '@geonature_common/form/synthese-form/synthese-form.service';

@Component({
  selector: 'pnx-synthese-modal-download',
  templateUrl: 'modal-download.component.html',
})
export class SyntheseModalDownloadComponent {
  public syntheseConfig = AppConfig.SYNTHESE;

  @Input() tooManyObs = false;

  constructor(
    public activeModal: NgbActiveModal,
    public _dataService: SyntheseDataService,
    private _fs: SyntheseFormService,
    private _storeService: SyntheseStoreService
  ) {}

  downloadObservations(format) {
    this._dataService.downloadObservations(this._storeService.idSyntheseList, format);
  }

  downloadTaxons(format, filename) {
    this._dataService.downloadTaxons(this._storeService.idSyntheseList, format, filename);
  }

  downloadStatusOrMetadata(url, filename) {
    const params = this._fs.formatParams();
    this._dataService.downloadStatusOrMetadata(
      `${AppConfig.API_ENDPOINT}/${url}`,
      'csv',
      params,
      filename
    );
  }
}
