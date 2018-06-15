import { Component, OnInit, Input, Output, EventEmitter } from '@angular/core';
import { DataFormService } from '../data-form.service';
import { FormControl } from '@angular/forms';
import { AuthService } from '../../../components/auth/auth.service';
import { AppConfig } from '../../../../conf/app.config';
import { GenericFormComponent } from '@geonature_common/form/genericForm.component';
import { CommonService } from '../../service/common.service';

@Component({
  selector: 'pnx-datasets',
  templateUrl: 'datasets.component.html'
})
export class DatasetsComponent extends GenericFormComponent implements OnInit {
  public dataSets: any;
  @Input() displayAll: false; // param to display the field 'all' in the list, default at false
  constructor(
    private _dfs: DataFormService,
    private _auth: AuthService,
    private _commonService: CommonService
  ) {
    super();
  }

  ngOnInit() {
    this._dfs.getDatasets().subscribe(
      res => {
        this.dataSets = res;
      },
      error => {
        if (error.status === 500) {
          this._commonService.translateToaster('error', 'MetaData.JddError');
        } else if (error.status === 404) {
          if (AppConfig.CAS.CAS_AUTHENTIFICATION) {
            this._commonService.translateToaster('warning', 'MetaData.NoJDDMTD');
          } else {
            this._commonService.translateToaster('warning', 'MetaData.NoJDD');
          }
        }
      }
    );
  }
}
