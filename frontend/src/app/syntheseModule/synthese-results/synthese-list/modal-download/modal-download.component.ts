import { Component, OnInit, Input } from '@angular/core';
import { AppConfig } from '@geonature_config/app.config';
import { HttpParams } from '@angular/common/http';
import { NgbActiveModal } from '@ng-bootstrap/ng-bootstrap';
import { DataService } from '../../../services/data.service';

@Component({
  selector: 'pnx-synthese-modal-download',
  templateUrl: 'modal-download.component.html'
})
export class SyntheseModalDownloadComponent implements OnInit {
  public syntheseConfig = AppConfig.SYNTHESE;

  @Input() queryString: HttpParams;
  @Input() tooManyObs = false;

  constructor(public activeModal: NgbActiveModal, private _dataService: DataService) { }

  ngOnInit() { }



  downloadData(format) {
    const downloadURL = this.queryString.set('export_format', format);
    const url = `${AppConfig.API_ENDPOINT}/synthese/export`;
    this._dataService.downloadData(url, format, downloadURL, 'export_synthese_observations');
  }

  downloadStatus() {
    this.queryString = this.queryString.delete('limit');
    const url = `${AppConfig.API_ENDPOINT}/synthese/statuts`;
    this._dataService.downloadData(url, 'csv', this.queryString, 'export_synthese_statuts');
  }
}
