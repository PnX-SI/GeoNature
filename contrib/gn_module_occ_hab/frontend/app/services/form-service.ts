import { Injectable } from "@angular/core";
import { FormBuilder, FormGroup } from "@angular/forms";
import { NgbDateParserFormatter } from "@ng-bootstrap/ng-bootstrap";
import { OccHabDataService } from "../services/data.service";
import { CommonService } from "@geonature_common/service/common.service";

@Injectable()
export class OcchabFormService {
  public stationForm: FormGroup;
  public habitatForm: FormGroup;
  constructor(
    private _fb: FormBuilder,
    private _dateParser: NgbDateParserFormatter,
    private _dataService: OccHabDataService,
    private _commonService: CommonService
  ) {
    this.stationForm = this._fb.group({
      observers: null,
      observers_txt: null,
      id_dataset: null,
      date_min: null,
      date_max: null,
      altitude_min: null,
      altitude_max: null,
      id_nomenclature_area_surface_calculation: null,
      t_habitats: [new Array()],
      geom_4326: null
    });

    this.habitatForm = this._fb.group({
      nom_cite: "test",
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
    this.stationForm.value.t_habitats.push(this.habitatForm.value);
    this.habitatForm.reset();
  }

  patchGeomValue(geom) {
    this.stationForm.patchValue({ geom_4326: geom.geometry });
  }

  postStation() {
    let formData = Object.assign({}, this.stationForm.value);

    //format cd_hab
    formData.t_habitats.forEach(element => {
      element.cd_hab = element.habitat_obj.cd_hab;
    });

    // format date
    formData.date_min = this._dateParser.format(formData.date_min);
    formData.date_max = this._dateParser.format(formData.date_max);

    this._dataService.postStation(formData).subscribe(
      data => {
        console.log(data);
      },
      error => {
        if (error.status === 403) {
          this._commonService.translateToaster("error", "NotAllowed");
        } else {
          console.error(error.error.message);
          this._commonService.translateToaster("error", "ErrorMessage");
        }
      }
    );
  }
}
