import { Component, OnInit, Input, Output, EventEmitter, ViewEncapsulation, ViewChild } from '@angular/core';
import { FormControl, FormBuilder, FormGroup, FormArray, Validators } from '@angular/forms';
import { ContactFormService } from '../contact-form.service';



@Component({
  selector: 'pnx-counting',
  templateUrl: './counting.component.html',
  styleUrls: ['./counting.component.scss'],
  encapsulation: ViewEncapsulation.None
})
export class CountingComponent implements OnInit {
  @Input() index: number;
  @Input() length :number; 
  @Input() formArray: FormArray;
  @Output() countingRemoved = new EventEmitter<any>();
  @Output() countingAdded = new EventEmitter<any>();
  @ViewChild('typeDenombrement') public typeDenombrement: any;

  constructor(public fs: ContactFormService) { }

  ngOnInit() {

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
