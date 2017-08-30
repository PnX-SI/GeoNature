import { Component, OnInit, Input, Output, EventEmitter } from '@angular/core';
import { ContactFormService } from '../contact-form/contact-form.service'
import { FormControl, FormBuilder, FormGroup, FormArray } from '@angular/forms';


@Component({
  selector: 'pnx-counting',
  templateUrl: './counting.component.html',
  styleUrls: ['./counting.component.scss']
})
export class CountingComponent implements OnInit {
  @Input() index: number;
  @Input() length :number; 
  @Input() formGroup: FormGroup;
  constructor(public cfs: ContactFormService) { }

  ngOnInit() {}

  
}
