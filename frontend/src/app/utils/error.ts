import { Injectable } from '@angular/core';
import { MissingTranslationHandler, MissingTranslationHandlerParams } from '@ngx-translate/core';

@Injectable()
export class CustomMissingTranslationHandler implements MissingTranslationHandler {
  handle(params: MissingTranslationHandlerParams): string {
    // Log the missing translation for debugging
    console.warn(`Missing translation for key: ${params.key}`);

    // Return a formatted message instead of just the key
    return `[MISSING: ${params.key}]`;
  }
}
