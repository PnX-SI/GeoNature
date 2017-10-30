import { Component, OnInit, Input, Output, EventEmitter } from '@angular/core';
import { DataFormService } from '../data-form.service';
import { FormControl } from '@angular/forms';
import { AuthService } from '../../../components/auth/auth.service';
import { NavService } from '../../../services/nav.service';
import { AppConfig } from '../../../../conf/app.config';

@Component({
  selector: 'pnx-datasets',
  templateUrl: 'datasets.component.html'
})

export class DatasetsComponent implements OnInit {
  public dataSets: any;
  @Input() placeholder: string;
  @Input() parentFormControl: FormControl;
  @Output() dataSetChanged = new EventEmitter<number>();
  constructor(private _dfs: DataFormService, private _auth: AuthService, private _navService: NavService) { }

  ngOnInit() {
      // TODO : recuperer l'id du module en cours
      const currentUser = this._auth.getCurrentUser();
      const appRights = currentUser.getRight(14);
      let idOrganism = null;
      if (appRights['R'] < AppConfig.RIGHTS.MY_ORGANISM_DATA) {
         idOrganism = currentUser.organism.organismId;
      }
      this._dfs.getDatasets(idOrganism)
      .subscribe(res => {
        this.dataSets = res;
     });
    }

}
