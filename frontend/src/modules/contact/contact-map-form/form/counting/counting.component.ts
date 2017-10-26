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
  public currentCountMin: number;
  constructor(public fs: ContactFormService, private _commonService: CommonService) { }

  ngOnInit() {
    // autocomplete count_max
    (this.formArray.controls[this.fs.indexCounting] as FormGroup).controls.count_min.valueChanges
      .subscribe(value => {
        this.currentCountMin = value;
        (this.formArray.controls[this.fs.indexCounting] as FormGroup).patchValue({'count_max': value});
      });
    // check if count_max is not > count_min
    (this.formArray.controls[this.fs.indexCounting] as FormGroup).controls.count_max.valueChanges
      .debounceTime(500)
      .filter(value => value !== null)
      .subscribe( value => {
        if (value < this.currentCountMin) {
          this._commonService.translateToaster('error', 'Counting.CountError');
          (this.formArray.controls[this.fs.indexCounting] as FormGroup).controls.count_max.setErrors([Validators.required]);
        }
      });
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
