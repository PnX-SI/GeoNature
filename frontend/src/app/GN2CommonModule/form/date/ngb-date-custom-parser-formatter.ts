// FR parser

import { Injectable } from '@angular/core';
import { NgbDateParserFormatter } from '@ng-bootstrap/ng-bootstrap';
import { DateStruc } from './date.component';

function padNumber(value: number) {
  if (isNumber(value)) {
    return `0${value}`.slice(-2);
  } else {
    return '';
  }
}

function isNumber(value: any): boolean {
  return !isNaN(toInteger(value));
}

function toInteger(value: any): number {
  return parseInt(`${value}`, 10);
}

@Injectable()
export class NgbDateFRParserFormatter extends NgbDateParserFormatter {
  parse(value: string): DateStruc {
    if (value) {
      const dateParts = value.trim().split('/');
      if (dateParts.length === 1 && isNumber(dateParts[0])) {
        return { year: toInteger(dateParts[0]), month: null, day: null };
      } else if (dateParts.length === 2 && isNumber(dateParts[0]) && isNumber(dateParts[1])) {
        return { year: toInteger(dateParts[1]), month: toInteger(dateParts[0]), day: null };
      } else if (
        dateParts.length === 3 &&
        isNumber(dateParts[0]) &&
        isNumber(dateParts[1]) &&
        isNumber(dateParts[2])
      ) {
        return {
          year: toInteger(dateParts[2]),
          month: toInteger(dateParts[1]),
          day: toInteger(dateParts[0])
        };
      }
    }
    return null;
  }

  format(date: DateStruc): string {
    let stringDate: string = '';
    if (date) {
      stringDate += isNumber(date.day) ? padNumber(date.day) + '/' : '';
      stringDate += isNumber(date.month) ? padNumber(date.month) + '/' : '';
      stringDate += date.year;
    }

    return stringDate;
  }
}

@Injectable()
export class NgbDatePeriodParserFormatter extends NgbDateParserFormatter {
  parse(value: string): DateStruc {
    if (value) {
      const dateParts = value.trim().split('/');
      if (dateParts.length === 1 && isNumber(dateParts[0])) {
        return { year: null, month: null, day: null };
      } else if (dateParts.length === 2 && isNumber(dateParts[0]) && isNumber(dateParts[1])) {
        return { year: null, month: toInteger(dateParts[0]), day: null };
      } else if (
        dateParts.length === 3 &&
        isNumber(dateParts[0]) &&
        isNumber(dateParts[1]) &&
        isNumber(dateParts[2])
      ) {
        return {
          year: null,
          month: toInteger(dateParts[1]),
          day: toInteger(dateParts[0])
        };
      }
    }
    return null;
  }
  format(date: DateStruc): string {
    let stringDate: string = '';
    if (date) {
      stringDate += isNumber(date.day) ? padNumber(date.day) + '/' : '';
      stringDate += isNumber(date.month) ? padNumber(date.month) : '';
    }

    return stringDate;
  }
}
