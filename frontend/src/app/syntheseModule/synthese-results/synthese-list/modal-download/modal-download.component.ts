import { Component, Input } from '@angular/core';
import { NgbActiveModal } from '@ng-bootstrap/ng-bootstrap';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { SyntheseStoreService } from '../../../services/store.service';
import { SyntheseFormService } from '@geonature_common/form/synthese-form/synthese-form.service';
import { ConfigService } from '@geonature/services/config.service';

@Component({
  selector: 'pnx-synthese-modal-download',
  templateUrl: 'modal-download.component.html',
})
export class SyntheseModalDownloadComponent {
  public syntheseConfig = null;

  @Input() tooManyObs = false;

  constructor(
    public activeModal: NgbActiveModal,
    public _dataService: SyntheseDataService,
    private _fs: SyntheseFormService,
    private _storeService: SyntheseStoreService,
    public config: ConfigService
  ) {
    this.syntheseConfig = this.config.SYNTHESE;
  }

  downloadObservations(format, view_name) {
    this._dataService.downloadObservations(this._storeService.idSyntheseList, format, view_name);
  }

  downloadTaxons(format, filename) {
    this._dataService.downloadTaxons(this._storeService.idSyntheseList, format, filename);
  }

  downloadStatusOrMetadata(url, filename) {
    const params = this._fs.formatParams();
    this._dataService.downloadStatusOrMetadata(
      `${this.config.API_ENDPOINT}/${url}`,
      'csv',
      params,
      filename
    );
  }
}
