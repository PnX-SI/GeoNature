import { Injectable } from "@angular/core";
import { FormBuilder, FormGroup, Validators, FormArray, ValidatorFn, ValidationErrors, AbstractControl
 } from "@angular/forms";
import { BehaviorSubject, Observable } from 'rxjs';
import { map, filter, switchMap, tap, pairwise } from 'rxjs/operators';
import { CommonService } from "@geonature_common/service/common.service";
import { OcctaxFormService } from '../occtax-form.service';
import { OcctaxFormCountingService } from '../counting/counting.service';
import { FormService } from "@geonature_common/form/form.service";
import { OcctaxDataService } from '../../services/occtax-data.service';

@Injectable()
export class OcctaxFormOccurrenceService {

  public form: FormGroup;
  public taxref: BehaviorSubject<any> = new BehaviorSubject(null);
  public occurrence: BehaviorSubject<any> = new BehaviorSubject(null);
  public existProof_DATA: Array<any> = [];

  public saveWaiting: boolean = false;

  constructor(
    private fb: FormBuilder,
    private commonService: CommonService,
    private coreFormService: FormService,
    private occtaxFormService: OcctaxFormService,
    private occtaxFormCountingService: OcctaxFormCountingService,
    private occtaxDataService: OcctaxDataService
  ) {
    this.initForm();
    this.setObservables();
  }

  private get initialValues() {
    return {
      determiner: this.occtaxFormService.currentUser.nom_complet
    };
  }

  initForm(): void {
    this.form = this.fb.group({
      id_nomenclature_obs_meth: [null, Validators.required],
      id_nomenclature_bio_condition: [null, Validators.required],
      id_nomenclature_bio_status: null,
      id_nomenclature_naturalness: null,
      id_nomenclature_exist_proof: null,
      id_nomenclature_observation_status: null,
      id_nomenclature_diffusion_level: null,
      id_nomenclature_blurring: null,
      id_nomenclature_source_status: null,
      determiner: [null, Validators.required],
      id_nomenclature_determination_method: [null, Validators.required],
      nom_cite: [null, Validators.required],
      cd_nom: [null, Validators.required],
      meta_v_taxref: null,
      sample_number_proof: null,
      digital_proof: null,
      non_digital_proof: null,
      comment: null,
      cor_counting_occtax: this.fb.array([], Validators.required)
    });

    this.form.patchValue(this.initialValues);
  }

  /**
  * Initialise les observables pour la mise en place des actions automatiques
  **/
  private setObservables() {

    //patch le form par les valeurs par defaut si creation
    this.occurrence
      .pipe(
        tap(()=>{
          //On vide préalablement le FormArray //.clear() existe en angular 8
          this.clearFormArray((this.form.get('cor_counting_occtax') as FormArray));
        }),
        switchMap(occurrence => {
          //on oriente la source des données pour patcher le formulaire
          return occurrence ? this.occurrence : this.defaultValues;
        }),
        tap(occurrence=>{
          //mise en place des countingForm
          if (occurrence.cor_counting_occtax) {
            occurrence.cor_counting_occtax.forEach((c, i)=>{
              this.addCountingForm(occurrence.id_occurrence_occtax === null); //si id_occurrence_occtax === null on patch le form avec les valeurs par defauts
            })
          }
        })
      ).subscribe(values=>{this.form.patchValue(values)});

    //Gestion des erreurs pour les preuves d'existence
    this.form.get('id_nomenclature_exist_proof')
                            .valueChanges
                            .pipe(
                              map((id_nomenclature: number): string=>{
                                return this.getCdNomenclatureById(
                                                id_nomenclature,
                                                this.existProof_DATA
                                              );
                              })
                            )
                            .subscribe((cd_nomenclature: string)=>{
                              if (cd_nomenclature == "1") {
                                this.form.setValidators(proofRequiredValidator);
                                this.form.get('digital_proof').setValidators(Validators.pattern("^(http://|https://|ftp://){1}.+$"));
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
    this.form.get('digital_proof')
                            .valueChanges
                            .pipe(
                              filter(val=>val !== null), //filtre la valeur null
                              pairwise(),
                              filter(([prev, next]: [string, string])=>prev !== next),
                              map(([prev, next]: [string, string])=>{return next.length > 0 ? next : null;})
                            )
                            .subscribe(val=>this.form.get('digital_proof').setValue(val));

    //reset non_digital_proof à null si texte vide : ''
    this.form.get('non_digital_proof')
                            .valueChanges
                            .pipe(
                              filter(val=>val !== null), //filtre la valeur null
                              pairwise(),
                              filter(([prev, next]: [string, string])=>prev !== next),
                              map(([prev, next]: [string, string])=>{return next.length > 0 ? next : null;})
                            )
                            .subscribe(val=>this.form.get('non_digital_proof').setValue(val));

  }


  private get defaultValues(): Observable<any> {
    return this.occtaxFormService.getDefaultValues(this.occtaxFormService.currentUser.id_organisme)
                    .pipe(
                      map(DATA=> {
                        return {
                          id_nomenclature_bio_condition: DATA["ETA_BIO"],
                          id_nomenclature_naturalness: DATA["NATURALITE"],
                          id_nomenclature_obs_meth: DATA["METH_OBS"],
                          id_nomenclature_bio_status: DATA["STATUT_BIO"],
                          id_nomenclature_exist_proof: DATA["PREUVE_EXIST"],
                          id_nomenclature_determination_method: DATA["METH_DETERMIN"],
                          id_nomenclature_observation_status: DATA["STATUT_OBS"],
                          id_nomenclature_diffusion_level: DATA["NIV_PRECIS"],
                          id_nomenclature_blurring: DATA["DEE_FLOU"],
                          id_nomenclature_source_status: DATA["STATUT_SOURCE"],
                          cor_counting_occtax: [{
                            id_nomenclature_life_stage: DATA["STADE_VIE"],
                            id_nomenclature_sex: DATA["SEXE"],
                            id_nomenclature_obj_count: DATA["OBJ_DENBR"],
                            id_nomenclature_type_count: DATA["TYP_DENBR"],
                            id_nomenclature_valid_status: DATA["STATUT_VALID"]
                          }]
                        };
                      })
                    );
  }

  addCountingForm(patchWithDefaultValue: boolean = false): void {
    (this.form.get('cor_counting_occtax') as FormArray).push(this.occtaxFormCountingService.createForm(patchWithDefaultValue));
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
    let id_releve = this.occtaxFormService.id_releve_occtax.getValue();
    this.saveWaiting = true;
    if (this.occurrence.getValue()) {
      //update
      this.occtaxDataService
                .updateOccurrence((this.occurrence.getValue()).id_occurrence_occtax, this.form.value)
                .pipe(
                  tap(()=>this.saveWaiting = false)
                )
                .subscribe(occurrence=>{
                  this.commonService.translateToaster(
                    "info",
                    "Taxon.UpdateDone"
                  );
                 this.occtaxFormService.replaceOccurrenceData(occurrence);
                 this.reset();
                });
    } else {
      //create
      this.occtaxDataService
                .createOccurrence(id_releve, this.form.value)
                .pipe(
                  tap(()=>this.saveWaiting = false)
                )
                .subscribe(occurrence=>{
                  this.commonService.translateToaster(
                    "info",
                    "Taxon.CreateDone"
                  );
                  this.occtaxFormService.addOccurrenceData(occurrence);
                  this.reset();
                });
    }
  }

  deleteOccurrence(occurrence) {
    this.occtaxDataService.deleteOccurrence(occurrence.id_occurrence_occtax)
              .subscribe((confirm:boolean)=>{
                this.occtaxFormService.removeOccurrenceData(occurrence.id_occurrence_occtax);
                this.commonService.translateToaster(
                  "info",
                  "Taxon.DeleteDone"
                );
              });
  }

  reset() {
    this.form.reset(this.initialValues);
    this.occurrence.next(null);
  }

  private clearFormArray(formArray: FormArray) {
    while (formArray.length !== 0) {
      formArray.removeAt(0)
    }
  }
}



export const proofRequiredValidator: ValidatorFn = (control: FormGroup): ValidationErrors | null => {
  const digital_proof = control.get('digital_proof');
  const non_digital_proof = control.get('non_digital_proof');

  if ( digital_proof && non_digital_proof && digital_proof.value === null && non_digital_proof.value === null ) {
    return { 'proofRequired': true }
  }

  return null
};



export function proofNotNullValidator(control: AbstractControl): { [key: string]: boolean } | null {
    if ( control.value !== null ) {
        return { 'proofNotNull': true };
    }
    return null;
}