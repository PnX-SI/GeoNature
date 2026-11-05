import { Injectable, OnDestroy } from '@angular/core';
import { FormControl, FormGroup, Validators } from '@angular/forms';
import { Observable, Subject, combineLatest, of } from 'rxjs';
import { map, filter, tap, switchMap, pairwise, takeUntil } from 'rxjs/operators';

import { OcctaxFormService } from '../../occtax-form.service';
import { OcctaxFormParamService } from '../../form-param/form-param.service';
import { MediaService } from '@geonature_common/service/media.service';
import { PhytoCountingStateService } from './counting-state.service';
import { PhytoOccurrenceService } from './occurrence.service';
import { minBelowMaxValidator } from '@geonature/services/validators';
import {
  AdditionalFieldDefinition,
  Counting,
  CountingForm,
  CountingFormControls,
} from '../utils/interfaces';

@Injectable()
export class PhytoCountingFormService implements OnDestroy {
  public readonly counting = new Subject<Counting>();
  public additionalFieldsForm: AdditionalFieldDefinition[] = [];
  public form: CountingForm;

  private readonly destroy$ = new Subject<void>();

  constructor(
    private occurrenceFormService: OcctaxFormService,
    private phytoOccurrenceService: PhytoOccurrenceService,
    private countingStateService: PhytoCountingStateService,
    private formParamService: OcctaxFormParamService,
    private mediaService: MediaService
  ) {
    this.initForm();
    this.setObservables();
  }

  private initForm(): void {
    this.form = new FormGroup<CountingFormControls>(
      {
        id_counting_occtax: new FormControl<number | null>(null),
        id_nomenclature_life_stage: new FormControl<number | null>(null, Validators.required),
        id_individual: new FormControl<number | null>(null),
        id_nomenclature_sex: new FormControl<number | null>(null, Validators.required),
        id_nomenclature_obj_count: new FormControl<number | null>(null, Validators.required),
        id_nomenclature_type_count: new FormControl<number | null>(null),
        id_nomenclature_vegetation_stratum: new FormControl<number | null>(null),
        id_nomenclature_phytosociological_abundance: new FormControl<number | null>(null),
        count_min: new FormControl<number | null>(null, [
          Validators.required,
          Validators.pattern('[0-9]+'),
        ]),
        count_max: new FormControl<number | null>(null, [
          Validators.required,
          Validators.pattern('[0-9]+'),
        ]),
        medias: new FormControl<unknown[] | null>([], this.mediaService.mediasValidator()),
        additional_fields: new FormGroup<Record<string, FormControl<unknown>>>({}),
      },
      { validators: minBelowMaxValidator('count_min', 'count_max') }
    );
    this.phytoOccurrenceService.addCountingForm(this.form);
  }

  private setObservables(): void {
    combineLatest(
      this.counting.pipe(
        switchMap((counting) =>
          this.defaultValues.pipe(
            map((defaults) => ({
              ...defaults,
              ...counting,
            }))
          )
        )
      ),
      this.countingStateService.additionalFields.asObservable()
    )
      .pipe(
        tap(([counting, additional_fields]) => {
          if (counting.additional_fields) {
            additional_fields.forEach((field) => {
              if (field.type_widget === 'date') {
                if (typeof counting.additional_fields[field.attribut_name] !== 'object') {
                  counting.additional_fields[field.attribut_name] =
                    this.occurrenceFormService.formatDate(
                      String(counting.additional_fields[field.attribut_name])
                    );
                }
              }

              if (counting.additional_fields[field.attribut_name] !== undefined) {
                field.value = counting.additional_fields[field.attribut_name];
              }
            });
          }
        }),
        tap(([counting, additional_fields]) => {
          this.additionalFieldsForm = additional_fields;
        }),
        takeUntil(this.destroy$)
      )
      .subscribe(([counting]) => {
        const { additional_fields, ...countingValues } = counting;
        this.form.patchValue(countingValues);
        Object.entries(additional_fields || {}).forEach(([key, value]) => {
          this.form.controls.additional_fields.controls[key]?.setValue(value);
        });
      });

    this.form.controls.count_min.valueChanges
      .pipe(
        pairwise(),
        filter(([previousMinimum]) => previousMinimum === this.form.controls.count_max.value),
        map(([, nextMinimum]) => nextMinimum),
        takeUntil(this.destroy$)
      )
      .subscribe((count_min) => this.form.controls.count_max.setValue(count_min));
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  private get defaultValues(): Observable<Partial<Counting>> {
    return this.occurrenceFormService
      .getDefaultValues(this.occurrenceFormService.currentUser.id_organisme)
      .pipe(
        map((defaults) => {
          return {
            count_min: this.formParamService.get('counting.count_min') || 1,
            count_max: this.formParamService.get('counting.count_max') || 1,
            id_nomenclature_life_stage:
              this.formParamService.get('counting.id_nomenclature_life_stage') ||
              defaults['STADE_VIE'],
            id_nomenclature_sex:
              this.formParamService.get('counting.id_nomenclature_sex') || defaults['SEXE'],
            id_nomenclature_obj_count:
              this.formParamService.get('counting.id_nomenclature_obj_count') ||
              defaults['OBJ_DENBR'],
            id_nomenclature_type_count:
              this.formParamService.get('counting.id_nomenclature_type_count') ||
              defaults['TYP_DENBR'],
            id_nomenclature_valid_status:
              this.formParamService.get('counting.id_nomenclature_valid_status') ||
              defaults['STATUT_VALID'],
            additional_fields: {},
          };
        })
      );
  }
}
