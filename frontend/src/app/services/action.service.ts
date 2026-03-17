import { Injectable } from '@angular/core';
import { TranslateService } from '@ngx-translate/core';

@Injectable({
  providedIn: 'root',
})
export class ActionService {
  constructor(private translate: TranslateService) {}

  /**
   * Returns the tooltip for an action (Edit/Delete)
   * @param cruved cruved concerned
   * @param afOpened allows to know if the related acquisition framework is open
   * @param action 'U' for Edit or 'D' for Delete
   * @param moduleName Module name for translation keys (Occhab, Occtax or Import for example)
   * @param objectName Object name for translation keys (Station for Occhab for example)
   * @param tooltipParams Parameters for interpolation in the translation (ex: { id: 123 })
   * @param translateService Allows passing the translation service if the key is not in the GeoNature core
   * @returns string The translated tooltip text
   */
  getActionTooltip(
    cruved: any,
    afOpened: boolean,
    action: 'U' | 'D',
    moduleName: string,
    objectName?: string,
    tooltipParams: any = {},
    translateService?: TranslateService
  ): string {
    const translate = translateService || this.translate;
    if (!afOpened) {
      return translate.instant('MetaData.Messages.ImpossibleActionAFClosed');
    }

    if (!cruved?.[action]) {
      return translate.instant('Errors.NotAllowed');
    }
    const actionType = action === 'D' ? 'Delete' : 'Update';
    const translateKey = objectName
      ? `${moduleName}.${objectName}.Actions.${actionType}`
      : `${moduleName}.Actions.${actionType}`;

    return translate.instant(translateKey, tooltipParams);
  }

  isActionAllowed(cruved: any, afOpened: boolean, action: 'U' | 'D'): boolean {
    const hasRights = cruved?.[action];
    return hasRights && afOpened;
  }
}
