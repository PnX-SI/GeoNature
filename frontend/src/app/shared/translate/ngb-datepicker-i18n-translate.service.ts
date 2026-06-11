import { Injectable } from '@angular/core';
import { TranslationWidth } from '@librairies/@angular/common';
import { NgbDatepickerI18n, NgbDateStruct } from '@ng-bootstrap/ng-bootstrap';
import { TranslateService } from '@ngx-translate/core';

@Injectable()
export class NgbDatepickerI18nTranslate extends NgbDatepickerI18n {
  private weekdays: string[] = [];
  private months: string[] = [];

  // Use TranslateService so the calendar labels are reloaded when the user switches language.
  // NgbDatepickerI18nDefault uses LOCALE_ID and initializes its month/day names only once,
  // so it does not react to dynamic language changes after app startup.
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
      : ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];
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
      day = day.charAt(0);
    } else if (width === TranslationWidth.Abbreviated) {
      day = day.substring(0, 3);
    } else if (width === TranslationWidth.Wide) {
      day = day;
    } else if (width === TranslationWidth.Short) {
      day = day.substring(0, 2);
    }
    return this.capitalize(day);
  }

  getDayAriaLabel(date: NgbDateStruct): string {
    const weekdayNum = this.getWeekdayNumber(date);
    const weekday = this.getWeekdayLabel(weekdayNum);
    return `${weekday}, ${date.day} ${this.getMonthFullName(date.month)} ${date.year}`;
  }

  private getWeekdayNumber(date: NgbDateStruct): number {
    const jsDate = new Date(date.year, date.month - 1, date.day);
    const weekdayNum = jsDate.getDay(); // 0-6, sunday = 0
    // In weekdays translations, index of monday is 0
    const mondayIsFirstDay = weekdayNum === 0 ? 7 : weekdayNum;
    // Return day number in week where monday is 1 and sunday 7
    return mondayIsFirstDay;
  }

  getWeekdayShortName(weekday: number): string {
    return this.capitalize(this.weekdays[weekday - 1]);
  }

  getMonthShortName(month: number): string {
    return this.capitalize(this.months[month - 1].substring(0, 3));
  }

  getMonthFullName(month: number): string {
    return this.capitalize(this.months[month - 1]);
  }

  private capitalize(text: string): string {
    let capitalized = text;
    if (text && text.length > 0) {
      capitalized = text.charAt(0).toUpperCase() + text.slice(1);
    }
    return capitalized;
  }
}
