import { Component, OnInit, Input, Output, EventEmitter, ViewEncapsulation, ViewChild } from '@angular/core';
import { FormControl, FormBuilder, FormGroup, FormArray, Validators } from '@angular/forms';
import { ContactFormService } from '../contact-form.service';
import { CommonService } from '../../../../../core/GN2Common/service/common.service';



@Component({
  selector: 'pnx-counting',
  templateUrl: './counting.component.html',
  styleUrls: ['./counting.component.scss'],
  encapsulation: ViewEncapsulation.None
})
export class CountingComponent implements OnInit {
  @Input() index: number;
  @Input() length: number;
  @Input() formArray: FormArray;
  @Output() countingRemoved = new EventEmitter<any>();
  @Output() countingAdded = new EventEmitter<any>();
  @ViewChild('typeDenombrement') public typeDenombrement: any;
  constructor(public fs: ContactFormService, private _commonService: CommonService) { }

  ngOnInit() {
    // autocomplete count_max
    (this.formArray.controls[this.fs.indexCounting] as FormGroup).controls.count_min.valueChanges
      .debounceTime(500)
      .distinctUntilChanged()
      .subscribe(value => {
        if (
          this.formArray.controls[this.fs.indexCounting].value.count_max === null
          ||
          (this.formArray.controls[this.fs.indexCounting] as FormGroup).controls.count_max.pristine
        ) {
          (this.formArray.controls[this.fs.indexCounting] as FormGroup).patchValue({'count_max': value});
        }
        this.checkCountingIntegrity();
      });

    // check if count_max is not > count_min
    (this.formArray.controls[this.fs.indexCounting] as FormGroup).controls.count_max.valueChanges
      .debounceTime(500)
      .distinctUntilChanged()
      .filter(value => value !== null)
      .subscribe( value => {
        // autocomplete count_min if null
        if ((this.formArray.controls[this.fs.indexCounting] as FormGroup).controls.count_min.pristine &&
             this.formArray.controls[this.fs.indexCounting].value.count_min === null) {
          (this.formArray.controls[this.fs.indexCounting] as FormGroup).patchValue({'count_min': value});
        }
        this.checkCountingIntegrity();
      });
  }

  checkCountingIntegrity() {
    const count_min = this.formArray.controls[this.fs.indexCounting].value.count_min;
    const count_max = this.formArray.controls[this.fs.indexCounting].value.count_max;
    if (count_max < count_min) {
      this._commonService.translateToaster('error', 'Counting.CountError');
      (this.formArray.controls[this.fs.indexCounting] as FormGroup).controls.count_max.setErrors([Validators.required]);
    }
  }

  typeDenombrementChanged(event) {
    // Test validation conditionelle
    // if (event !== null && event !== 109) {
    //   const formGroup: FormGroup = <FormGroup>this.fs.countingForm.controls[0];
    //    formGroup.controls['count_min'].setErrors([Validators.required]);
    //    formGroup.controls['count_max'].setErrors([Validators.required]);
    // }
  }

  onAddCounting() {
    this.countingAdded.emit();
  }

  onRemoveCounting() {
    this.countingRemoved.emit(this.index);
  }


}
