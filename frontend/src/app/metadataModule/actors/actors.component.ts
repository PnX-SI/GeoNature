import { Component, OnInit, Input, Output, EventEmitter } from '@angular/core';
import { FormArray, FormGroup } from '@angular/forms';
import { BehaviorSubject } from 'rxjs';
import { MatDialog } from "@angular/material";

import { ConfirmationDialog } from "@geonature_common/others/modal-confirmation/confirmation.dialog";
import { AppConfig } from '../../../conf/app.config';
import {ActorFormService} from '../services/actor-form.service'
@Component({
  selector: 'pnx-metadata-actor',
  templateUrl: 'actors.component.html',
  styleUrls: ['./actors.component.scss']
})
export class ActorComponent implements OnInit {

  //formulaire acteur demandé par le componenent dataset-form.component ou af-form.component
  @Input() actorForm: FormGroup;
  @Input() isRemovable: boolean = true;
  @Output() actorFormSubmit = new EventEmitter<boolean>();
  @Output() actorFormRemove = new EventEmitter<boolean>();
  @Input() metadataType: 'dataset'|'af' = null;
  @Input() defaultTab: 'organism' | 'person' | 'all'

  //liste des organismes pour peupler le select HTML
  get organisms() { return this.actorFormS.organisms; }

  //liste des roles pour peupler le select HTML
  get roles() { return this.actorFormS.roles; }

  //liste des types de role pour peupler le select HTML
  get role_types() {
    return this.actorFormS.role_types
          .filter(e => {
            if(e.cd_nomenclature == 1) {
              return false
            } else {
              if(this.metadataType == "dataset" && AppConfig.METADATA.CD_NOMENCLATURE_ROLE_TYPE_DS.length > 0) {
                return AppConfig.METADATA.CD_NOMENCLATURE_ROLE_TYPE_DS.includes(e.cd_nomenclature);
              }
              if(this.metadataType == "af" && AppConfig.METADATA.CD_NOMENCLATURE_ROLE_TYPE_AF.length > 0) {
                return AppConfig.METADATA.CD_NOMENCLATURE_ROLE_TYPE_AF.includes(e.cd_nomenclature);
              }
            }
            return true;
          });
  }

  //Retourne l'objet organisme à partir de son identifiant issu du formulaire (pour affiche son label en mode edition = false)
  get organismValue() {
    return this.organisms
            .find((organism: any) => organism.id_organisme == this.actorForm.get('id_organism').value);
  }

  //Retourne l'objet role à partir de son identifiant issu du formulaire (pour affiche son label en mode edition = false)
  get roleValue() {
    return this.roles
            .find((role: any) => role.id_role == this.actorForm.get('id_role').value);
  }

  //indique si c'est une formulaire d'édition ou de creation
  isEdition: boolean = false;

  //switch entre affichage du formulaire ou des labels
  toggleForm: boolean = false;


  //Pour switcher l'affichage du formulaire avec la liste organisme seule, role seul ou les deux.
  _toggleButtonValue: BehaviorSubject<string> = new BehaviorSubject("organism");
  get toggleButtonValue() { return this._toggleButtonValue.getValue(); };

  @Input() parentFormArray: FormArray;

  constructor(
    public dialog: MatDialog,
    private actorFormS: ActorFormService,
  ) {}

  ngOnInit() {
    if (!this.actorForm.get('id_organism').value && !this.actorForm.get('id_role').value) {
      this.toggleForm = true;

      if (this.actorForm.get('id_nomenclature_actor_role').value !== null) {
        this.isEdition = true;
      }
    }

    this.setToggleButtonValue();

  }

  setToggleButtonValue() {
    //selectionne le bon element du toggleButton en fonction de la valeur initiale du formulaire
    if (this.actorForm.get('id_organism').value && this.actorForm.get('id_role').value) {
      this._toggleButtonValue.next('all');
    } else if (this.actorForm.get('id_role').value) {
      this._toggleButtonValue.next('person');
    } else {
      this._toggleButtonValue.next('organism');
    }
  }

  submitActor() {
    this.actorFormSubmit.emit(this.actorForm.valid);
  }

  remove() {
    const message = `Êtes-vous certain de supprimer cet acteur ?`;
    const dialogRef = this.dialog.open(ConfirmationDialog, {
      width: "350px",
      position: { top: "5%" },
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
    return this.actorFormS.getCdNomenclatureByIDRoleType(this.actorForm.get('id_nomenclature_actor_role').value) == "1";
  }


}



