import { Component, OnInit } from '@angular/core';
import { FormControl, FormArray, FormBuilder } from '@angular/forms';
import { ExportsService } from './exports.service';
import { AppConfig } from '../../conf/app.config';

@Component({
  selector: 'pnx-exports-component',
  templateUrl: 'exports.component.html',
  styleUrls: ['exports.component.scss']
})
export class ExportsComponent implements OnInit {
  public dataSetControl = new FormControl();
  public dataSetsControls = this._fb.array([]);
  public viewList: Array<any>;
  constructor(public exportsService: ExportsService, private _fb: FormBuilder) {}

  ngOnInit() {
    this.viewList = this.exportsService.getFakeViewList();
    this.viewList.forEach((view, index) => {
      this.dataSetsControls.insert(index, this._fb.control(null));
    });
    this.dataSetControl.valueChanges.subscribe(value => {});
  }

  exportCsv(idView, idDataSet) {
    if (idDataSet) {
      document.location.href = `${
        AppConfig.API_ENDPOINT
      }/occtax/export?id_dataset=${idDataSet}&format=csv`;
    } else {
      document.location.href = `${AppConfig.API_ENDPOINT}/occtax/export?format=csv`;
    }
  }
}
