import { Component, OnInit } from '@angular/core';
import { FormGroup, FormBuilder, Validators } from '@angular/forms';
import { Router } from '@angular/router';

import { AppConfig } from '@geonature_config/app.config';
import { DateStruc } from '../../../GN2CommonModule/form/date/date.component';

@Component({
  selector: 'pnx-access-request',
  templateUrl: './access-request.component.html',
  styleUrls: ['./access-request.component.scss']
})
export class AccessRequestComponent implements OnInit {

  public disableSubmit = false;
  public regularFormGrp: FormGroup;
  public dynamicFormGrp: FormGroup;
  public config = AppConfig.PERMISSION_MANAGEMENT;
  public dynamicFormCfg;
  public rulesLink;
  public areaTypes: Array<Number>;
  public defaultAccessDuration;
  public maxAccessDuration;
  public defaultEndAccess: DateStruc;
  public datePickerMin;
  public datePickerMax;

  constructor(
    private formBuilder: FormBuilder,
    private _router: Router,
  ) {
    this.redirectToHome();
    this.dynamicFormCfg = this.config.REQUEST_FORM;
    this.rulesLink = this.config.SENSITIVE_DATA_ACCESS_RULES_LINK || false;
    // TODO: use code instead of id
    this.areaTypes = this.config.AREA_TYPES;
    this.defaultAccessDuration = this.config.DEFAULT_ACCESS_DURATION;
    this.maxAccessDuration = this.config.MAX_ACCESS_DURATION;
  }

  private redirectToHome() {
    if (!(this.config.ENABLE_ACCESS_REQUEST || false)) {
      this._router.navigate(['/']);
    }
  }

  ngOnInit() {
    this.prepareAccessDates();
    this.createRegularForm();
    this.createDynamicForm();
  }

  private prepareAccessDates() {
    const today = new Date();
    const dayDuration = 864e5;

    this.datePickerMin = this.transformToDateObject(today);

    const maxAccessDuration = dayDuration * this.maxAccessDuration;
    const in2YearsDate = new Date(today.valueOf() + maxAccessDuration);
    this.datePickerMax = this.transformToDateObject(in2YearsDate);

    const defaultAccessDuration = dayDuration * this.defaultAccessDuration;
    const defaultEndAccessDate = new Date(today.valueOf() + defaultAccessDuration);
    this.defaultEndAccess = this.transformToDateObject(defaultEndAccessDate);
  }

  private transformToDateObject(date: Date) {
    return {
      year: date.getFullYear(),
      month: date.getMonth() + 1,
      day: date.getDate(),
    };
  }

  private createRegularForm() {
    this.regularFormGrp = this.formBuilder.group({
      areas: ['', Validators.required],
      taxa: [''],
      sensitive_access: [''],
      end_access_date: [this.defaultEndAccess],
    });
  }

  private createDynamicForm() {
    this.dynamicFormGrp = this.formBuilder.group({});
  }

  send() {
    if (this.regularFormGrp.valid && this.dynamicFormGrp.valid) {
      this.disableSubmit = true;
      const finalForm = Object.assign({}, this.regularFormGrp.value);

      // Concatenate two forms
      if (this.dynamicFormCfg.length > 0) {
        finalForm['champs_addi'] = this.dynamicFormGrp.value;
      }
      // TODO: add service
    }
  }
}
