import { Injectable } from "@angular/core";
import { FormBuilder, FormGroup, Validators, FormArray } from "@angular/forms";
import { BehaviorSubject, Observable } from 'rxjs';
import { map, filter, switchMap, tap } from 'rxjs/operators';
import { OcctaxFormService } from '../occtax-form.service';
import { OcctaxFormCountingService } from '../counting/counting.service';
import { FormService } from "@geonature_common/form/form.service";

@Injectable()
export class OcctaxFormOccurrenceService {

  public form: FormGroup;
  public taxref: BehaviorSubject<any> = new BehaviorSubject(null);
  public occurrence: BehaviorSubject<any> = new BehaviorSubject(null)

  constructor(
    private fb: FormBuilder,
    private coreFormService: FormService,
    private occtaxFormService: OcctaxFormService,
    private occtaxFormCountingService: OcctaxFormCountingService,
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
      cd_nom: [null, this.coreFormService.taxonValidator],
      meta_v_taxref: null,
      sample_number_proof: null,
      digital_proof: null,
      non_digital_proof: null,
      comment: null,
      cor_counting_occtax: this.fb.array([], Validators.required)
    });

    this.form.patchValue(this.initialValues);

    // this.form.get('cd_nom').setValidators([
    //   this.coreFormService.taxonValidator,
    //   Validators.required
    // ]);

    //occForm.controls.non_digital_proof.setValidators([this.proofValidator.bind(this)]);
    //this.form.setValidators([this.proofValidator.bind(this)]);

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
          this.clearFormArray(this.form.get('cor_counting_occtax'));
        }),
        switchMap(occurrence => {
          //on oriente la source des données pour patcher le formulaire
          return occurrence ? this.occurrence : this.defaultValues;
        }),
        tap(occurrence=>{
          //mise en place des countingForm
          if (occurrence.cor_counting_occtax) {
            occurrence.cor_counting_occtax.forEach((c, i)=>{
              (this.form.get('cor_counting_occtax') as FormArray).push(this.occtaxFormCountingService.createForm());
            })
          }
        })
      ).subscribe(values=>{console.log(values);this.form.patchValue(values)});

    //attribut le cd_nom au formulaire si un taxon est selectionné
    this.taxref
          .pipe(map(taxref=>{return taxref ? taxref.cd_nom : null}))
          .subscribe(cd_nom=>this.form.get('cd_nom').setValue(cd_nom));

    // this.taxref
    //       .pipe(
    //         filter(taxref=>taxref !== null),
    //         switchMap({
    //                       return this.getDefaultValues(
    //                             //   this.currentUser.id_organisme,
    //                             //   $event.item.regne,
    //                             //   $event.item.group2_inpn
    //                             })

    //       )
    //       .subscribe(data=>{
    //         // this.patchDefaultNomenclatureOccurrence(data);
    //         // // counting
    //         // this.countingForm.controls.forEach(formgroup => {
    //         //   this.patchDefaultNomenclatureCounting(formgroup as FormGroup, data);
    //         // });
    //       });

    this.form.get('nom_cite')
                  .valueChanges
                  .pipe(
                    filter(val=>val.cd_nom === undefined)
                  )
                  .subscribe(()=>this.taxref.next(null));
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

  getCurrentCD(labels, currentID) {
    //currentCD = null;
    let i = 0;
    while (i < labels.length) {
      if (labels[i].id_nomenclature == currentID) {
        return labels[i].cd_nomenclature;
      }
      i++;
    }
    return null;
  }

  // proofValidator(occControl: FormGroup) {
  //   if (
  //     occControl.controls.id_nomenclature_exist_proof !== null &&
  //     this.currentExistProofLabels !== null
  //   ) {
  //     // on recupere le CD a partir de l'id
  //     const currentCD = this.getCurrentCD(
  //       this.currentExistProofLabels,
  //       occControl.controls.id_nomenclature_exist_proof.value
  //     );
  //     // si le type validation est = OUI et que les deux champs validation
  //     // sont pas remplis  (null ou legnth == 0)=> erreur
  //     // prettier-ignore
  //     if (
  //       currentCD === "1" &&
  //       (
  //         ( 
  //           occControl.controls.digital_proof.value === null
  //           ||
  //           (
  //             occControl.controls.digital_proof.value !== null &&
  //             occControl.controls.digital_proof.value.length === 0
  //           )
  //         )// false
  //       &&
  //         (
  //           occControl.controls.non_digital_proof.value === null 
  //           ||
  //             (
  //               occControl.controls.non_digital_proof.value !== null &&
  //               occControl.controls.non_digital_proof.value.length === 0
  //             )
  //         )// true
  //       )
  //     ) {

  //       return { noExistProofError: true };
  //     }
  //     // si les deux preuve sont pas NULL
  //     if (
  //       (occControl.controls.digital_proof.value !== null &&
  //         occControl.controls.digital_proof.value.length > 0) ||
  //       (occControl.controls.non_digital_proof.value !== null &&
  //         occControl.controls.non_digital_proof.value.length > 0)
  //     ) {
  //       // si preuve est different de oui on leve une erreur
  //       if (currentCD !== "1") {
  //         return { existproofError: true };
  //       }
  //       // si preuve = oui et que le validateur de la conf est activé et que preuve numerique est différent de http ...
  //       else if (
  //         occControl.controls.digital_proof.value !== null &&
  //         occControl.controls.digital_proof.value.length > 0 &&
  //         ModuleConfig.digital_proof_validator
  //       ) {
  //         let REGEX = new RegExp("^(http://|https://|ftp://){1}.+$");
  //         return REGEX.test(occControl.controls.digital_proof.value)
  //           ? null
  //           : {
  //               invalidDigitalProof: true
  //             };
  //       }
  //     }
  //   }
  // }

  reset() {
    this.form.reset(this.initialValues);
  }

  private clearFormArray(formArray: FormArray) {
    while (formArray.length !== 0) {
      formArray.removeAt(0)
    }
  }
  

}
