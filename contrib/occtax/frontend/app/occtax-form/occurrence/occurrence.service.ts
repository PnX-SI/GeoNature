import { Injectable } from '@angular/core';
import {
  FormBuilder,
  FormGroup,
  Validators,
  FormArray,
  ValidatorFn,
  ValidationErrors,
  AbstractControl,
} from '@angular/forms';
import { BehaviorSubject, Observable, of, forkJoin, combineLatest } from 'rxjs';
import {
  map,
  filter,
  switchMap,
  tap,
  pairwise,
  retry,
  mergeMap,
  distinctUntilChanged,
  first,
  catchError,
} from 'rxjs/operators';
import { CommonService } from '@geonature_common/service/common.service';
import { OcctaxFormService } from '../occtax-form.service';
import { OcctaxFormCountingsService } from '../counting/countings.service';
import { OcctaxDataService } from '../../services/occtax-data.service';
import { OcctaxFormParamService } from '../form-param/form-param.service';
import { OcctaxTaxaListService } from '../taxa-list/taxa-list.service';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { ModuleConfig } from '../../module.config';
import { NgbDateParserFormatter } from '@ng-bootstrap/ng-bootstrap';

@Injectable()
export class OcctaxFormOccurrenceService {
  public form: FormGroup;
  public taxref: BehaviorSubject<any> = new BehaviorSubject(null);
  public lifeStage: BehaviorSubject<any> = new BehaviorSubject(null);
  public occurrence: BehaviorSubject<any> = new BehaviorSubject(null);
  // public countings: any[];
  public existProof_DATA: Array<any> = [];
  public saveWaiting: boolean = false;

  public data: any;

  public additionalFieldsForm: any[] = [];

  public profilErrors = [];

  public formFieldsStatus: any;

  constructor(
    private fb: FormBuilder,
    private commonService: CommonService,
    private occtaxFormService: OcctaxFormService,
    private occtaxFormCountingsService: OcctaxFormCountingsService,
    private occtaxDataService: OcctaxDataService,
    private occtaxParamS: OcctaxFormParamService,
    private occtaxTaxaListService: OcctaxTaxaListService,
    private dateParser: NgbDateParserFormatter,
    private _dataS: DataFormService
  ) {
    this.initForm();
    this.setObservables();
  }

  initForm(): void {
    this.form = this.fb.group({
      id_nomenclature_obs_technique: [null, Validators.required],
      id_nomenclature_bio_condition: [null, Validators.required],
      id_nomenclature_bio_status: null,
      id_nomenclature_naturalness: null,
      id_nomenclature_exist_proof: null,
      id_nomenclature_behaviour: null,
      id_nomenclature_observation_status: null,
      id_nomenclature_blurring: null,
      id_nomenclature_source_status: null,
      determiner: null,
      id_nomenclature_determination_method: null,
      nom_cite: [null, Validators.required],
      cd_nom: [null, Validators.required],
      meta_v_taxref: null,
      sample_number_proof: null,
      digital_proof: null,
      non_digital_proof: null,
      comment: null,
      additional_fields: this.fb.group({}),
      cor_counting_occtax: this.fb.array([], Validators.required),
    });
  }

  /**
   * Initialise les observables pour la mise en place des actions automatiques
   **/
  private setObservables() {
    //patch le form par les valeurs par defaut si creation
    const $_occurrenceSub = this.occurrence.pipe(
      switchMap((occurrence) => {
        //on oriente la source des données pour patcher le formulaire
        return occurrence ? this.occurrence : this.defaultValues;
      }),
      tap(
        (occurrence) => (this.occtaxFormCountingsService.countings = occurrence.cor_counting_occtax)
      ),
      //get additional global fields from occurrence, datasaet fields are taken by occtax-form.service > occtaxData observable
      switchMap((occurrence): Observable<any[]> => {
        //observable : get occurrence & countinf filed in same array, explode for separate into double array (occ array & couting array)
        const $_globalFieldsObservable = this.occtaxFormService
          .getAdditionnalFields(['OCCTAX_OCCURENCE'])
          .pipe(catchError(() => of([])));

        return forkJoin(of(occurrence), $_globalFieldsObservable);
      })
    );

    /**
     * Get dataset additional fields
     */
    const $_datasetSub = this.occtaxFormService.occtaxData.asObservable().pipe(
      map((data) => (((data || {}).releve || {}).properties || {}).id_dataset),
      filter((id_dataset) => id_dataset !== undefined && id_dataset !== null),
      switchMap((id_dataset): Observable<any[]> => {
        return this.occtaxFormService
          .getAdditionnalFields(['OCCTAX_OCCURENCE'], id_dataset)
          .pipe(catchError(() => of([])));
      })
    );

    //observ global and dataset additional fields to set additionalFieldsForm only one time on each change (optimise memory usage)
    combineLatest($_occurrenceSub, $_datasetSub)
      .pipe(
        map(([[occurrence, global_additional_fields], dataset_additional_fields]) => {
          const additional_fields = [].concat(global_additional_fields, dataset_additional_fields);
          return [occurrence, additional_fields];
        }),
        tap(([occurrence, additional_fields]) => {
          //manage occ_additional_f
          additional_fields.forEach((field) => {
            //Formattage des dates
            if (field.type_widget == 'date') {
              //On peut passer plusieurs fois ici, donc on vérifie que la date n'est pas déja formattée
              if (typeof occurrence.additional_fields[field.attribut_name] !== 'object') {
                occurrence.additional_fields[field.attribut_name] =
                  this.occtaxFormService.formatDate(
                    occurrence.additional_fields[field.attribut_name]
                  );
              }
            }

            //set value of field (eq patchValue)
            if (occurrence.additional_fields[field.attribut_name] !== undefined) {
              field.value = occurrence.additional_fields[field.attribut_name];
            }
          });

          return [occurrence, additional_fields];
        }),
        tap(([occurrence, additional_fields]) => {
          this.additionalFieldsForm = additional_fields;
        }),
        //map for return occurrence data only
        map(([occurrence, additional_fields]): any => occurrence)
      )
      .subscribe((occurrence: any) => this.form.patchValue(occurrence));

    //Gestion des erreurs pour les preuves d'existence
    this.form
      .get('id_nomenclature_exist_proof')
      .valueChanges.pipe(
        map((id_nomenclature: number): string => {
          return this.getCdNomenclatureById(id_nomenclature, this.existProof_DATA);
        })
      )
      .subscribe((cd_nomenclature: string) => {
        if (cd_nomenclature == '1') {
          this.form.setValidators(proofRequiredValidator);
          this.form
            .get('digital_proof')
            .setValidators(
              ModuleConfig.digital_proof_validator
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
        })
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
        })
      )
      .subscribe((val) => this.form.get('non_digital_proof').setValue(val));
  }

  private get defaultValues(): Observable<any> {
    return this.occtaxFormService
      .getDefaultValues(this.occtaxFormService.currentUser.id_organisme)
      .pipe(
        map((DATA) => {
          return {
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
          };
        })
      );
  }

  addCountingForm(form: FormGroup): void {
    (this.form.get('cor_counting_occtax') as FormArray).push(form);
  }

  getCdNomenclatureById(IdNomenclature, DATA) {
    //currentCD = null;
    let i = 0;
    while (i < DATA.length) {
      if (DATA[i].id_nomenclature == IdNomenclature) {
        return DATA[i].cd_nomenclature;
      }
      i++;
    }
    return null;
  }

  submitOccurrence() {
    let formValue = Object.assign({}, this.form.value);

    formValue = this.occurrenceFormValue();

    let id_releve = this.occtaxFormService.id_releve_occtax.getValue();
    let TEMP_ID_OCCURRENCE = this.uuidv4();

    this.occtaxTaxaListService.addOccurrenceInProgress(
      TEMP_ID_OCCURRENCE,
      this.occurrence.getValue() !== null
        ? Object.assign(this.occurrence.getValue(), this.form.value)
        : this.form.value //pour gerer la modification si erreur
    );

    let api: Observable<any>;

    if (this.occurrence.getValue() && this.occurrence.getValue().id_occurrence_occtax) {
      //update
      api = this.occtaxDataService
        .updateOccurrence(this.occurrence.getValue().id_occurrence_occtax, this.form.value)
        .pipe(
          retry(3),
          tap((occurrence) => {
            this.commonService.translateToaster('info', 'Taxon.UpdateDone');
            this.occtaxFormService.replaceOccurrenceData(occurrence);
          })
        );
    } else {
      //create
      api = this.occtaxDataService.createOccurrence(id_releve, formValue).pipe(
        tap((occurrence) => {
          this.commonService.translateToaster('info', 'Taxon.CreateDone');
          this.occtaxFormService.addOccurrenceData(occurrence);
        })
      );
    }

    api.subscribe(
      (occurrence) => {
        this.occtaxTaxaListService.removeOccurrenceInProgress(TEMP_ID_OCCURRENCE);
      },
      (error) => {
        this.commonService.translateToaster('error', 'ErrorMessage');
        this.occtaxTaxaListService.errorOccurrenceInProgress(TEMP_ID_OCCURRENCE);
      }
    );

    //vide le formulaire
    this.reset();
  }

  deleteOccurrence(occurrence) {
    this.occtaxDataService.deleteOccurrence(occurrence.id_occurrence_occtax).subscribe(
      (confirm: boolean) => {
        this.occtaxFormService.removeOccurrenceData(occurrence.id_occurrence_occtax);
        this.commonService.translateToaster('info', 'Taxon.DeleteDone');
      },
      (error) => {
        this.commonService.translateToaster('error', 'ErrorMessage');
      }
    );
  }

  occurrenceFormValue() {
    let value = JSON.parse(JSON.stringify(this.form.value));

    /* Champs additionnels - formatter les dates et les nomenclatures */
    this.additionalFieldsForm.forEach((fieldForm: any) => {
      if (fieldForm.type_widget == 'date') {
        value.properties.additional_fields[fieldForm.attribut_name] = this.dateParser.format(
          value.properties.additional_fields[fieldForm.attribut_name]
        );
      }
    });

    //TODO: recuperer les info des counting à partir du counting.service
    return value;
  }

  reset() {
    this.form.reset();
    this.occurrence.next(null);
  }

  private clearFormArray(formArray: FormArray) {
    while (formArray.length !== 0) {
      formArray.removeAt(0);
    }
  }

  private uuidv4() {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
      var r = (Math.random() * 16) | 0,
        v = c == 'x' ? r : (r & 0x3) | 0x8;
      return v.toString(16);
    });
  }
}

export const proofRequiredValidator: ValidatorFn = (
  control: FormGroup
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

export function proofNotNullValidator(control: AbstractControl): { [key: string]: boolean } | null {
  if (control.value !== null) {
    return { proofNotNull: true };
  }
  return null;
}
