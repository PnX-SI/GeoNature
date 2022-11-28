import { Injectable } from '@angular/core';
import { FormGroup, FormArray, FormBuilder, Validators } from '@angular/forms';
import { BehaviorSubject, Observable } from 'rxjs';
import { tap, filter, switchMap, map } from 'rxjs/operators';

import { ActorFormService } from './actor-form.service';
import { FormService } from '@geonature_common/form/form.service';

@Injectable()
export class AcquisitionFrameworkFormService {
  public form: FormGroup;
  public acquisition_framework: BehaviorSubject<any> = new BehaviorSubject(null);

  constructor(
    private fb: FormBuilder,
    private actorFormS: ActorFormService,
    private formS: FormService
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
          is_parent: false,
          cor_objectifs: [],
          cor_volets_sinp: [],
          cor_territories: [],
          cor_af_actor: [{ id_nomenclature_actor_role: id_nomenclature }],
        };
      })
    );
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
      cor_af_actor: this.fb.array(
        [],
        [
          this.actorFormS.mainContactRequired.bind(this.actorFormS),
          this.actorFormS.uniqueMainContactvalidator.bind(this.actorFormS),
          this.actorFormS.checkDoublonsValidator.bind(this.actorFormS),
        ]
      ),
      bibliographical_references: this.fb.array([]),
    });

    this.form.setValidators([
      this.formS.dateValidator(
        this.form.get('acquisition_framework_start_date'),
        this.form.get('acquisition_framework_end_date')
      ),
    ]);
  }

  /**
   * Initialise les observables pour la mise en place des actions automatiques
   **/
  private setObservables() {
    //Observable de this.dataset pour adapter le formulaire selon la donnée
    this.acquisition_framework
      .asObservable()
      .pipe(
        tap(() => this.reset()),
        switchMap((af) =>
          af !== null ? this.acquisition_framework.asObservable() : this.initialValues
        ),
        map((value) => {
          if (value.cor_af_actor) {
            if (this.actorFormS.nbMainContact(value.cor_af_actor) == 0) {
              console.log(value.cor_af_actor);
              value.cor_af_actor.push({
                id_nomenclature_actor_role: this.actorFormS.getIDRoleTypeByCdNomenclature('1'),
              });
            }
            value.cor_af_actor.forEach((actor) => {
              this.addActor(this.actors, actor);
            });
          }
          if (value.bibliographical_references) {
            value.bibliographical_references.forEach((e) => {
              this.addBibliographicalReferences();
            });
          }
          return value;
        })
      )
      .subscribe((value: any) => this.form.patchValue(value));

    //gère lactivation/désactivation de la zone de saisie du framework Parent
    this.form.get('is_parent').valueChanges.subscribe((value: boolean) => {
      if (value) {
        this.form.get('acquisition_framework_parent_id').disable();
      } else {
        this.form.get('acquisition_framework_parent_id').enable();
      }
    });
  }

  get actors(): FormArray {
    return this.form.get('cor_af_actor') as FormArray;
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
    formArray.removeAt(i);
  }

  get bibliographicalReferences(): FormArray {
    return this.form.get('bibliographical_references') as FormArray;
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
    this.bibliographicalReferences.removeAt(i);
  }

  //retourne true sur l'acteur est contact principal
  isMainContact(actorForm) {
    return (
      actorForm.get('id_nomenclature_actor_role').value ==
      this.actorFormS.getIDRoleTypeByCdNomenclature('1')
    );
  }

  reset() {
    this.clearFormArray(this.form.get('cor_af_actor') as FormArray);
    this.form.reset();
  }

  private clearFormArray(formArray: FormArray) {
    while (formArray.length !== 0) {
      formArray.removeAt(0);
    }
  }
}
