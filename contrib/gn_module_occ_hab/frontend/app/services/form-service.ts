import { Injectable } from "@angular/core";
import { FormBuilder, FormGroup } from "@angular/forms";
@Injectable()
export class OcchabFormService {
  public stationForm: FormGroup;
  public habitatForm: FormGroup;
  constructor(private _fb: FormBuilder) {
    this.stationForm = this._fb.group({
      observers: null,
      id_dataset: null,
      date_min: null,
      date_max: null,
      altitude_min: null,
      altitude_max: null,
      id_nomenclature_area_surface_calculation: null,
      habitats: [new Array()]
    });

    this.habitatForm = this._fb.group({
      non_cite: null,
      habitat_obj: null,
      id_nomenclature_determination_type: null,
      determiner: null,
      id_nomenclature_collection_technique: null,
      recovery_percentage: null,
      id_nomenclature_abundance: null,
      technical_precision: null,
      id_nomenclature_community_interest: null
    });
  }

  addHabitat() {
    // this.stationForm.patchValue({ habitats: this.habitatForm.value });
    this.stationForm.value.habitats.push(this.habitatForm.value);
    this.habitatForm.reset();
  }
}
