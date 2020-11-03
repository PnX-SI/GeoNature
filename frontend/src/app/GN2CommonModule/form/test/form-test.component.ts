import { Component, OnInit, Input, Output, EventEmitter, ViewEncapsulation } from '@angular/core';
import { Router, ActivatedRoute, ParamMap } from '@angular/router';
import { AppConfig } from '@geonature_config/app.config';
import { FormGroup, FormBuilder, Validators } from '@angular/forms';
import { MediaService } from '@geonature_common/service/media.service';

@Component({
  selector: 'pnx-form-test',
  templateUrl: './form-test.component.html',
  styleUrls: ['./form-test.component.scss']
  // encapsulation: ViewEncapsulation.None
})
export class FormTestComponent implements OnInit {
  public testForm: FormGroup;

  public appConfig = AppConfig;

  bInitialized = false;

  public formDefinitions = [
     {
        "attribut_name": "cd_nom",
        "autocomplete": true,
        "type_widget": "datalist",
        "attribut_label": "Taxon",
        "keyValue": "cd_nom",
        "keyLabel": "lb_nom",
        "multiple": false,
        "api": "taxref/allnamebylist/100",
        "application": "TaxHub",
        "required": true,
        "type_util": "taxonomy"
      }
  ];

  constructor(
    private _route: ActivatedRoute,
    public ms: MediaService,
    private _formBuilder: FormBuilder
  ) {}

  ngOnInit() {
    // test TODO remove
    const a = {};
    const s = 'a["f"] = a => !!a';
    eval(s);
    console.log(a['f'](1));
    this.testForm = this._formBuilder.group({});
  }
}
