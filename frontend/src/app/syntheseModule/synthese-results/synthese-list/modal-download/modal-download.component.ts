import { Component, OnInit, Input } from '@angular/core';
import { AppConfig } from '@geonature_config/app.config';
import { HttpParams } from '@angular/common/http';
import { NgbActiveModal } from '@ng-bootstrap/ng-bootstrap';

@Component({
  selector: 'pnx-synthese-modal-download',
  templateUrl: 'modal-download.component.html'
})
export class SyntheseModalDownloadComponent implements OnInit {
  public syntheseConfig = AppConfig.SYNTHESE;
  @Input() queryString: HttpParams;
  @Input() tooManyObs = false;

  constructor(public activeModal: NgbActiveModal) {}

  ngOnInit() {
    console.log(this.queryString);
  }

  loadData(format) {
    this.queryString = this.queryString.set('export_format', format);
    document.location.href = `${
      AppConfig.API_ENDPOINT
    }/synthese/export?${this.queryString.toString()}`;
    this.activeModal.close();
  }

  downloadStatus() {
    document.location.href = `${
      AppConfig.API_ENDPOINT
    }/synthese/statuts?${this.queryString.toString()}`;
    this.activeModal.close();
  }
}
