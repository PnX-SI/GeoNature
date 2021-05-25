import { Injectable } from '@angular/core';
import { FormGroup, FormArray, FormBuilder, Validators } from '@angular/forms';
import { BehaviorSubject, Observable  } from 'rxjs';
import { tap, filter, switchMap, map } from 'rxjs/operators';
 
import { ActorFormService, ID_ROLE_AF_ACTORS } from './actor-form.service';
import { FormService } from '@geonature_common/form/form.service';
 
@Injectable()
export class AcquisitionFrameworkFormService {
 
  public form: FormGroup;
  public acquisition_framework: BehaviorSubject<any> = new BehaviorSubject(null);
  public genericActorsForm: FormArray; 
 
  constructor(
    private fb: FormBuilder, 
    private actorFormS: ActorFormService,
    private formS: FormService
  ) {
    this.initForm();
    this.setObservables();
  }
 
 
  private get initialValues(): Observable<any> {
    return this.actorFormS._role_types.asObservable()
      .pipe(
        map((role_types: any[]): number => {
          //recherche du role "Contact principal" (cd_nomenclature = "1") pour l'attribuer par defaut.
          const role_type = role_types.find((role_type) => role_type.cd_nomenclature == "1");
          return role_type ? role_type.id_nomenclature : null;
        }),
        filter((id_nomenclature: number) => id_nomenclature !== null),
        map((id_nomenclature: number): any => {
          //formate les donnés par défauts envoyées au formulaire
          return {
            is_parent: false,
            cor_objectifs: [],
            cor_volets_sinp: [],
            cor_territories: [],
            cor_af_actor: [{id_nomenclature_actor_role: id_nomenclature}]
          }
        })
      )
  }
 
  initForm(): void {
    //FORM
    this.form = this.fb.group({
      acquisition_framework_name: [null, Validators.required],
      acquisition_framework_desc: [null, Validators.required],
      id_nomenclature_territorial_level: [null, Validators.required],
      territory_desc: null,
      keywords: null,
      id_nomenclature_financing_type: [null, Validators.required],
      target_description: null,
      ecologic_or_geologic_target: null,
      acquisition_framework_parent_id: null,
      is_parent: null,
      acquisition_framework_start_date: [null, Validators.required],
      acquisition_framework_end_date: null,
      cor_objectifs: [[], Validators.required],
      cor_volets_sinp: [[]],
      cor_territories: [[], Validators.required],
      cor_af_actor: this.fb.array([],[
        this.mainContactRequired.bind(this), 
        this.uniqueMainContactvalidator.bind(this),
      ]),
      bibliographical_references: this.fb.array([]),
    });
    this.genericActorsForm = this.fb.array([]);
 
    this.form.setValidators([
      this.formS.dateValidator(
        this.form.get('acquisition_framework_start_date'),
        this.form.get('acquisition_framework_end_date')
      )
    ]);
  }
 
  /**
   * Initialise les observables pour la mise en place des actions automatiques
   **/
  private setObservables() {
 
    //Observable de this.dataset pour adapter le formulaire selon la donnée
    this.acquisition_framework.asObservable()
      .pipe(
        tap(() => this.reset()),
        switchMap((af) => af !== null ? this.acquisition_framework.asObservable() : this.initialValues),
        tap((value) => {
          if (value.cor_af_actor) {
            value.cor_af_actor.forEach(e => {
              this.addActor(this.actors);
            });
          }
          if (value.bibliographical_references) {
            value.bibliographical_references.forEach(e => {
              this.addBibliographicalReferences();
            });
          }
        })
      )
      .subscribe((value: any) => this.form.patchValue(value, {emitEvent: false, onlySelf: true}));
 
    //gère lactivation/désactivation de la zone de saisie du framework Parent
    this.form.get('is_parent').valueChanges
      .subscribe((value: boolean) => {
        if (value) {
          this.form.get('acquisition_framework_parent_id').enable();
        } else {
          this.form.get('acquisition_framework_parent_id').disable();
        }
      });
 
    //gère la separation des acteurs selon le type de role de chacun d'eux
    this.actors.valueChanges
      .subscribe(form => this.setOtherActorGroupForms());
  }
 
  get actors(): FormArray {
    return this.form.get("cor_af_actor") as FormArray;
  }
 
  //ajoute un acteur au formulaire, par défaut un acteur vide est ajouté
  addActor(formArray, value: any = null): void {
    const actorForm = this.actorFormS.createForm();
    if (value) {
      actorForm.patchValue(value);
    }
    formArray.push(actorForm);
  }
 
  removeActor(formArray: FormArray, i: number): void {
    formArray.removeAt(i);;
  }
 
  get bibliographicalReferences(): FormArray {
    return this.form.get("bibliographical_references") as FormArray;
  }
 
  //ajoute un acteur au formulaire, par défaut un acteur vide est ajouté
  addBibliographicalReferences(): void {
    const biblioRefForm = this.fb.group({
      id_bibliographic_reference: null,
      publication_url: null,
      publication_reference: [null, Validators.required],
    });
    this.bibliographicalReferences.push(biblioRefForm);
  }
 
  removeBibliographicalReferences(i: number): void {
    this.bibliographicalReferences.removeAt(i);;
  }
 
  //retourne true sur l'acteur est contact principal
  isMainContact(actorForm) {
    return actorForm.get('id_nomenclature_actor_role').value == this.actorFormS.getIDRoleTypeByCdNomenclature("1")
  }
 
  setOtherActorGroupForms(): void {
    for (let i = 0; i < this.actors.controls.length; i++) {
      const actorControl = this.actors.controls[i]
      const role_type = this.actorFormS.getRoleTypeByID(actorControl.get('id_nomenclature_actor_role').value);
 
      if (role_type !== undefined && !this.isMainContact(actorControl)) {
        this.actors.removeAt(i);
        this.genericActorsForm.push(actorControl);
      }
    }
  }
 
  reset() {
    this.clearFormArray(this.form.get("cor_af_actor") as FormArray);
    this.form.reset();
  }
 
  private clearFormArray(formArray: FormArray) {
    while (formArray.length !== 0) {
      formArray.removeAt(0)
    }
  }
 
  private mainContactRequired(actors: FormArray): { [key: string]: boolean } {
    let mainContactNb = 0;
 
    for (let i = 0; i < actors.controls.length; i++) {
      if (actors.controls[i].get('id_nomenclature_actor_role').value === this.actorFormS.getIDRoleTypeByCdNomenclature("1")) {
        mainContactNb = mainContactNb + 1;
      }
    }
 
    return mainContactNb == 0 ? { mainContactRequired: true } : null;
  };
 
  private uniqueMainContactvalidator(actors: FormArray): { [key: string]: boolean } {
    let mainContactNb = 0;
 
    for (let i = 0; i < actors.controls.length; i++) {
      if (actors.controls[i].get('id_nomenclature_actor_role').value === this.actorFormS.getIDRoleTypeByCdNomenclature("1")) {
        mainContactNb = mainContactNb + 1;
      }
    }
 
    return mainContactNb > 1 ? { uniqueMainContactvalidator: true } : null;
  };
 
}