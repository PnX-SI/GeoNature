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
        "multiple": true,
        "attribut_name": "cd_nom",
        "autocomplete": true,
        "type_widget": "datalist",
        "attribut_label": "Commune",
        "keyValue": "id_area",
        "keyLabel": "nom_com+insee_com",
        "keySearch": "nom_com",
        "keyTitle": "insee_com",
        "api": "geo/municipalities",
        "application": "GeoNature",
        "required": true,
        "params": {
          "limit": 10,
        },
        "type_util": "taxonomy",
        "value": [ 12352, 17784 ]
      }
  ];

  constructor(
    private _route: ActivatedRoute,
    public ms: MediaService,
    private _formBuilder: FormBuilder
  ) {}

  ngOnInit() {
    // test TODO remove
    this.testForm = this._formBuilder.group({});
  }
}
