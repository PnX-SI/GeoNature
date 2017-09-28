import { Component, OnInit, Input, Output, EventEmitter, ViewEncapsulation, ViewChild } from '@angular/core';
import { FormControl, FormBuilder, FormGroup, FormArray } from '@angular/forms';
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
  @Input() formGroup: FormGroup;
  @Output() countingRemoved = new EventEmitter<any>();
  @Output() countingAdded = new EventEmitter<any>();
  @ViewChild('typeDenombrement') public typeDenombrement: any;

  constructor(public fs: ContactFormService) { }

  ngOnInit() {

  }

  typeDenombrementChanged(event) {
    console.log(event);
  }

  onAddCounting() {
    this.countingAdded.emit();
  }

  onRemoveCounting() {
    this.countingRemoved.emit(this.index);
  }


}
