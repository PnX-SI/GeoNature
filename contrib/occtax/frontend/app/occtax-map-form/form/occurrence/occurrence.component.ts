import {
  Component,
  OnInit,
  AfterViewInit,
  Input,
  ViewEncapsulation,
  ContentChild,
  ViewChildren,
  ViewChild,
  QueryList
} from "@angular/core";
import { FormControl, FormGroup, Validators } from "@angular/forms";
import { OcctaxFormService } from "../occtax-form.service";
import { CommonService } from "@geonature_common/service/common.service";
import { NomenclatureComponent } from "@geonature_common/form/nomenclature/nomenclature.component";
import { ModuleConfig } from "../../../module.config";

@Component({
  selector: "pnx-occurrence",
  templateUrl: "./occurrence.component.html",
  styleUrls: ["./occurrence.component.scss"],
  encapsulation: ViewEncapsulation.None
})
export class OccurrenceComponent implements OnInit, AfterViewInit {
  public occtaxConfig: any;
  @Input() occurrenceForm: FormGroup;
  @ViewChild("taxon") taxon;
  @ViewChildren(NomenclatureComponent)
  nomenclatures: QueryList<NomenclatureComponent>;
  @ViewChild("existProof") existProof: NomenclatureComponent;
  constructor(
    public fs: OcctaxFormService,
    private _commonService: CommonService
  ) {}

  ngOnInit() {
    this.occtaxConfig = ModuleConfig;
  }

  validateDigitalProof(c: FormControl) {
    let REGEX = new RegExp("^(http://|https://|ftp://){1}.+$");
    return REGEX.test(c.value)
      ? null
      : {
          validateDigitalProof: {
            valid: false
          }
        };
  }

  ngAfterViewInit() {
    document.getElementById("taxonInput").focus();

    this.occurrenceForm.controls.id_nomenclature_exist_proof.valueChanges.subscribe(
      value => {
        // if exist proof is No or undefined => set error on both
        if (this.existProof.currentCdNomenclature !== "1" || value === null) {
          this.occurrenceForm.controls.digital_proof.setValue(null);
          this.occurrenceForm.controls.non_digital_proof.setValue(null);
          this.occurrenceForm.controls.digital_proof.disable();
          this.occurrenceForm.controls.non_digital_proof.disable();
        } else {
          this.occurrenceForm.controls.digital_proof.enable();
          this.occurrenceForm.controls.non_digital_proof.enable();
          if (
            this.occurrenceForm.value.digital_proof === null &&
            this.occurrenceForm.value.non_digital_proof === null
          ) {
            // digital proof must begin with 'http, https'...
            if (ModuleConfig.digital_proof_validator) {
              this.occurrenceForm.controls.digital_proof.setValidators(
                this.validateDigitalProof
              );
            }
            this.occurrenceForm.controls.digital_proof.setErrors({
              incorrect: true
            });
            this.occurrenceForm.controls.non_digital_proof.setErrors({
              incorrect: true
            });
          }
        }
      }
    );

    this.occurrenceForm.controls.digital_proof.valueChanges
      .filter(value => value !== null)
      .subscribe(value => {
        // set validator if it has been removed
        if (ModuleConfig.digital_proof_validator) {
          this.occurrenceForm.controls.digital_proof.setValidators(
            this.validateDigitalProof
          );
        }
        // if length = 0 set to null
        if (value.length === 0) {
          this.occurrenceForm.controls.digital_proof.setValue(null);
        }
        if (this.occurrenceForm.value.non_digital_proof === null) {
          this.occurrenceForm.controls.non_digital_proof.updateValueAndValidity();
        }
        if (
          value.length === 0 &&
          this.occurrenceForm.value.non_digital_proof === null
        ) {
          this.occurrenceForm.controls.digital_proof.setErrors({
            incorrect: true
          });
          this.occurrenceForm.controls.non_digital_proof.setErrors({
            incorrect: true
          });
        }
      });

    this.occurrenceForm.controls.non_digital_proof.valueChanges
      .filter(value => value !== null)
      .subscribe(value => {
        // if length = 0 set to null
        if (value.length === 0) {
          this.occurrenceForm.controls.non_digital_proof.setValue(null);
        }
        if (this.occurrenceForm.value.digital_proof === null) {
          this.occurrenceForm.controls.digital_proof.clearValidators();
          this.occurrenceForm.controls.digital_proof.updateValueAndValidity();
        }
        if (
          value.length === 0 &&
          this.occurrenceForm.value.digital_proof === null
        ) {
          this.occurrenceForm.controls.digital_proof.setErrors({
            incorrect: true
          });
          this.occurrenceForm.controls.non_digital_proof.setErrors({
            incorrect: true
          });
        }
      });
  }
}
