import { Component, OnInit, Input, Output, EventEmitter } from '@angular/core';
import { UntypedFormArray, UntypedFormGroup, Validators } from '@angular/forms';
import { BehaviorSubject } from 'rxjs';
import { MatDialog } from '@angular/material/dialog';

import { ConfirmationDialog } from '@geonature_common/others/modal-confirmation/confirmation.dialog';
import { ActorFormService } from '../services/actor-form.service';
import { ConfigService } from '@geonature/services/config.service';

@Component({
  selector: 'pnx-metadata-actor',
  templateUrl: 'actors.component.html',
  styleUrls: ['./actors.component.scss'],
})
export class ActorComponent implements OnInit {
  //formulaire acteur demandé par le componenent dataset-form.component ou af-form.component
  @Input() actorForm: UntypedFormGroup;
  @Input() isRemovable: boolean = true;
  @Output() actorFormSubmit = new EventEmitter<boolean>();
  @Output() actorFormRemove = new EventEmitter<boolean>();
  @Input() metadataType: 'dataset' | 'af' = null;
  @Input() defaultTab: 'organism' | 'person' | 'all';

  // pour mettre en cache la liste des nomenclature role_acteur
  _roleTypes;

  //liste des organismes pour peupler le select HTML
  get organisms() {
    return this.actorFormS.organisms;
  }

  //liste des roles pour peupler le select HTML
  get roles() {
    return this.actorFormS.roles;
  }

  //liste des types de role pour peupler le select HTML
  get role_types() {
    if (!this._roleTypes) {
      this._roleTypes = this.actorFormS.role_types.filter((e) => {
        if (e.cd_nomenclature == 1) {
          return false;
        } else {
          if (
            this.metadataType == 'dataset' &&
            this.config.METADATA.CD_NOMENCLATURE_ROLE_TYPE_DS.length > 0
          ) {
            return this.config.METADATA.CD_NOMENCLATURE_ROLE_TYPE_DS.includes(e.cd_nomenclature);
          }
          if (
            this.metadataType == 'af' &&
            this.config.METADATA.CD_NOMENCLATURE_ROLE_TYPE_AF.length > 0
          ) {
            return this.config.METADATA.CD_NOMENCLATURE_ROLE_TYPE_AF.includes(e.cd_nomenclature);
          }
        }
        return true;
      });
    }
    return this._roleTypes;
  }

  //Retourne l'objet organisme à partir de son identifiant issu du formulaire (pour affiche son label en mode edition = false)
  get organismValue() {
    return this.organisms.find(
      (organism: any) => organism.id_organisme == this.actorForm.get('id_organism').value
    );
  }

  //Retourne l'objet role à partir de son identifiant issu du formulaire (pour affiche son label en mode edition = false)
  get roleValue() {
    return this.roles.find((role: any) => role.id_role == this.actorForm.get('id_role').value);
  }

  //indique si c'est une formulaire d'édition ou de creation
  isEdition: boolean = false;

  //switch entre affichage du formulaire ou des labels
  toggleForm: boolean = false;

  //Pour switcher l'affichage du formulaire avec la liste organisme seule, role seul ou les deux.
  _toggleButtonValue: BehaviorSubject<string> = new BehaviorSubject('organism');
  public get toggleButtonValue() {
    return this._toggleButtonValue.getValue();
  }

  @Input() parentFormArray: UntypedFormArray;

  constructor(
    public dialog: MatDialog,
    private actorFormS: ActorFormService,
    public config: ConfigService
  ) { }

  ngOnInit() {
    if (!this.actorForm.get('id_organism').value && !this.actorForm.get('id_role').value) {
      this.toggleForm = true;

      if (this.actorForm.get('id_nomenclature_actor_role').value !== null) {
        this.isEdition = true;
      }
    }

    this.setToggleButtonValue();
  }

  toggleActorOrganismChoiceChange(event) {
    /**
     *  suprime id_organism si on choisi acteur seulement
     *  suprime id_role si on choisi organism seulement
     **/

    const btn = event.value;
    this._toggleButtonValue.next(btn);

    if (btn == 'person') {
      this.actorForm.controls.id_role.setValidators([Validators.required]);
      this.actorForm.controls.id_organism.setValidators([]);
      this.actorForm.patchValue({ id_organism: null });
    }

    if (btn == 'organism') {
      this.actorForm.controls.id_organism.setValidators([Validators.required]);
      this.actorForm.controls.id_role.setValidators([]);
      this.actorForm.patchValue({ id_role: null });
    }

    if (btn == 'all') {
      this.actorForm.controls.id_organism.setValidators([Validators.required]);
      this.actorForm.controls.id_role.setValidators([Validators.required]);
      this.actorForm.patchValue({});
    }
  }

  setToggleButtonValue() {
    var btn =
      this.actorForm.get('id_organism').value && this.actorForm.get('id_role').value
        ? 'all'
        : this.actorForm.get('id_role').value
          ? 'person'
          : 'organism';

    this.toggleActorOrganismChoiceChange({ value: btn });
  }

  submitActor() {
    this.actorFormSubmit.emit(this.actorForm.valid);
  }

  remove() {
    const message = `Êtes-vous certain de supprimer cet acteur ?`;
    const dialogRef = this.dialog.open(ConfirmationDialog, {
      width: '350px',
      position: { top: '5%' },
      data: { message: message },
    });

    dialogRef.afterClosed().subscribe((result) => {
      if (result) {
        this.actorFormRemove.emit(true);
      }
    });
  }

  get isMainContact(): boolean {
    //si le cdNomenclature == "1" => code de la ligne contact principal
    return (
      this.actorFormS.getCdNomenclatureByIDRoleType(
        this.actorForm.get('id_nomenclature_actor_role').value
      ) == '1'
    );
  }
}
