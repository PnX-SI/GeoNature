import { Injectable } from '@angular/core';
import { FormGroup, FormControl, FormArray, FormBuilder, Validators, ValidatorFn, AbstractControl } from '@angular/forms';
import { BehaviorSubject } from 'rxjs';
import { map } from 'rxjs/operators';
 
import { DataFormService } from '@geonature_common/form/data-form.service';
import { AppConfig } from '../../../conf/app.config';
 
// export const ID_ROLE_DATASET_ACTORS = ["5", "6", "7"]; //['Contact principal', 'Fournisseur du jeu de données', 'Producteur du jeu de données']
// export const ID_ROLE_AF_ACTORS = ["2", "3", "4"]; //['Contact principal', 'Fournisseur du jeu de données', 'Producteur du jeu de données']
 
@Injectable()
export class ActorFormService {
 
  _organisms: BehaviorSubject<any[]> = new BehaviorSubject([]);
  get organisms() { return this._organisms.getValue(); }
 
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
    private fb: FormBuilder,
    private dfs: DataFormService
  ) {
    this.dfs.getOrganisms()
      .subscribe((organisms: any[]) => this._organisms.next(organisms));
 
    this.dfs.getRoles({ group: false })
      .subscribe((roles: any[]) => this._roles.next(roles));
 
    this.dfs.getNomenclature("ROLE_ACTEUR", null, null, { orderby: 'label_default' })
      .pipe(
        map((res: any) => res.values)
      )
      .subscribe((role_types: any[]) => this._role_types.next(role_types));
  }
 
  createForm(): FormGroup {
    //FORM
    const form = this.fb.group({
      id_nomenclature_actor_role: [null, Validators.required],
      id_organism: null,
      id_role: null,
      id_cda: null, /* pour mise à jours des dataset actors */
      id_cafa: null /* pour mise à jours des afs actors */
    });
    form.setValidators([this.actorRequired]);
 
    return form;
  }
 
  actorRequired(actorForm: AbstractControl): { [key: string]: boolean } {
    const organism = actorForm.get("id_organism").value;
    const role = actorForm.get("id_role").value;
     
    return (organism === null && role === null) ? { actorRequired: true } : null;
  }
}