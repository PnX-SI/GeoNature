import { Injectable } from "@angular/core";
import {
  FormBuilder,
  FormGroup,
  FormArray,
  Validators,
  AbstractControl,
  FormControl
} from "@angular/forms";
import { GeoJSON } from "leaflet";
import { BehaviorSubject } from "rxjs/BehaviorSubject";

import { AppConfig } from "@geonature_config/app.config";
import { HttpClient, HttpParams } from "@angular/common/http";
import { Router } from "@angular/router";
import { ModuleConfig } from "../../module.config";
import { AuthService, User } from "@geonature/components/auth/auth.service";
import { FormService } from "@geonature_common/form/form.service";
import { Taxon } from "@geonature_common/form/taxonomy/taxonomy.component";
import { CommonService } from "@geonature_common/service/common.service";

@Injectable()
export class OcctaxFormReleveService {
  public defaultValues: any;
  public defaultValuesLoaded = false;
  public userReleveRigth: any;
  public currentHourMax: string;
  public currentReleve: any;

  public releveForm: FormGroup;

  constructor(
    private _fb: FormBuilder,
    private _http: HttpClient,
    private _router: Router,
    private _auth: AuthService,
    private _formService: FormService,
    private _commonService: CommonService
  ) {
    this.currentHourMax = null;
  } // end constructor


}
