import { Component, OnInit, Input, Output, EventEmitter, ViewEncapsulation } from '@angular/core';
import { FormControl, FormBuilder, FormGroup, FormArray } from '@angular/forms';
import { FormService } from '../form.service'


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
  constructor(public fs: FormService) { }

  ngOnInit() {}

  onAddCounting(){
    this.countingAdded.emit();
  }

  onRemoveCounting(){    
    this.countingRemoved.emit(this.index);
  }

  
}
