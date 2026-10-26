import { Injectable, OnDestroy } from '@angular/core';
import { UntypedFormBuilder, UntypedFormGroup, Validators } from '@angular/forms';
import { Observable, Subject, combineLatest, of } from 'rxjs';
import { map, filter, tap, switchMap, pairwise, takeUntil } from 'rxjs/operators';
import _ from 'lodash';

import { OcctaxFormService } from '../../occtax-form.service';
import { OcctaxFormParamService } from '../../form-param/form-param.service';
import { MediaService } from '@geonature_common/service/media.service';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { PhytoCountingsService } from '../services/countings.service';
import { PhytoOccurrenceService } from './occurrence.service';
import { minBelowMaxValidator } from '@geonature/services/validators';


@Injectable()
export class PhytoCountingService implements OnDestroy {
  counting: Subject<any[]> = new Subject();
  additionalFieldsForm: any[] = [];
  public form: UntypedFormGroup;
  public data: any;

  private readonly destroy$ = new Subject<void>();

  constructor(
    public dataFormService: DataFormService,
    private fb: UntypedFormBuilder,
    private occtaxFormService: OcctaxFormService,
    private phytoOccurrenceService: PhytoOccurrenceService,
    private phytoCountingsService: PhytoCountingsService,
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
        id_individual: null,
        id_nomenclature_sex: [null, Validators.required],
        id_nomenclature_obj_count: [null, Validators.required],
        id_nomenclature_type_count: null,
        id_nomenclature_vegetation_stratum: null,
        id_nomenclature_phytosociological_abundance: null,
        count_min: [null, [Validators.required, Validators.pattern('[0-9]+')]],
        count_max: [null, [Validators.required, Validators.pattern('[0-9]+')]],
        medias: [[], this.mediaService.mediasValidator()],
        additional_fields: this.fb.group({}),
      },
      {
        validators: [minBelowMaxValidator('count_min', 'count_max')],
      }
    );
    this.phytoOccurrenceService.addCountingForm(this.form);
  }

  private setObservables() {
    /**
     * patch form with eventual additional fields
     */
    combineLatest(
      this.counting.pipe(
        switchMap((counting) =>
          this.defaultValues.pipe(
            map((defaults) => ({
              ...defaults,
              ...counting
            }))
          )
        )
      ),
      this.phytoCountingsService.additionalFields.asObservable()
    )
      .pipe(
        tap(([counting, additional_fields]) => {
          if (counting.additional_fields) {
            //manage additional_fields
            additional_fields.forEach((field) => {
              //Formattage des dates
              if (field.type_widget == 'date') {
                //On peut passer plusieurs fois ici, donc on vérifie que la date n'est pas déja formattée
                if (typeof counting.additional_fields[field.attribut_name] !== 'object') {
                  counting.additional_fields[field.attribut_name] =
                    this.occtaxFormService.formatDate(
                      counting.additional_fields[field.attribut_name]
                    );
                }
              }

              //set value of field (eq patchValue)
              if (counting.additional_fields[field.attribut_name] !== undefined) {
                field.value = counting.additional_fields[field.attribut_name];
              }
            });
          }

          return [counting, additional_fields];
        }),
        tap(([counting, additional_fields]) => {
          this.additionalFieldsForm = additional_fields;
        }),
        //map for return occurrence data only
        map(([counting, additional_fields]): any => counting),
        takeUntil(this.destroy$)
      )
      .subscribe((counting) => this.form.patchValue(counting));

    this.form
      .get('count_min')
      .valueChanges.pipe(
        pairwise(),
        filter(([count_min_prev, count_min_new]) => {
          return count_min_prev == this.form.value.count_max;
        }),
        map(([count_min_prev, count_min_new]) => count_min_new),
        takeUntil(this.destroy$)
      )
      .subscribe((count_min) => this.form.get('count_max').setValue(count_min));
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
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
            // id_nomenclature_vegetation_stratum:
            //   this.occtaxParamS.get('counting.id_nomenclature_vegetation_stratum') || DATA['STRATE_VEGETATION'],
            // id_nomenclature_phytosociological_abundance:
            //   this.occtaxParamS.get('counting.id_nomenclature_phytosociological_abundance') || DATA['BRAUNBARK'],
            additional_fields: {},
          };
        })
      );
  }
}
