import { Injectable, OnDestroy } from '@angular/core';
import {
  FormControl,
  FormGroup,
  Validators,
  FormArray,
  ValidatorFn,
  ValidationErrors,
  AbstractControl,
} from '@angular/forms';
import { BehaviorSubject, Observable, Subject, of, combineLatest } from 'rxjs';
import {
  map,
  filter,
  switchMap,
  tap,
  pairwise,
  retry,
  catchError,
  takeUntil,
} from 'rxjs/operators';
import { CommonService } from '@geonature_common/service/common.service';
import { OcctaxFormService } from '../../occtax-form.service';
import { PhytoCountingStateService } from './counting-state.service';
import { OcctaxDataService } from '../../../services/occtax-data.service';
import { OcctaxFormParamService } from '../../form-param/form-param.service';
import { OcctaxTaxaListService } from '../../taxa-list/taxa-list.service'; // TODO: change this to phyto-taxa-list
import { NgbDateParserFormatter, NgbDateStruct } from '@ng-bootstrap/ng-bootstrap';
import { OcctaxConfigService } from '../../../services/occtax-config.service';
import { Nomenclature } from '@geonature_common/interfaces';
import {
  AdditionalFieldDefinition,
  CountingForm,
  CountingFormControls,
  Occurrence,
  OccurrenceForm,
  OccurrenceFormControls,
  TaxonReference,
  PhytoData,
} from '../utils/interfaces';

@Injectable()
export class PhytoOccurrenceService implements OnDestroy {
  public form: OccurrenceForm;
  public taxref = new BehaviorSubject<TaxonReference | null>(null);
  public lifeStage = new BehaviorSubject<number | null>(null);
  public occurrence = new BehaviorSubject<Occurrence | null>(null);
  public existProof_DATA: Nomenclature[] = [];
  public saveWaiting: boolean = false;

  public data: Occurrence | null = null;

  public additionalFieldsForm: AdditionalFieldDefinition[] = [];

  private readonly destroy$ = new Subject<void>();

  constructor(
    private commonService: CommonService,
    private occtaxFormService: OcctaxFormService,
    private countingStateService: PhytoCountingStateService,
    private occtaxDataService: OcctaxDataService,
    private occtaxParamS: OcctaxFormParamService,
    private occtaxTaxaListService: OcctaxTaxaListService,
    private dateParser: NgbDateParserFormatter,
    public occtaxConfig: OcctaxConfigService
  ) {
    this.initForm();
    this.setObservables();
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
    this.taxref.complete();
    this.lifeStage.complete();
    this.occurrence.complete();
  }

  initForm(): void {
    const nullableNumber = () => new FormControl<number | null>(null);
    const nullableString = () => new FormControl<string | null>(null);
    this.form = new FormGroup<OccurrenceFormControls>({
      id_nomenclature_obs_technique: nullableNumber(),
      id_nomenclature_bio_condition: nullableNumber(),
      id_nomenclature_bio_status: nullableNumber(),
      id_nomenclature_naturalness: nullableNumber(),
      id_nomenclature_exist_proof: nullableNumber(),
      id_nomenclature_behaviour: nullableNumber(),
      id_nomenclature_observation_status: nullableNumber(),
      id_nomenclature_blurring: nullableNumber(),
      id_nomenclature_source_status: nullableNumber(),
      determiner: nullableString(),
      id_nomenclature_determination_method: nullableNumber(),
      id_nomenclature_organism_support: nullableNumber(),
      nom_cite: new FormControl<string | null>(null, Validators.required),
      cd_nom: new FormControl<number | null>(null, Validators.required),
      meta_v_taxref: new FormControl<unknown>(null),
      sample_number_proof: nullableString(),
      digital_proof: nullableString(),
      non_digital_proof: nullableString(),
      comment: nullableString(),
      additional_fields: new FormGroup<Record<string, FormControl<unknown>>>({}),
      cor_counting_occtax: new FormArray<FormGroup<CountingFormControls>>(
        [],
        atLeastOneAbundanceValidator
      ),
    });
  }

  /**
   * Initialise les observables pour la mise en place des actions automatiques
   **/
  private setObservables() {
    //patch le form par les valeurs par defaut si creation
    const occurrenceFields$ = this.occurrence.pipe(
      switchMap((occurrence) => {
        //on oriente la source des données pour patcher le formulaire
        return occurrence ? of(occurrence) : this.defaultValues;
      }),
      tap((occurrence) => {
        this.countingStateService.countings = occurrence.cor_counting_occtax || [];
      }),
      //get additional global fields from occurrence, datasaet fields are taken by occtax-form.service > occtaxData observable
      switchMap((occurrence) => {
        const globalFields$: Observable<AdditionalFieldDefinition[]> = this.occtaxFormService
          .getAdditionnalFields(['OCCTAX_OCCURRENCE'])
          .pipe(
            catchError((error: unknown) => {
              this.reportAdditionalFieldsError(error);
              return of([] as AdditionalFieldDefinition[]);
            })
          );

        return combineLatest([of(occurrence), globalFields$]);
      })
    );

    const datasetFields$: Observable<AdditionalFieldDefinition[]> =
      this.occtaxFormService.occtaxData.asObservable().pipe(
        map((data: PhytoData) => data?.releve?.properties?.id_dataset),
        filter((id_dataset) => id_dataset !== undefined && id_dataset !== null),
        switchMap((id_dataset) => {
          return this.occtaxFormService
            .getAdditionnalFields(['OCCTAX_OCCURRENCE'], String(id_dataset))
            .pipe(
              catchError((error: unknown) => {
                this.reportAdditionalFieldsError(error);
                return of([] as AdditionalFieldDefinition[]);
              })
            );
        })
      );

    combineLatest([occurrenceFields$, datasetFields$])
      .pipe(
        map(([[occurrence, globalFields], datasetFields]) => ({
          occurrence,
          additionalFields: [...globalFields, ...datasetFields],
        })),
        tap(({ occurrence, additionalFields }) => {
          additionalFields.forEach((field) => {
            const value = occurrence.additional_fields?.[field.attribut_name];
            if (field.type_widget === 'date' && typeof value === 'string') {
              occurrence.additional_fields![field.attribut_name] =
                this.occtaxFormService.formatDate(value);
            }
            if (value !== undefined) {
              field.value = occurrence.additional_fields?.[field.attribut_name];
            }
          });
          this.additionalFieldsForm = additionalFields;
        }),
        takeUntil(this.destroy$)
      )
      .subscribe(({ occurrence }) => this.form.patchValue(occurrence));

    //Gestion des erreurs pour les preuves d'existence
    this.form
      .get('id_nomenclature_exist_proof')
      .valueChanges.pipe(
        map((id_nomenclature: number): string => {
          return this.getCdNomenclatureById(id_nomenclature, this.existProof_DATA);
        }),
        takeUntil(this.destroy$)
      )
      .subscribe((cd_nomenclature: string) => {
        if (cd_nomenclature == '1') {
          this.form.setValidators(proofRequiredValidator);
          this.form
            .get('digital_proof')
            .setValidators(
              this.occtaxConfig.moduleConf.digital_proof_validator
                ? Validators.pattern('^(http://|https://|ftp://){1}.+$')
                : []
            );
          this.form.get('non_digital_proof').setValidators([]);
        } else {
          this.form.setValidators([]);
          this.form.get('digital_proof').setValidators(proofNotNullValidator);
          this.form.get('non_digital_proof').setValidators(proofNotNullValidator);
        }
        this.form.updateValueAndValidity();
        this.form.get('digital_proof').updateValueAndValidity();
        this.form.get('non_digital_proof').updateValueAndValidity();
      });

    //reset digital_proof à null si texte vide : ''
    this.form
      .get('digital_proof')
      .valueChanges.pipe(
        filter((val) => val !== null), //filtre la valeur null
        pairwise(),
        filter(([prev, next]: [string, string]) => prev !== next),
        map(([prev, next]: [string, string]) => {
          return next.length > 0 ? next : null;
        }),
        takeUntil(this.destroy$)
      )
      .subscribe((val) => this.form.get('digital_proof').setValue(val));

    //reset non_digital_proof à null si texte vide : ''
    this.form
      .get('non_digital_proof')
      .valueChanges.pipe(
        filter((val) => val !== null), //filtre la valeur null
        pairwise(),
        filter(([prev, next]: [string, string]) => prev !== next),
        map(([prev, next]: [string, string]) => {
          return next.length > 0 ? next : null;
        }),
        takeUntil(this.destroy$)
      )
      .subscribe((val) => this.form.get('non_digital_proof').setValue(val));
  }

  private get defaultValues(): Observable<Occurrence> {
    return this.occtaxFormService
      .getDefaultValues(this.occtaxFormService.currentUser.id_organisme)
      .pipe(
        map(
          (DATA): Occurrence => ({
            determiner:
              this.occtaxParamS.get('occurrence.determiner') ||
              this.occtaxFormService.currentUser.nom_complet,
            sample_number_proof: this.occtaxParamS.get('occurrence.sample_number_proof'),
            digital_proof: this.occtaxParamS.get('occurrence.digital_proof'),
            non_digital_proof: this.occtaxParamS.get('occurrence.non_digital_proof'),
            comment: this.occtaxParamS.get('occurrence.comment'),
            id_nomenclature_bio_condition:
              this.occtaxParamS.get('occurrence.id_nomenclature_bio_condition') || DATA['ETA_BIO'],
            id_nomenclature_naturalness:
              this.occtaxParamS.get('occurrence.id_nomenclature_naturalness') || DATA['NATURALITE'],
            id_nomenclature_obs_technique:
              this.occtaxParamS.get('occurrence.id_nomenclature_obs_technique') || DATA['METH_OBS'],
            id_nomenclature_bio_status:
              this.occtaxParamS.get('occurrence.id_nomenclature_bio_status') || DATA['STATUT_BIO'],
            id_nomenclature_exist_proof:
              this.occtaxParamS.get('occurrence.id_nomenclature_exist_proof') ||
              DATA['PREUVE_EXIST'],
            id_nomenclature_determination_method:
              this.occtaxParamS.get('occurrence.id_nomenclature_determination_method') ||
              DATA['METH_DETERMIN'],
            id_nomenclature_observation_status:
              this.occtaxParamS.get('occurrence.id_nomenclature_observation_status') ||
              DATA['STATUT_OBS'],
            id_nomenclature_blurring:
              this.occtaxParamS.get('occurrence.id_nomenclature_blurring') || DATA['DEE_FLOU'],
            id_nomenclature_source_status:
              this.occtaxParamS.get('occurrence.id_nomenclature_source_status') ||
              DATA['STATUT_SOURCE'],
            id_nomenclature_behaviour:
              this.occtaxParamS.get('occurrence.id_nomenclature_behaviour') ||
              DATA['OCC_COMPORTEMENT'],
            additional_fields: {},
            cor_counting_occtax: [{}],
          })
        )
      );
  }

  addCountingForm(form: CountingForm): void {
    this.form.controls.cor_counting_occtax.push(form);
  }

  getCdNomenclatureById(
    idNomenclature: number | null,
    nomenclatures: Nomenclature[]
  ): string | null {
    return (
      nomenclatures.find((nomenclature) => nomenclature.id_nomenclature === idNomenclature)
        ?.cd_nomenclature || null
    );
  }

  submitOccurrence() {
    const formValue = this.occurrenceFormValue();

    if (formValue.cor_counting_occtax) {
      formValue.cor_counting_occtax = formValue.cor_counting_occtax.filter((counting) => {
        return counting.id_nomenclature_phytosociological_abundance !== null;
      });
    }

    const idReleve = this.occtaxFormService.id_releve_occtax.getValue();
    const temporaryOccurrenceId = this.uuidv4();

    this.occtaxTaxaListService.addOccurrenceInProgress(
      temporaryOccurrenceId,
      this.occurrence.getValue() !== null
        ? Object.assign(this.occurrence.getValue(), this.form.value)
        : this.form.value //pour gerer la modification si erreur
    );

    let api: Observable<Occurrence>;

    if (this.occurrence.getValue() && this.occurrence.getValue().id_occurrence_occtax) {
      //update
      api = this.occtaxDataService
        .updateOccurrence(this.occurrence.getValue().id_occurrence_occtax, formValue)
        .pipe(
          retry(3),
          tap((occurrence) => {
            this.commonService.translateToaster('info', 'Occtax.Taxon.Messages.UpdateDone');
            this.occtaxFormService.replaceOccurrenceData(occurrence);
          })
        );
    } else {
      //create
      api = this.occtaxDataService.createOccurrence(idReleve, formValue).pipe(
        tap((occurrence) => {
          this.commonService.translateToaster('info', 'Occtax.Taxon.Messages.CreateDone');
          this.occtaxFormService.addOccurrenceData(occurrence);
        })
      );
    }

    api.subscribe(
      (occurrence) => {
        this.occtaxTaxaListService.removeOccurrenceInProgress(temporaryOccurrenceId);
      },
      (error) => {
        this.commonService.translateToaster('error', 'Errors.ErrorOccurs');
        this.occtaxTaxaListService.errorOccurrenceInProgress(temporaryOccurrenceId);
      }
    );

    //vide le formulaire
    this.reset();
  }

  deleteOccurrence(occurrence: Occurrence): void {
    if (occurrence.id_occurrence_occtax == null) {
      return;
    }

    this.occtaxDataService
      .deleteOccurrence(occurrence.id_occurrence_occtax)
      .subscribe(
        (confirm: boolean) => {
          this.occtaxFormService.removeOccurrenceData(occurrence.id_occurrence_occtax);
          this.commonService.translateToaster('info', 'Occtax.Taxon.Messages.DeleteDone');
        },
        (error) => {
          this.commonService.translateToaster('error', 'Errors.ErrorOccurs');
        }
      );
  }

  private reportAdditionalFieldsError(error: unknown): void {
    console.error('Error loading phyto occurrence additional fields:', error);
    this.commonService.translateToaster('error', 'Errors.ErrorOccurs');
  }

  occurrenceFormValue(): Occurrence {
    const value = this.form.getRawValue();
    /* Champs additionnels - formatter les dates et les nomenclatures */
    this.additionalFieldsForm.forEach((fieldForm: AdditionalFieldDefinition) => {
      if (fieldForm.type_widget == 'date') {
        const dateValue = value.additional_fields[fieldForm.attribut_name];
        if (isNgbDateStruct(dateValue)) {
          value.additional_fields[fieldForm.attribut_name] = this.dateParser.format(dateValue);
        }
      }
    });

    return value;
  }

  reset(): void {
    this.form.reset();
    this.occurrence.next(null);
  }

  private uuidv4() {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
      var r = (Math.random() * 16) | 0,
        v = c == 'x' ? r : (r & 0x3) | 0x8;
      return v.toString(16);
    });
  }
}

function isNgbDateStruct(value: unknown): value is NgbDateStruct {
  if (typeof value !== 'object' || value === null) {
    return false;
  }
  return (
    'year' in value &&
    'month' in value &&
    'day' in value &&
    typeof value.year === 'number' &&
    typeof value.month === 'number' &&
    typeof value.day === 'number'
  );
}

export const proofRequiredValidator: ValidatorFn = (
  control: AbstractControl
): ValidationErrors | null => {
  const digital_proof = control.get('digital_proof');
  const non_digital_proof = control.get('non_digital_proof');

  if (
    digital_proof &&
    non_digital_proof &&
    digital_proof.value === null &&
    non_digital_proof.value === null
  ) {
    return { proofRequired: true };
  }

  return null;
};

export function proofNotNullValidator(control: AbstractControl): ValidationErrors | null {
  if (control.value !== null) {
    return { proofNotNull: true };
  }
  return null;
}

export const atLeastOneAbundanceValidator: ValidatorFn = (
  control: AbstractControl
): ValidationErrors | null => {
  const countings = control as FormArray<FormGroup<CountingFormControls>>;
  const hasAbundance = countings.controls.some(
    (counting) =>
      counting.controls.id_nomenclature_phytosociological_abundance.value != null
  );

  return hasAbundance ? null : { required: true };
};
