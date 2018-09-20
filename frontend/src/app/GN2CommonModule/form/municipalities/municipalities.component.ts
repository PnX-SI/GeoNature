import { Component, OnInit, Input, EventEmitter, Output } from '@angular/core';
import { GenericFormComponent } from '@geonature_common/form/genericForm.component';
import { DataFormService } from '../data-form.service';
import { FormControl } from '@angular/forms';
import { log } from 'util';
import { CommonService } from '@geonature_common/service/common.service';

@Component({
  selector: 'pnx-municipalities',
  templateUrl: './municipalities.component.html',
  styleUrls: ['./municipalities.component.scss']
})
export class MunicipalitiesComponent implements OnInit {
  public municipalities: Array<any>;
  public searchControl = new FormControl();
  @Input() parentFormControl: FormControl;
  @Input() label: string;
  @Input() searchBar = false;
  @Input() disabled: boolean;
  @Input() bindAllItem: false;
  @Input() debounceTime: number;
  public currentValue: any;
  constructor(private _dfs: DataFormService, private _commonService: CommonService) {}

  ngOnInit() {
    this._dfs.getMunicipalities().subscribe(data => {
      this.municipalities = data;
    });
  }
  refreshMunicipalities(municipality) {
    console.log('LAAAAAAA');
    console.log(municipality);
    if (municipality) {
      this._dfs.getMunicipalities(municipality).subscribe(
        data => {
          this.municipalities = data;
        },
        err => {
          if (err.status === 404) {
            this.municipalities = [{ nom_com: 'No data to display' }];
          } else {
            this.municipalities = [];
            this._commonService.translateToaster('error', 'ErrorMessage');
          }
        }
      );
    }
  }
}
