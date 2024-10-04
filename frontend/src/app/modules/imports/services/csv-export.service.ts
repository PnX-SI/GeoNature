import { Injectable } from '@angular/core';
import { saveAs } from 'file-saver';
import { ImportDataService } from './data.service';
import { CommonService } from '@geonature_common/service/common.service';

@Injectable()
export class CsvExportService {
  historyId: any;
  n_invalid: any;
  csvDownloadResp: any;

  constructor(
    private _ds: ImportDataService,
    private _commonService: CommonService
  ) {}

  onCSV(id_import) {
    // TODO: get filename from Content-Disposition
    let filename = 'invalid_data.csv';
    this._ds.getErrorCSV(id_import).subscribe((res) => {
      saveAs(res, filename);
    });
  }
}
