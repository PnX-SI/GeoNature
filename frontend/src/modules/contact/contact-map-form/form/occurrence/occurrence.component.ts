import { Component, OnInit, OnChanges, AfterContentInit, AfterViewInit, Input, ViewEncapsulation, ContentChild,
  ViewChildren, ViewChild, QueryList } from '@angular/core';
import { FormControl, FormGroup, Validators } from '@angular/forms';
import { ContactFormService } from '../contact-form.service';
import { AuthService } from '../../../../../core/components/auth/auth.service';
import { CommonService } from '../../../../../core/GN2Common/service/common.service';
import { NomenclatureComponent } from '../../../../../core/GN2Common/form/nomenclature/nomenclature.component';
import { ContactConfig } from '../../../contact.config';

@Component({
  selector: 'pnx-occurrence',
  templateUrl: './occurrence.component.html',
  styleUrls: ['./occurrence.component.scss'],
  encapsulation: ViewEncapsulation.None
})
export class OccurrenceComponent implements AfterViewInit {
  public contactConfig: any;
  @Input() occurrenceForm: FormGroup;
  @ViewChild('taxon') taxon;
  @ViewChildren(NomenclatureComponent) nomenclatures: QueryList<NomenclatureComponent>;
  @ViewChild('existProof') existProof: NomenclatureComponent;
  constructor(public fs: ContactFormService, private _auth: AuthService, private _commonService: CommonService ) {
   }

  validateDigitalProof(c: FormControl) {
    let REGEX = new RegExp('^(http://|https://|ftp://){1}.+$');
    return REGEX.test(c.value) ? null : {
      validateDigitalProof: {
        valid: false
      }
    };
  }

  ngAfterViewInit() {
    this.contactConfig = ContactConfig;
    document.getElementById('taxonInput').focus();

    this.occurrenceForm.controls.id_nomenclature_exist_proof.valueChanges
      .subscribe(value => {
        // if exist proof is No or undefined => set error on both
        if (this.existProof.currentCdNomenclature !== '1') {
          this.occurrenceForm.controls.digital_proof.setValue(null);
          this.occurrenceForm.controls.non_digital_proof.setValue(null);
          this.occurrenceForm.controls.digital_proof.disable();
          this.occurrenceForm.controls.non_digital_proof.disable();
        }
        // exist proof is Yes
        if (this.existProof.currentCdNomenclature === '1') {
          this.occurrenceForm.controls.digital_proof.enable();
          this.occurrenceForm.controls.non_digital_proof.enable();
          if (this.occurrenceForm.value.digital_proof === null && this.occurrenceForm.value.non_digital_proof === null) {
            // if digital proof must begin with 'http, https'...
            if (ContactConfig.digital_proof_validator) {
              this.occurrenceForm.controls.digital_proof.setValidators(this.validateDigitalProof);
            }
            this.occurrenceForm.controls.digital_proof.setErrors({'incorrect': true});
            this.occurrenceForm.controls.non_digital_proof.setErrors({'incorrect': true});
          }
        }
      });

    this.occurrenceForm.controls.digital_proof.valueChanges
      .filter(value => value !== null)
      .subscribe(value => {
        // set validator if it has been removed
        if (ContactConfig.digital_proof_validator) {
          this.occurrenceForm.controls.digital_proof.setValidators(this.validateDigitalProof);
        }
        // if length = 0 set to null
        if (value.length === 0) {
          this.occurrenceForm.controls.digital_proof.setValue(null);
        }
        if (this.occurrenceForm.value.non_digital_proof === null) {
          this.occurrenceForm.controls.non_digital_proof.updateValueAndValidity();
        }
        if (value.length === 0 && this.occurrenceForm.value.non_digital_proof === null) {
          this.occurrenceForm.controls.digital_proof.setErrors({'incorrect': true});
          this.occurrenceForm.controls.non_digital_proof.setErrors({'incorrect': true});
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
        if (value.length === 0 && this.occurrenceForm.value.digital_proof === null) {
          this.occurrenceForm.controls.digital_proof.setErrors({'incorrect': true});
          this.occurrenceForm.controls.non_digital_proof.setErrors({'incorrect': true});
        }
      });

  }





}
