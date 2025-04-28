import { ValidationErrorsId } from "@geonature/services/validators";
import { Injectable } from "@angular/core";
import { TranslateService } from "@ngx-translate/core";

@Injectable({ providedIn: 'root' })
export class ValidatorMessageService {

  private defaultDict: Record<string,string> = {
    // Angular built-in
    required   : 'Ce champ est obligatoire.',
    minlength  : 'Le texte doit contenir au moins {{requiredLength}} caractères (actuellement {{actualLength}}).',
    maxlength  : 'Le texte doit contenir au plus {{requiredLength}} caractères (actuellement {{actualLength}}).',
    pattern    : 'Valeur non valide.',
    min        : 'La valeur doit être ≥ {{min}} (actuellement {{actual}}).',
    max        : 'La valeur doit être ≤ {{max}} (actuellement {{actual}}).',

    //validateurs custom
    [ValidationErrorsId.ARRAY_MIN_LENGTH_ERROR]: 'Il faut au moins {{arrayLength}} éléments.',
    [ValidationErrorsId.IS_OBJECT_ERROR]       : 'Format d’objet invalide.',
    [ValidationErrorsId.MIN_GREATER_THAN_MAX]  : 'Le minimum doit être ≤ le maximum.',
    [ValidationErrorsId.NOT_NUMBER_ERROR]      : 'Le champ doit être un nombre valide.',
    [ValidationErrorsId.COMMA_NOT_ALLOWED]      : 'Le champ de type nombre ne doit pas contenir de virgule. Utilisez le point pour la décimale.',
    file                    : 'Le fichier est trop volumineux.',
    medias                  : 'Format de médias invalide.',
  };

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

    // 3) fallback sur dictionnaire default
    const tmpl = this.defaultDict[key] || 'Valeur invalide.';
    return this.interpolate(tmpl, details);
  }

  /** remplace {{foo}} par details.foo dans une chaîne */
  private interpolate(template: string, details: Record<string,any>): string {
    return template.replace(/\{\{(\w+)\}\}/g, (_, p) =>
      details[p] != null ? details[p] : ''
    );
  }
}
