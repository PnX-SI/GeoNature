import { LOCALE_ID, Provider } from '@angular/core';
import { LocaleService } from './services/locale.service';

export class LocaleId extends String {
  constructor(private localeService: LocaleService) {
    super();
  }

  toString(): string {
    return this.localeService.currentLocale;
  }

  valueOf(): string {
    return this.toString();
  }
}

export const LocaleProvider: Provider = {
  provide: LOCALE_ID,
  useClass: LocaleId,
  deps: [LocaleService]
};
