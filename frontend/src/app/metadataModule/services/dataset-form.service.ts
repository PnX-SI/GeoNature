import { Injectable } from '@angular/core';
import { FormGroup, FormArray, FormBuilder, Validators } from '@angular/forms';
import { ToastrService } from 'ngx-toastr';
import { BehaviorSubject, Observable } from 'rxjs';
import { tap, filter, switchMap, map } from 'rxjs/operators';

import { ActorFormService } from './actor-form.service';

@Injectable()
export class DatasetFormService {
  public form: FormGroup;
  public genericActorForm: FormArray;

  public dataset: BehaviorSubject<any> = new BehaviorSubject(null);
  public otherActorGroupForms: BehaviorSubject<any> = new BehaviorSubject({});

  constructor(
    private fb: FormBuilder,
    private _toaster: ToastrService,
    private actorFormS: ActorFormService
  ) {
    this.initForm();
    this.setObservables();
  }

  private get initialValues(): Observable<any> {
    return this.actorFormS._role_types.asObservable().pipe(
      map((role_types: any[]): number => {
        //recherche du role "Contact principal" (cd_nomenclature = "1") pour l'attribuer par defaut.
        const role_type = role_types.find((role_type) => role_type.cd_nomenclature == '1');
        return role_type ? role_type.id_nomenclature : null;
      }),
      filter((id_nomenclature: number) => id_nomenclature !== null),
      map((id_nomenclature: number): any => {
        //formate les donnés par défauts envoyées au formulaire
        return {
          terrestrial_domain: true,
          marine_domain: false,
          validable: true,
          active: true,
          modules: [],
          cor_territories: [],
          cor_dataset_actor: [{ id_nomenclature_actor_role: id_nomenclature }],
        };
      })
    );
  }

  initForm(): void {
    //FORM
    this.form = this.fb.group({
      id_acquisition_framework: [null, Validators.required],
      dataset_name: [null, [Validators.required, Validators.maxLength(150)]],
      dataset_shortname: [null, [Validators.required, Validators.maxLength(30)]],
      dataset_desc: [null, Validators.required],
      id_nomenclature_data_type: [null, Validators.required],
      keywords: null,
      terrestrial_domain: null,
      marine_domain: null,
      id_nomenclature_dataset_objectif: [null, Validators.required],
      id_nomenclature_collecting_method: [null, Validators.required],
      id_nomenclature_data_origin: [null, Validators.required],
      id_nomenclature_source_status: [null, Validators.required],
      id_nomenclature_resource_type: [null, Validators.required],
      validable: null,
      active: [null, Validators.required],
      id_taxa_list: null,
      modules: [[]],
      cor_territories: [[], Validators.required],
      cor_dataset_actor: this.fb.array(
        [],
        [
          this.actorFormS.mainContactRequired.bind(this.actorFormS),
          this.actorFormS.checkDoublonsValidator.bind(this.actorFormS),
        ]
      ),
    });
    this.genericActorForm = this.fb.array(
      [],
      [this.actorFormS.checkDoublonsValidator.bind(this.actorFormS)]
    );
  }

  /**
   * Initialise les observables pour la mise en place des actions automatiques
   **/
  private setObservables() {
    //Observable de this.dataset pour adapter le formulaire selon la donnée
    this.dataset
      .asObservable()
      .pipe(
        tap(() => this.reset()),
        switchMap((dataset) =>
          dataset !== null ? this.dataset.asObservable() : this.initialValues
        ),
        map((value) => {
          if (!this.actorFormS.nbMainContact(value.cor_dataset_actor)) {
            value.cor_dataset_actor.push({
              id_nomenclature_actor_role: this.actorFormS.getIDRoleTypeByCdNomenclature('1'),
            });
          }
          value.cor_dataset_actor.forEach((actor) => {
            this.addActor(actor);
          });
          delete value.cor_dataset_actor;
          return value;
        })
      )
      .subscribe((value: any) => this.form.patchValue(value));

    //gère la separation des acteurs selon le type de role de chacun d'eux
    this.actors.valueChanges.subscribe((form) => this.setOtherActorGroupForms());
  }

  get actors(): FormArray {
    return this.form.get('cor_dataset_actor') as FormArray;
  }

  //ajoute un acteur au formulaire, par défaut un acteur vide est ajouté
  addActor(value: any = null): void {
    const actorForm = this.actorFormS.createForm();
    if (value) {
      actorForm.patchValue(value);
    }
    this.actors.push(actorForm);
  }

  removeActor(formArray: FormArray, i: number): void {
    formArray.removeAt(i);
  }

  //retourne true sur l'acteur est contact principal
  isMainContact(actorForm) {
    return (
      actorForm.get('id_nomenclature_actor_role').value ==
      this.actorFormS.getIDRoleTypeByCdNomenclature('1')
    );
  }

  setOtherActorGroupForms(): void {
    const groups = {};
    for (let i = 0; i < this.actors.controls.length; i++) {
      const actorControl = this.actors.controls[i];
      const role_type = this.actorFormS.getRoleTypeByID(
        actorControl.get('id_nomenclature_actor_role').value
      );
      if (role_type !== undefined && !this.isMainContact(actorControl)) {
        this.actors.removeAt(i);
        this.genericActorForm.push(actorControl);
      }
    }
  }

  reset() {
    this.clearFormArray(this.form.get('cor_dataset_actor') as FormArray);
    this.form.reset();
  }

  private clearFormArray(formArray: FormArray) {
    while (formArray.length !== 0) {
      formArray.removeAt(0);
    }
  }
}
