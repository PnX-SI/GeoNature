import { Injectable } from '@angular/core';
import { TranslationWidth } from '@librairies/@angular/common';
import { NgbDatepickerI18n, NgbDateStruct } from '@ng-bootstrap/ng-bootstrap';
import { TranslateService } from '@ngx-translate/core';

@Injectable()
export class NgbDatepickerI18nTranslate extends NgbDatepickerI18n {
  private weekdays: string[] = [];
  private months: string[] = [];

  constructor(private translate: TranslateService) {
    super();
    this.loadTexts();
    this.translate.onLangChange.subscribe(() => this.loadTexts());
  }

  private loadTexts() {
    const w = this.translate.instant('Calendar.Weekdays');
    const m = this.translate.instant('Calendar.Months');
    this.weekdays = Array.isArray(w)
      ? w
      : ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    this.months = Array.isArray(m)
      ? m
      : [
          'janvier',
          'février',
          'mars',
          'avril',
          'mai',
          'juin',
          'juillet',
          'août',
          'septembre',
          'octobre',
          'novembre',
          'décembre',
        ];
  }

  getWeekdayLabel(weekday: number, width?: TranslationWidth): string {
    let day = this.weekdays[weekday - 1];
    if (width === TranslationWidth.Narrow) {
      day = day.charAt(0).toUpperCase();
    } else if (width === TranslationWidth.Abbreviated) {
      day = day.substring(0, 3);
    } else if (width === TranslationWidth.Wide) {
      day = day;
    } else if (width === TranslationWidth.Short) {
      day = day.substring(0, 2);
    }
    return day;
  }

  getDayAriaLabel(date: NgbDateStruct): string {
    return `${date.day} ${this.getMonthFullName(date.month)} ${date.year}`;
  }

  getWeekdayShortName(weekday: number): string {
    return this.weekdays[weekday - 1];
  }

  getMonthShortName(month: number): string {
    return this.months[month - 1].substring(0, 3);
  }

  getMonthFullName(month: number): string {
    return this.months[month - 1];
  }
}
