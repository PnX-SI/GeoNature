import { Component, OnInit, ElementRef, OnDestroy } from '@angular/core';
import { NgbDateParserFormatter } from '@ng-bootstrap/ng-bootstrap';
import { NgbDatePeriodParserFormatter } from './ngb-date-custom-parser-formatter';
import { DateComponent } from './date.component';

@Component({
  selector: 'pnx-period',
  host: {
    '(document:click)': 'onClick($event)'
  },
  templateUrl: 'date.component.html',
  providers: [{ provide: NgbDateParserFormatter, useClass: NgbDatePeriodParserFormatter }]
})
export class PeriodComponent extends DateComponent implements OnInit {
  public elementRef: ElementRef;

  constructor(myElement: ElementRef, public dateParser: NgbDateParserFormatter) {
    super(myElement, dateParser);
  }

  ngOnInit() {}
}
