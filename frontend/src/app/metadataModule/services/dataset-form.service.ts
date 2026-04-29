import { Injectable } from '@angular/core';
import { UntypedFormGroup, UntypedFormArray, UntypedFormBuilder, Validators } from '@angular/forms';
import { ToastrService } from 'ngx-toastr';
import { BehaviorSubject, forkJoin, Observable, of } from 'rxjs';
import { tap, filter, switchMap, map } from 'rxjs/operators';

import { ActorFormService } from './actor-form.service';
import { FormService } from '@geonature_common/form/form.service';
import { ConfigService } from '@geonature/services/config.service';
import { ActivatedRoute } from '@librairies/@angular/router';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { ModuleService } from '@geonature/services/module.service';

@Injectable()
export class DatasetFormService {
  public form: UntypedFormGroup;
  public genericActorForm: UntypedFormArray;

  public dataset: BehaviorSubject<any> = new BehaviorSubject(null);
  public otherActorGroupForms: BehaviorSubject<any> = new BehaviorSubject({});

  // Custom additional fields
  public additionalFieldsForm: Array<any> = [];

  constructor(
    private fb: UntypedFormBuilder,
    private _toaster: ToastrService,
    private actorFormS: ActorFormService,
    private formS: FormService,
    private _config: ConfigService,
    private _route: ActivatedRoute,
    private dataFormService: DataFormService,
    public moduleService: ModuleService
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
          additional_data: {},
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
      id_nomenclature_collecting_method: [null, Validators.required],
      id_nomenclature_data_origin: [null, Validators.required],
      id_nomenclature_source_status: [null, Validators.required],
      id_nomenclature_resource_type: [null, Validators.required],
      validable: null,
      active: [null, Validators.required],
      id_taxa_list: null,
      modules: [[]],
      cor_objectifs: [[], Validators.required],
      cor_territories: [[], Validators.required],
      cor_dataset_actor: this.fb.array(
        [],
        [
          this.actorFormS.mainContactRequired.bind(this.actorFormS),
          this.actorFormS.checkDoublonsValidator.bind(this.actorFormS),
        ]
      ),
      unique_dataset_id: [null, [this.formS.uuidValidator()]],
      additional_data: this.fb.group({}),
    });
    this.genericActorForm = this.fb.array(
      [],
      [this.actorFormS.checkDoublonsValidator.bind(this.actorFormS)]
    );
  }

  getAdditionalFields(object_code: Array<string>): Observable<any> {
    return this.dataFormService
      .getadditionalFields({
        module_code: [this.moduleService.currentModule.module_code],
        object_code: object_code,
      })
      .catch((error) => {
        console.error('Error while getting additional fields', error);
        return of([]);
      });
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
        tap(() => {
          this.additionalFieldsForm = [];
        }),
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
          // Pre-fill associated modules from config
          //  but only for the creation a new DS and not for the update of an existing one
          this._route.params.subscribe((params) => {
            const isCreateAndNotUpdate = !params.hasOwnProperty('id');
            if (isCreateAndNotUpdate) {
              value.modules = this.moduleService.modules.filter((module) => {
                return this._config.METADATA.DATASETS_DEFAULT_ASSOCIATED_MODULES.includes(
                  module.module_code
                );
              });
            }
          });
          return value;
        }),
        // Get additional fields from datasets
        switchMap((dataset) => {
          let additionnalFieldsObservable: Observable<any>;
          additionnalFieldsObservable = this.getAdditionalFields(['METADATA_JEU_DE_DONNEES']);
          return forkJoin([of(dataset), additionnalFieldsObservable]);
        }),
        map(([dataset, additional_data]) => {
          additional_data.forEach((field) => {
            // Set value of field
            if (
              dataset.additional_data &&
              dataset.additional_data[field.attribut_name] !== undefined
            ) {
              field.value = dataset.additional_data[field.attribut_name];
            }
          });

          return [dataset, additional_data];
        }),
        // Set the additional fields form
        tap(([dataset, additional_data]) => {
          this.additionalFieldsForm = additional_data;
        }),
        // Map to return acquisition framework data only
        map(([dataset, additional_data]) => dataset)
      )
      .subscribe((value: any) => this.form.patchValue(value));

    //gère la separation des acteurs selon le type de role de chacun d'eux
    this.actors.valueChanges.subscribe((form) => this.setOtherActorGroupForms());
  }

  get actors(): UntypedFormArray {
    return this.form.get('cor_dataset_actor') as UntypedFormArray;
  }

  //ajoute un acteur au formulaire, par défaut un acteur vide est ajouté
  addActor(value: any = null): void {
    const actorForm = this.actorFormS.createForm();
    if (value) {
      actorForm.patchValue(value);
    }
    this.actors.push(actorForm);
  }

  removeActor(formArray: UntypedFormArray, i: number): void {
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
    this.clearFormArray(this.form.get('cor_dataset_actor') as UntypedFormArray);
    this.form.reset();
  }

  private clearFormArray(formArray: UntypedFormArray) {
    while (formArray.length !== 0) {
      formArray.removeAt(0);
    }
  }
}
