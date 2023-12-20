import { Injectable } from '@angular/core';
import {
  FormGroup,
  FormControl,
  Validators,
  AbstractControl,
  ValidationErrors,
} from '@angular/forms';
import { DataService } from '../data.service';
import { CommonService } from '@geonature_common/service/common.service';

@Injectable()
export class FieldMappingService {
  /*public fieldMappingForm: FormGroup;
  public userFieldMappings;
  public columns;
  public newMapping: boolean = false;
  public id_mapping;*/

  constructor /*private _ds: DataService,
    private _commonService: CommonService*/() {}

  /*getMappingNamesList(mapping_type) {
    this._ds.getMappings(mapping_type).subscribe(
      result => {
        this.userFieldMappings = result["mappings"];
        if (result["column_names"] != "undefined import_id") {
          this.columns = result["column_names"].map(col => {
            return {
              id: col,
              selected: false
            };
          });
        }
      },
      error => {
        console.error(error);
        if (error.statusText === "Unknown Error") {
          // show error message if no connexion
          this._commonService.regularToaster(
            "error",
            "Une erreur s'est produite : contactez l'administrateur du site"
          );
        } else {
          this._commonService.regularToaster("error", error.error);
        }
      }
    );
  }

  createMapping() {
    this.fieldMappingForm.reset();
    this.newMapping = true;
  }

  cancelMapping() {
    this.newMapping = false;
    this.fieldMappingForm.controls["mappingName"].setValue("");
  }



  onMappingName(mappingForm, targetFormName): void {
    mappingForm.get("fieldMapping").valueChanges.subscribe(
      id_mapping => {
        this.id_mapping = id_mapping;
        if (this.id_mapping && id_mapping != "") {
          this.fillMapping(this.id_mapping, targetFormName);
        } else {
          this.fillEmptyMapping(targetFormName);
          this.disableMapping(targetFormName);
          this.shadeSelectedColumns(targetFormName);
        }
      },
      error => {
        if (error.statusText === "Unknown Error") {
          // show error message if no connexion
          this._commonService.regularToaster(
            "error",
            "ERROR: IMPOSSIBLE TO CONNECT TO SERVER (check your connexion)"
          );
        } else {
          console.error(error);
          this._commonService.regularToaster("error", error.error);
        }
      }
    );
  }

  fillMapping(id_mapping, targetFormName) {
    this.id_mapping = id_mapping;
    this._ds.getMappingFields(this.id_mapping).subscribe(
      mappingFields => {
        if (mappingFields.length > 0) {
          for (let field of mappingFields) {
            this.enableMapping(targetFormName);
            targetFormName
              .get(field["target_field"])
              .setValue(field["source_field"]);
          }
          this.shadeSelectedColumns(targetFormName);
          this.geoFormValidator(targetFormName);
        } else {
          this.fillEmptyMapping(targetFormName);
        }
      },
      error => {
        if (error.statusText === "Unknown Error") {
          // show error message if no connexion
          this._commonService.regularToaster(
            "error",
            "ERROR: IMPOSSIBLE TO CONNECT TO SERVER (check your connexion)"
          );
        } else {
          console.error(error);
          this._commonService.regularToaster("error", error.error);
        }
      }
    );
  }

  shadeSelectedColumns(targetFormName) {
    let formValues = targetFormName.value;
    this.columns.map(col => {
      if (formValues) {
        if (Object.values(formValues).includes(col.id)) {
          col.selected = true;
        } else {
          col.selected = false;
        }
      }
    });
  }*/

  /*setFormControlNotRequired(form): void {
    form.clearValidators();
    //form.setValidators(null);
    form.updateValueAndValidity();
  }

  setFormControlRequired(form): void {
    form.setValidators([Validators.required]);
    form.updateValueAndValidity();
  }*/

  /*setInvalid(form, errorName: string): void {
    const error = {}
    error[errorName] = true
    form.setErrors(error)
  }*/

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

  /*onSelect(id_mapping, targetForm) {
    this.id_mapping = id_mapping;
    this.shadeSelectedColumns(targetForm);
    this.geoFormValidator(targetForm);
  }

  disableMapping(targetForm) {
    Object.keys(targetForm.controls).forEach(key => {
      targetForm.controls[key].disable();
    });
  }

  enableMapping(targetForm) {
    Object.keys(targetForm.controls).forEach(key => {
      targetForm.controls[key].enable();
    });
  }

  fillEmptyMapping(targetForm) {
    Object.keys(targetForm.controls).forEach(key => {
      targetForm.get(key).setValue("");
    });
  }*/
}
