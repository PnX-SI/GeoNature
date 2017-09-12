import { Component, OnInit, Input, Output, EventEmitter, ViewEncapsulation } from '@angular/core';
import { FormControl, FormGroup } from '@angular/forms';
import { FormService }  from '../form.service'

@Component({
  selector: 'pnx-occurrence',
  templateUrl: './occurrence.component.html',
  styleUrls: ['./occurrence.component.scss'],
  encapsulation: ViewEncapsulation.None
})
export class OccurrenceComponent implements OnInit {

  @Input() occurrenceForm: FormGroup;

  constructor(public fs: FormService) {
   }

  ngOnInit() {
 
  }



}
