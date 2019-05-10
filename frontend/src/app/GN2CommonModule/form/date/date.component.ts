import {
  Component,
  OnInit,
  Input,
  EventEmitter,
  Output,
  ElementRef,
  OnDestroy
} from '@angular/core';
import { FormControl } from '@angular/forms';
import { NgbDateParserFormatter } from '@ng-bootstrap/ng-bootstrap';
import { Subscription } from 'rxjs';
import { NgbDateFRParserFormatter } from './ngb-date-custom-parser-formatter';


export interface DateStruc {
  day: number;
  month: number;
  year: number;
}

@Component({
  selector: 'pnx-date',
  host: {
    '(document:click)': 'onClick($event)'
  },
  templateUrl: 'date.component.html',
  providers: [{ provide: NgbDateParserFormatter, useClass: NgbDateFRParserFormatter }]
})
export class DateComponent implements OnInit, OnDestroy {
  public elementRef: ElementRef;
  @Input() label: string;
  @Input() disabled: boolean;
  @Input() parentFormControl: FormControl;
  @Input() defaultToday = true;
  @Output() onChange = new EventEmitter<any>();
  @Output() onDelete = new EventEmitter<any>();
  dynamicId;
  public changeSub: Subscription;
  public today: DateStruc;
  constructor(myElement: ElementRef, private _dateParser: NgbDateParserFormatter) {
    this.elementRef = myElement;
  }

  ngOnInit() {

    const today = new Date();
    this.today = { year: today.getFullYear(), month: today.getMonth() + 1, day: today.getDate() };
    if (this.defaultToday) {
      this.parentFormControl.setValue(this.today);
    }

    this.changeSub = this.parentFormControl.valueChanges.subscribe(date => {
      if (date !== null && this._dateParser.format(date) !== 'undefined--') {
        this.onChange.emit(this._dateParser.format(date));
      } else {
        this.onDelete.emit(null);
      }
    });
  }

  openDatepicker(id) {
    this.dynamicId = id;
  }

  onClick(event) {
    if (this.dynamicId) {
      if (!this.elementRef.nativeElement.contains(event.target)) {
        setTimeout(() => {
          this.dynamicId.close();
        }, 10);
      }
    }
  }

  ngOnDestroy() {
    if (this.changeSub) {
      this.changeSub.unsubscribe();
    }
  }
}
