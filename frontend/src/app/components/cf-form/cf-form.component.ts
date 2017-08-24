import { Component, OnInit } from '@angular/core';
import {FormControl} from '@angular/forms';
import {NomenclatureComponent} from './nomenclature/nomenclature.component';
import 'rxjs/add/operator/startWith';
import 'rxjs/add/operator/map';

@Component({
  selector: 'app-cf-form',
  templateUrl: './cf-form.component.html',
  styleUrls: ['./cf-form.component.scss']
})
export class CfFormComponent implements OnInit {

  stateCtrl: FormControl;
  dataForm: any;
  constructor() {
    this.dataForm = {
      observers : []
    };
  }


  ngOnInit() {
  }
  addObservers(observer) {
    this.dataForm.observers.push(observer);
  }

  deleteObservers(observer) {
    const index = this.dataForm.observers.indexOf(observer);
    this.dataForm.observers.split(index, 1);
  }

  updateModelWithLabel(nomclatureObj) {
    const nomenclatureName = nomclatureObj.nomenclature.toLowerCase();
    const idLabel = nomclatureObj.idLabel;
    this.dataForm[nomenclatureName] = idLabel;
  }
}
