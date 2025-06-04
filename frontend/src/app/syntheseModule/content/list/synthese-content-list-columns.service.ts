import { Injectable, OnInit } from '@angular/core';
import { ConfigService } from '@geonature/services/config.service';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';

@Injectable()
export class SyntheseContentListColumnsService {
  public defaultColumns: Array<any> = [];
  public availableColumns: Array<any> = [];

  constructor(
    private _config: ConfigService,
    public ngbModal: NgbModal
  ) {
    // initListColumns
    this.defaultColumns = this._config.SYNTHESE.LIST_COLUMNS_FRONTEND;
    let allColumnsTemp = [
      ...this._config.SYNTHESE.LIST_COLUMNS_FRONTEND,
      ...this._config.SYNTHESE.ADDITIONAL_COLUMNS_FRONTEND,
    ];
    this.availableColumns = allColumnsTemp.map((col) => {
      col['checked'] = this.defaultColumns.some((defcol) => {
        return defcol.name == col.name;
      });
      return col;
    });
  }

  toggleColumnNames(col) {
    col.checked = !col.checked;
    this.defaultColumns = this.availableColumns.filter((col) => col.checked);
  }

  openModal($event, modal) {
    this.ngbModal.open(modal);
  }
}
