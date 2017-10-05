import { Component, OnInit, Input, EventEmitter, Output, ElementRef } from '@angular/core';
import {NgbDateStruct} from '@ng-bootstrap/ng-bootstrap';
import { FormControl } from '@angular/forms';
import { NgbDateParserFormatter } from '@ng-bootstrap/ng-bootstrap';


@Component({
  selector: 'pnx-date',
  host: {
    '(document:click)': 'onClick($event)',
  },
  templateUrl: 'date.component.html'
})

export class DateComponent implements OnInit {
  public elementRef: ElementRef;
  @Input() placeholder: string;
  @Input() parentFormControl: FormControl;
  @Output() dateChanged = new EventEmitter<any>();
  dynamicId;
  public today: NgbDateStruct;
  constructor(private _dateParser: NgbDateParserFormatter, myElement:ElementRef) {
    this.elementRef = myElement;
   }

  ngOnInit() {
    const today = new Date();
    this.today = { year: today.getFullYear(), month: today.getMonth() + 1, day: today.getDate() };

    this.parentFormControl.valueChanges.subscribe(date => {
      this.dateChanged.emit(this._dateParser.format(date));
    });
   }

   openDatepicker(id) {
    this.dynamicId = id;
  }

   onClick(event) {
    if (this.dynamicId){
      if (!this.elementRef.nativeElement.contains(event.target)) {
        setTimeout(() => {
          this.dynamicId.close();
        }, 10);
      }
    }
  }


}