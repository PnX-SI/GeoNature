import { Injectable } from '@angular/core';
import {
  UntypedFormGroup,
  UntypedFormArray,
  UntypedFormBuilder,
  Validators,
  AbstractControl,
} from '@angular/forms';
import { BehaviorSubject } from 'rxjs';
import { map } from 'rxjs/operators';

import { DataFormService } from '@geonature_common/form/data-form.service';

// export const ID_ROLE_DATASET_ACTORS = ["5", "6", "7"]; //['Contact principal', 'Fournisseur du jeu de données', 'Producteur du jeu de données']
// export const ID_ROLE_AF_ACTORS = ["2", "3", "4"]; //['Contact principal', 'Fournisseur du jeu de données', 'Producteur du jeu de données']

@Injectable()
export class ActorFormService {
  _organisms: BehaviorSubject<any[]> = new BehaviorSubject([]);
  get organisms() {
    return this._organisms.getValue();
  }

  _roles: BehaviorSubject<any[]> = new BehaviorSubject([]);
  get roles() {
    return this._roles.getValue();
  }

  _role_types: BehaviorSubject<any[]> = new BehaviorSubject([]);
  get role_types() {
    return this._role_types.getValue();
  }

  getIDRoleTypeByCdNomenclature(code) {
    const role_type = this._role_types.getValue().find((e) => e.cd_nomenclature == code);
    return role_type ? role_type.id_nomenclature : null;
  }

  getCdNomenclatureByIDRoleType(id) {
    const role_type = this._role_types.getValue().find((e) => e.id_nomenclature == id);
    return role_type ? role_type.cd_nomenclature : null;
  }

  getRoleTypeByID(id) {
    return this._role_types.getValue().find((e) => e.id_nomenclature == id);
  }

  constructor(
    private fb: UntypedFormBuilder,
    private dfs: DataFormService
  ) {
    this.dfs.getOrganisms().subscribe((organisms: any[]) => this._organisms.next(organisms));

    this.dfs.getRoles({ group: false }).subscribe((roles: any[]) => this._roles.next(roles));

    this.dfs
      .getNomenclature('ROLE_ACTEUR', null, null, null, { orderby: 'label_default' })
      .pipe(map((res: any) => res.values))
      .subscribe((role_types: any[]) => this._role_types.next(role_types));
  }

  createForm(): UntypedFormGroup {
    //FORM
    const form = this.fb.group({
      id_nomenclature_actor_role: [null, Validators.required],
      id_organism: null,
      id_role: null,
      id_cda: null /* pour mise à jours des dataset actors */,
      id_cafa: null /* pour mise à jours des afs actors */,
    });
    form.setValidators([this.actorRequired]);

    return form;
  }

  actorRequired(actorForm: AbstractControl): { [key: string]: boolean } {
    const organism = actorForm.get('id_organism').value;
    const role = actorForm.get('id_role').value;

    return organism === null && role === null ? { actorRequired: true } : null;
  }

  /**
   * fonctions et Validateurs pour les listes d'acteurs
   * utilisé par les JDD et les CA
   */

  nbMainContact(actors: Array<any>) {
    let mainContactNb = 0;

    for (let i = 0; i < actors.length; i++) {
      if (
        // le test est seulement sur la nomenclature
        actors[i]['id_nomenclature_actor_role'] === this.getIDRoleTypeByCdNomenclature('1')
      ) {
        mainContactNb = mainContactNb + 1;
      }
    }
    return mainContactNb;
  }

  /**
   * Validateur pour s'assurer d'avoir au moins un contact principal (JDD et CA)
   */
  mainContactRequired(actors: UntypedFormArray): { [key: string]: boolean } {
    return this.nbMainContact(actors.value) == 0 ? { mainContactRequired: true } : null;
  }

  /**
   * Validateur pour s'assurer d'avoir au plus un contact principla (CA)
   */
  uniqueMainContactvalidator(actors: UntypedFormArray): { [key: string]: boolean } {
    return this.nbMainContact(actors.value) > 1 ? { uniqueMainContactvalidator: true } : null;
  }

  /**
   * Validateur pour empêcher d'avoir deux acteur identiques (test sur role, organisme, nomenclature)
   * retourne l'index du doublons le plus bas dans la liste
   */
  checkDoublonsValidator(actors: UntypedFormArray): { [key: string]: any } {
    // pour tous les acteurs
    for (let i = 0; i < actors.value.length - 1; i = i + 1) {
      // test sur les suivants de i
      for (let j = i + 1; j < actors.value.length; j = j + 1) {
        if (
          actors.value[i].id_role == actors.value[j].id_role &&
          actors.value[i].id_organism == actors.value[j].id_organism &&
          actors.value[i].id_nomenclature_actor_role == actors.value[j].id_nomenclature_actor_role
        ) {
          // en cas de doublons on renvoie l'index j
          return { hasDoublons: { index: j } };
        }
      }
    }
    return null;
  }
}
