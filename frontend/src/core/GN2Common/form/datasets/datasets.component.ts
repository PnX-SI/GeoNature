import { Component, OnInit, Input, Output, EventEmitter } from '@angular/core';
import { DataFormService } from '../data-form.service';
import { FormControl } from '@angular/forms';
import { AuthService } from '../../../components/auth/auth.service';
import { AppConfig } from '../../../../conf/app.config';

@Component({
  selector: 'pnx-datasets',
  templateUrl: 'datasets.component.html',
})

export class DatasetsComponent implements OnInit {
  public dataSets: any;
  @Input() placeholder: string;
  @Input() displayAll: false; // param to display the field 'all' in the list, default at false
  @Input() parentFormControl: FormControl;
  @Input() disabled: boolean;
  @Output() dataSetChanged = new EventEmitter<number>();
  @Output() dataSetDeleted = new EventEmitter();
  constructor(private _dfs: DataFormService, private _auth: AuthService) { }

  ngOnInit() {
      // TODO : recuperer l'id du module en cours
      this._dfs.getDatasets()
      .subscribe(res => {
        this.dataSets = res;
     });

     this.parentFormControl.valueChanges
      .subscribe(id_dataset => {
        if (id_dataset === null) {
          this.dataSetDeleted.emit();
        } else {
          this.dataSetChanged.emit(id_dataset);
        }
      });

    }

}
