import { Injectable } from "@angular/core";
import { FormBuilder, FormGroup, Validators, FormArray } from "@angular/forms";
import { BehaviorSubject, Observable } from 'rxjs';
import { map, filter, switchMap, tap } from 'rxjs/operators';

import { OcctaxFormService } from '../occtax-form.service';
import { OcctaxFormCountingService } from '../counting/counting.service';
// import { AppConfig } from "@geonature_config/app.config";
// import { HttpClient, HttpParams } from "@angular/common/http";
// import { Router } from "@angular/router";
// import { ModuleConfig } from "../../module.config";
// import { AuthService, User } from "@geonature/components/auth/auth.service";
import { FormService } from "@geonature_common/form/form.service";
// import { Taxon } from "@geonature_common/form/taxonomy/taxonomy.component";
// import { CommonService } from "@geonature_common/service/common.service";

@Injectable()
export class OcctaxFormOccurrenceService {

  public form: FormGroup;
  public taxref: BehaviorSubject<any> = new BehaviorSubject(null);
  public occurrence: BehaviorSubject<any> = new BehaviorSubject(null)

  constructor(
    // private _http: HttpClient,
    // private _router: Router,
    // private _auth: AuthService,
    // private _commonService: CommonService
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
      cor_counting_occtax: new FormArray([])
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
        switchMap(occurrence => {
          //Le switch permet, selon si édition ou creation, de récuperer les valeur par defaut ou celle de l'API
          return /*this.occurrence ? this.occurrence :*/ this.defaultValues;
        })
      ).subscribe(values=>this.form.patchValue(values))

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
                      map(data=> {
                        return {
                          id_nomenclature_bio_condition: data["ETA_BIO"],
                          id_nomenclature_naturalness: data["NATURALITE"],
                          id_nomenclature_obs_meth: data["METH_OBS"],
                          id_nomenclature_bio_status: data["STATUT_BIO"],
                          id_nomenclature_exist_proof: data["PREUVE_EXIST"],
                          id_nomenclature_determination_method: data["METH_DETERMIN"],
                          id_nomenclature_observation_status: data["STATUT_OBS"],
                          id_nomenclature_diffusion_level: data["NIV_PRECIS"],
                          id_nomenclature_blurring: data["DEE_FLOU"],
                          id_nomenclature_source_status: data["STATUT_SOURCE"],
//                          cor_counting_occtax: new FormArray(this.occtaxFormCountingService.getForm())
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


  

}
