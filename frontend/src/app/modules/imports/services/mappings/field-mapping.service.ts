import { Injectable } from '@angular/core';
import {
  FormGroup,
  FormControl,
  Validators,
  AbstractControl,
  ValidationErrors,
  FormBuilder,
} from '@angular/forms';
import { ImportDataService } from '../data.service';
import { CommonService } from '@geonature_common/service/common.service';

@Injectable()
export class FieldMappingService {
  public mappingFormGroup: FormGroup;

  constructor(private _fb: FormBuilder) {}

  initForm() {
    this.mappingFormGroup = this._fb.group({});
    this.createMappingFormValidators();
    this.mappingFormGroup.updateValueAndValidity();
  }

  createMappingFormValidators(): ValidationErrors | null {
    return null;
  }

  // add a form control for each target field in the mappingForm
  // mandatory target fields have a required validator
  displayAlert(field) {
    return (
      field.name_field === 'unique_id_sinp_generate' &&
      !this.mappingFormGroup.get(field.name_field).value
    );
  }
  /**
   * Add custom validator to the form
   */
  geoFormValidator(g: FormGroup): ValidationErrors | null {
    /* We require a position (wkt/x,y) and/or a attachement (code{maille,commune,departement})
       We can set both as some file can have a position for few rows, and a attachement for others.
       Contraints are:
       - We must have a position or a attachement (or both).
       - WKT and X/Y are mutually exclusive.
       - Code{maille,commune,departement} are mutually exclusive.
    */
    /*
        6 cases :
        - all null : all required
        - wkt == null and both coordinates != null : wkt not required, codes not required, coordinates required
        - wkt != '' : wkt required, coordinates and codes not required
        - one of the code not empty: others not required
        - wkt and X/Y filled => error
        */
    let xy = false;
    let attachment = false;

    let wkt_errors = null;
    let longitude_errors = null;
    let latitude_errors = null;
    let codemaille_errors = null;
    let codecommune_errors = null;
    let codedepartement_errors = null;
    // check for position
    if (g.value.longitude != null || g.value.latitude != null) {
      xy = true;
      // ensure both x/y are set
      if (g.value.longitude == null) longitude_errors = { required: true };
      if (g.value.latitude == null) latitude_errors = { required: true };
    }
    if (g.value.WKT != null) {
      xy = true;
    }
    // check for attachment
    if (
      g.value.codemaille != null ||
      g.value.codecommune != null ||
      g.value.codedepartement != null
    ) {
      attachment = true;
    }
    if (xy == false && attachment == false) {
      wkt_errors = { required: true };
      longitude_errors = { required: true };
      latitude_errors = { required: true };
      codemaille_errors = { required: true };
      codecommune_errors = { required: true };
      codedepartement_errors = { required: true };
    }
    if ('WKT' in g.controls) g.controls.WKT.setErrors(wkt_errors);
    if ('longitude' in g.controls) g.controls.longitude.setErrors(longitude_errors);
    if ('latitude' in g.controls) g.controls.latitude.setErrors(latitude_errors);
    if ('codemaille' in g.controls) g.controls.codemaille.setErrors(codemaille_errors);
    if ('codecommune' in g.controls) g.controls.codecommune.setErrors(codecommune_errors);
    if ('codedepartement' in g.controls)
      g.controls.codedepartement.setErrors(codedepartement_errors);
    // we set errors on individual form control level, so we return no errors (null) at form group level.
    return null;
  }
}
