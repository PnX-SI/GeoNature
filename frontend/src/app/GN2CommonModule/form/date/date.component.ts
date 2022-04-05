import {
  Component,
  OnInit,
  Input,
  EventEmitter,
  Output,
  ElementRef,
  OnDestroy,
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
/**
 * Ce composant permet de créer un input de type "datepicker".
 * Créé à parti de https://github.com/ng-bootstrap/ng-bootstrap
 * Retourne objet date:
 * ```
 * {
    "year": 2018,
    "month": 3,
      "day": 9
 }```
 */
@Component({
  selector: 'pnx-date',
  host: {
    '(document:click)': 'onClick($event)',
  },
  templateUrl: 'date.component.html',
  styleUrls: ['./date.component.scss'],
  providers: [{ provide: NgbDateParserFormatter, useClass: NgbDateFRParserFormatter }],
})
export class DateComponent implements OnInit, OnDestroy {
  public elementRef: ElementRef;
  @Input() label: string;
  @Input() isInvalid: string;
  @Input() disabled: boolean;
  @Input() parentFormControl: FormControl;
  @Input() defaultToday = false;
  @Input() minDate = { year: 1735, month: 1, day: 1 };
  @Input() maxDate;
  @Output() onChange = new EventEmitter<any>();
  @Output() onDelete = new EventEmitter<any>();
  dynamicId;
  public changeSub: Subscription;
  public today: DateStruc;

  constructor(myElement: ElementRef, private _dateParser: NgbDateParserFormatter) {
    this.elementRef = myElement;
    this.initializeDates();
  }

  ngOnInit() {
    // Set a default value to form control
    if (!this.parentFormControl.value) {
      if (this.defaultToday) {
        this.parentFormControl.setValue(this.today);
      } else {
        // TODO: set to null to avoid the display of an invalid class. Find a better way !
        this.parentFormControl.setValue(null);
      }
    }

    // React to parent form control change
    this.changeSub = this.parentFormControl.valueChanges.subscribe((date) => {
      if (date !== null && this._dateParser.format(date) !== 'undefined--') {
        this.onChange.emit(this._dateParser.format(date));
      } else {
        this.onDelete.emit(null);
      }
    });
  }

  private initializeDates() {
    const today = new Date();
    this.today = { year: today.getFullYear(), month: today.getMonth() + 1, day: today.getDate() };
    if (!this.maxDate) {
      this.maxDate = this.today;
    }
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
