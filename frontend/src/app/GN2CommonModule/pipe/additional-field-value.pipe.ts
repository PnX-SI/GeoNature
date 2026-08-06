import { PipeTransform, Pipe } from '@angular/core';

const LABEL_PREFIX = '_label_';

/**
 * Résout la valeur à afficher pour un champ d'un dict additional_fields :
 * le libellé "_label_<champ>" s'il existe (cas des champs de type
 * nomenclature), sinon la valeur brute du champ.
 *
 * Usage: {{ releve.additional_fields | additionalFieldValue: 'mon_champ' }}
 */
@Pipe({ name: 'additionalFieldValue' })
export class AdditionalFieldValuePipe implements PipeTransform {
  transform(fields: { [key: string]: any } | null | undefined, fieldName: string): any {
    if (!fields) {
      return undefined;
    }
    const labelKey = LABEL_PREFIX + fieldName;
    return Object.prototype.hasOwnProperty.call(fields, labelKey)
      ? fields[labelKey]
      : fields[fieldName];
  }
}
