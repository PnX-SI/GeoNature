import { Component, OnInit, Input, Output, EventEmitter } from '@angular/core';
import { DataFormService } from '../data-form.service';
import { FormControl } from '@angular/forms';
import { AuthService } from '../../../components/auth/auth.service';
import { AppConfig } from '../../../../conf/app.config';

@Component({
  selector: 'pnx-datasets',
  templateUrl: 'datasets.component.html'
})

export class DatasetsComponent implements OnInit {
  public dataSets: any;
  @Input() appId: number;
  @Input() placeholder: string;
  @Input() parentFormControl: FormControl;
  @Output() dataSetChanged = new EventEmitter<number>();
  constructor(private _dfs: DataFormService, private _auth: AuthService) { }

  ngOnInit() {
      // TODO : recuperer l'id du module en cours
      this._dfs.getDatasets()
      .subscribe(res => {
        this.dataSets = res;
     });
    }

}
