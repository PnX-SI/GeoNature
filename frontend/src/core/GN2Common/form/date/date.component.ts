import { Component, OnInit, Input, EventEmitter, Output } from '@angular/core';
import {NgbDateStruct} from '@ng-bootstrap/ng-bootstrap';
import { FormControl } from '@angular/forms';
import { NgbDateParserFormatter } from '@ng-bootstrap/ng-bootstrap';


@Component({
  selector: 'pnx-date',
  templateUrl: 'date.component.html'
})

export class DateComponent implements OnInit {
  @Input() placeholder: string;
  @Input() parentFormControl: FormControl;
  @Output() dateChanged = new EventEmitter<any>();
  public today: NgbDateStruct;
  constructor(private _dateParser: NgbDateParserFormatter) { }

  ngOnInit() {
    const today = new Date();
    this.today = { year: today.getFullYear(), month: today.getMonth() + 1, day: today.getDate() };

    this.parentFormControl.valueChanges.subscribe(date => {
      this.dateChanged.emit(this._dateParser.format(date));
    });
   }
}