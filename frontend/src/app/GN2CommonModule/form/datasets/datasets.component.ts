import { Component, OnInit, Input, Output, EventEmitter } from '@angular/core';
import { DataFormService } from '../data-form.service';
import { FormControl } from '@angular/forms';
import { AuthService } from '../../../components/auth/auth.service';
import { AppConfig } from '../../../../conf/app.config';
import { GenericFormComponent } from '@geonature_common/form/genericForm.component';

@Component({
  selector: 'pnx-datasets',
  templateUrl: 'datasets.component.html'
})
export class DatasetsComponent extends GenericFormComponent implements OnInit {
  public dataSets: any;
  @Input() displayAll: false; // param to display the field 'all' in the list, default at false
  constructor(private _dfs: DataFormService, private _auth: AuthService) {
    super();
  }

  ngOnInit() {
    // TODO : recuperer l'id du module en cours
    this._dfs.getDatasets().subscribe(res => {
      this.dataSets = res;
    });
  }
}
