import { Directive, Input, TemplateRef, ViewContainerRef } from '@angular/core';

const LABEL_PREFIX = '_label_';

export interface AdditionalFieldContext {
  $implicit: {
    name: string;
    label: string;
    value: any;
  };
}

/**
 * Structural directive itérant sur les champs d'un dict additional_fields, en
 * masquant les entrées "_label_<champ>" (fusionnées dans leur champ d'origine)
 * et en substituant la valeur brute d'un champ de type nomenclature par son
 * libellé "_label_<champ>" quand celui-ci existe. Les champs sans libellé
 * associé (texte, select, ...) restent affichés avec leur valeur brute.
 *
 * Usage:
 * <ng-container *additionalFields="let field of releve.additional_fields">
 *   <div>{{ field.label }} : {{ field.value }}</div>
 * </ng-container>
 */
@Directive({
  selector: '[additionalFields]',
})
export class AdditionalFieldsDirective {
  constructor(
    private templateRef: TemplateRef<AdditionalFieldContext>,
    private viewContainerRef: ViewContainerRef
  ) {}

  @Input()
  set additionalFieldsOf(fields: { [key: string]: any } | null | undefined) {
    this.viewContainerRef.clear();
    if (!fields) {
      return;
    }
    Object.keys(fields)
      .filter((key) => !key.startsWith(LABEL_PREFIX))
      .forEach((name) => {
        const labelKey = LABEL_PREFIX + name;
        const hasLabel = Object.prototype.hasOwnProperty.call(fields, labelKey);
        this.viewContainerRef.createEmbeddedView(this.templateRef, {
          $implicit: {
            name,
            label: name,
            value: hasLabel ? fields[labelKey] : fields[name],
          },
        });
      });
  }
}
