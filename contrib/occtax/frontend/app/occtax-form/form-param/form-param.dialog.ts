import { Component, OnInit } from "@angular/core";
import { FormBuilder, FormGroup, Validators } from "@angular/forms";
import { combineLatest } from "rxjs";
import { filter, map } from "rxjs/operators";
import { ModuleConfig } from "../../module.config";  
import { OcctaxFormParamService } from './form-param.service';


@Component({
  selector: "pnx-occtax-form-param",
  templateUrl: "./form-param.dialog.html",
  styleUrls: ["./form-param.dialog.scss"]
})
export class OcctaxFormParamDialog implements OnInit {

  public occtaxConfig: any;
  public paramsForm: FormGroup;
  public selectedIndex: number = null;

  get releveParamForm() { return this.paramsForm.get('releve'); }
  get occurrenceParamForm() { return this.paramsForm.get('occurrence'); }
  get countingParamForm() { return this.paramsForm.get('counting'); }

  constructor(
    private fb: FormBuilder,
    public occtaxFormParamService: OcctaxFormParamService
  ) {
    this.occtaxConfig = ModuleConfig;
  }
  
  ngOnInit() {

    this.paramsForm = this.fb.group({
      releve: this.fb.group({
        id_dataset: null,
        date_min: null,
        date_max: null,
        hour_min: [null, Validators.pattern("^([0-9]|0[0-9]|1[0-9]|2[0-3]):[0-5][0-9](:[0-5][0-9])?$")],
        hour_max: [null, Validators.pattern("^([0-9]|0[0-9]|1[0-9]|2[0-3]):[0-5][0-9](:[0-5][0-9])?$")],
        comment: null,
        id_nomenclature_obs_technique: null,
        observers: null,
        observers_txt: null,
        id_nomenclature_grp_typ: null
      }),
      occurrence: this.fb.group({
        id_nomenclature_obs_meth: null,
        id_nomenclature_bio_condition: null,
        id_nomenclature_bio_status: null,
        id_nomenclature_naturalness: null,
        id_nomenclature_exist_proof: null,
        id_nomenclature_observation_status: null,
        id_nomenclature_diffusion_level: null,
        id_nomenclature_blurring: null,
        id_nomenclature_source_status: null,
        determiner: null,
        id_nomenclature_determination_method: null,
        sample_number_proof: null,
        comment: null
      }),
      counting: this.fb.group({
        id_nomenclature_life_stage: null,
        id_nomenclature_sex: null,
        id_nomenclature_obj_count: null,
        id_nomenclature_type_count: null,
        count_min: null,
        count_max: null
      })
    });
    
    this.paramsForm.patchValue(this.occtaxFormParamService.parameters);

    this.paramsForm.valueChanges
                .pipe(
                  filter(()=>this.paramsForm.valid)
                )
                .subscribe(values=>this.occtaxFormParamService.parameters = values);

    combineLatest(this.occtaxFormParamService.releveState, this.occtaxFormParamService.occurrenceState, this.occtaxFormParamService.countingState)
      .pipe(
        filter(([releveState, occurrenceState, countingState])=>(releveState+occurrenceState+countingState)===1), //si une seul est cochée
        map(([releveState, occurrenceState, countingState])=>{
          //convertit la case coché en index de tab à activer
          if (releveState) {
            return 0;
          }
          if (occurrenceState) {
            return 1;
          }
          if (countingState) {
            return 2;
          }
        })
      )
      .subscribe(index=>this.selectedIndex = index)
  }



}