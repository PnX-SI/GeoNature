import { Injectable, OnInit } from '@angular/core';
import { ConfigService } from '@geonature/services/config.service';

@Injectable()
export class SyntheseContentListColumnsService implements OnInit {
  public defaultColumns: Array<any> = [];
  public availableColumns: Array<any> = [];

  constructor(private _config: ConfigService) { }

  ngOnInit() {
    this._initListColumns();
  }

  _initListColumns() {
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
}
