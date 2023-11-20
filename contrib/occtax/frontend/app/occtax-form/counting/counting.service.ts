import { Injectable } from '@angular/core';
import { UntypedFormBuilder, UntypedFormGroup, Validators } from '@angular/forms';
import { Observable, Subscription, Subject, combineLatest, of } from 'rxjs';
import { map, filter, tap, switchMap, pairwise } from 'rxjs/operators';
import _ from 'lodash';

import { OcctaxFormService } from '../occtax-form.service';
import { OcctaxFormOccurrenceService } from '../occurrence/occurrence.service';
import { OcctaxFormParamService } from '../form-param/form-param.service';
import { MediaService } from '@geonature_common/service/media.service';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { OcctaxFormCountingsService } from './countings.service';
import { minBelowMaxValidator } from '@geonature/services/validators';
@Injectable()
export class OcctaxFormCountingService {
  counting: Subject<any[]> = new Subject();
  synchroCountSub: Subscription;
  additionalFieldsForm: any[] = [];
  public form: UntypedFormGroup;
  public data: any;

  constructor(
    public dataFormService: DataFormService,
    private fb: UntypedFormBuilder,
    private occtaxFormService: OcctaxFormService,
    private occtaxFormOccurrenceService: OcctaxFormOccurrenceService,
    private occtaxFormCountingsService: OcctaxFormCountingsService,
    private occtaxParamS: OcctaxFormParamService,
    private mediaService: MediaService
  ) {
    this.initForm();
    this.setObservables();
  }

  /**
   * Génére un formulaire vide
   * Cette fonction est appelée par occurrence.service
   */
  initForm(): void {
    this.form = this.fb.group(
      {
        id_counting_occtax: null,
        id_nomenclature_life_stage: [null, Validators.required],
        id_nomenclature_sex: [null, Validators.required],
        id_nomenclature_obj_count: [null, Validators.required],
        id_nomenclature_type_count: null,
        count_min: [null, [Validators.required, Validators.pattern('[0-9]+')]],
        count_max: [null, [Validators.required, Validators.pattern('[0-9]+')]],
        medias: [[], this.mediaService.mediasValidator()],
        additional_fields: this.fb.group({}),
      },
      {
        validators: [minBelowMaxValidator('count_min', 'count_max')],
      }
    );
    this.occtaxFormOccurrenceService.addCountingForm(this.form);
  }

  private setObservables() {
    /**
     * patch form with eventual additional fields
     */
    combineLatest(
      this.counting.pipe(
        switchMap((counting) => (!_.isEmpty(counting) ? of(counting) : this.defaultValues))
      ),
      this.occtaxFormCountingsService.additionalFields.asObservable()
    )
      .pipe(
        tap(([counting, additional_fields]) => {
          //manage additional_fields
          additional_fields.forEach((field) => {
            //Formattage des dates
            if (field.type_widget == 'date') {
              //On peut passer plusieurs fois ici, donc on vérifie que la date n'est pas déja formattée
              if (typeof counting.additional_fields[field.attribut_name] !== 'object') {
                counting.additional_fields[field.attribut_name] = this.occtaxFormService.formatDate(
                  counting.additional_fields[field.attribut_name]
                );
              }
            }

            //set value of field (eq patchValue)
            if (counting.additional_fields[field.attribut_name] !== undefined) {
              field.value = counting.additional_fields[field.attribut_name];
            }
          });

          return [counting, additional_fields];
        }),
        tap(([counting, additional_fields]) => {
          this.additionalFieldsForm = additional_fields;
        }),
        //map for return occurrence data only
        map(([counting, additional_fields]): any => counting)
      )
      .subscribe((counting) => this.form.patchValue(counting));

    this.form
      .get('count_min')
      .valueChanges.pipe(
        pairwise(),
        filter(([count_min_prev, count_min_new]) => {
          return count_min_prev == this.form.value.count_max;
        }),
        map(([count_min_prev, count_min_new]) => count_min_new)
      )
      .subscribe((count_min) => this.form.get('count_max').setValue(count_min));
  }

  private get defaultValues(): Observable<any> {
    return this.occtaxFormService
      .getDefaultValues(this.occtaxFormService.currentUser.id_organisme)
      .pipe(
        map((DATA) => {
          return {
            count_min: this.occtaxParamS.get('counting.count_min') || 1,
            count_max: this.occtaxParamS.get('counting.count_max') || 1,
            id_nomenclature_life_stage:
              this.occtaxParamS.get('counting.id_nomenclature_life_stage') || DATA['STADE_VIE'],
            id_nomenclature_sex:
              this.occtaxParamS.get('counting.id_nomenclature_sex') || DATA['SEXE'],
            id_nomenclature_obj_count:
              this.occtaxParamS.get('counting.id_nomenclature_obj_count') || DATA['OBJ_DENBR'],
            id_nomenclature_type_count:
              this.occtaxParamS.get('counting.id_nomenclature_type_count') || DATA['TYP_DENBR'],
            id_nomenclature_valid_status:
              this.occtaxParamS.get('counting.id_nomenclature_valid_status') ||
              DATA['STATUT_VALID'],
            additional_fields: {},
          };
        })
      );
  }
}
