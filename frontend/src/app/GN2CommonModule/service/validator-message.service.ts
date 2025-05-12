import { ValidationErrorsId } from "@geonature/services/validators";
import { Injectable } from "@angular/core";
import { TranslateService } from "@ngx-translate/core";

@Injectable({ providedIn: 'root' })
export class ValidatorMessageService {


  constructor(private translate: TranslateService) {}
   /**
   * Renvoie le message d'erreur à afficher pour un contrôle donné
   * @param key            : première clé d'erreur du contrôle (min, required, notNumber…)
   * @param details        : ctrl.getError(key) (payload min/max/actual/etc)
   * @param overrideDict   : overrideMessages passés dans le template
   * @param prefix         : préfixe i18n ("Errors" ou "ValidationError")
   */
   getMessage(
    key: string,
    details: Record<string, any> = {},
    overrideDict?: Record<string,string>,
    prefix: string = 'Form.Errors'
  ): string {
    // 1) overrideMessages passe avant tout
    if (overrideDict && overrideDict[key]) {
      return this.interpolate(overrideDict[key], details);
    }

    // 2) tentative i18n
    const translationKey = `${prefix}.${key}`;
    const translated = this.translate.instant(translationKey);
    // si ngx-translate ne trouve pas la clé il renvoie la clé elle-même
    if (translated !== translationKey) {
      return this.interpolate(translated, details); 
    }
  }

  /** remplace {{foo}} par details.foo dans une chaîne */
  private interpolate(template: string, details: Record<string,any>): string {
    return template.replace(/\{\{(\w+)\}\}/g, (_, p) =>
      details[p] != null ? details[p] : ''
    );
  }
}
