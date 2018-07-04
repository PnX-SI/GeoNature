import { Component, OnInit, Output, EventEmitter } from '@angular/core';
import { FormBuilder, FormGroup } from '@angular/forms';
import { DataService } from '../services/data.service';
import { FormService } from '../services/form.service';
import { NgbModal, ModalDismissReasons } from '@ng-bootstrap/ng-bootstrap';

@Component({
  selector: 'pnx-synthese-search',
  templateUrl: 'synthese-search.component.html',
  styleUrls: ['synthese-search.component.scss']
})
export class SyntheseSearchComponent implements OnInit {
  public searchForm: FormGroup;
  public nomenclaturesForms = [
    {
      controlType: 'nomenclature',
      label: "Technique d'observation",
      key: 'id_nomenclature_obs_technique',
      idComponent: 100,
      required: false
    },
    {
      controlType: 'nomenclature',
      label: 'Type de regroupement',
      key: 'id_nomenclature_grp_typ',
      idComponent: 24,
      required: false
    },
    {
      controlType: 'nomenclature',
      label: "Statut d'observation",
      key: 'id_nomenclature_observation_status',
      idComponent: 18,
      required: false
    },
    {
      controlType: 'nomenclature',
      label: "Méthode d'observation",
      key: 'id_nomenclature_obs_meth',
      idComponent: 14,
      required: false
    },
    {
      controlType: 'nomenclature',
      label: 'Etat biologique',
      key: 'id_nomenclature_bio_condition',
      idComponent: 7,
      required: false
    },
    {
      controlType: 'nomenclature',
      label: 'Statut biologique',
      key: 'id_nomenclature_bio_status',
      idComponent: 13,
      required: false
    },
    {
      controlType: 'nomenclature',
      label: 'Naturalité',
      key: 'id_nomenclature_naturalness',
      idComponent: 8,
      required: false
    },
    {
      controlType: 'nomenclature',
      label: 'Méthode de détermination',
      key: 'id_nomenclature_determination_method',
      idComponent: 106,
      required: false
    },
    {
      controlType: 'nomenclature',
      label: "Preuve d'existence",
      key: 'id_nomenclature_exist_proof',
      idComponent: 15,
      required: false
    },
    {
      controlType: 'nomenclature',
      label: 'Niveau de diffusion',
      key: 'id_nomenclature_diffusion_level',
      idComponent: 5,
      required: false
    },
    {
      controlType: 'nomenclature',
      label: 'Statut source',
      key: 'id_nomenclature_source_status',
      idComponent: 19,
      required: false
    },
    {
      controlType: 'nomenclature',
      label: 'Floutage',
      key: 'id_nomenclature_blurring',
      idComponent: 4,
      required: false
    },
    // counting
    {
      controlType: 'nomenclature',
      label: 'Stade de vie',
      key: 'id_nomenclature_life_stage',
      idComponent: 10,
      required: false
    },
    {
      controlType: 'nomenclature',
      label: 'Sexe',
      key: 'id_nomenclature_sex',
      idComponent: 9,
      required: false
    },
    {
      controlType: 'nomenclature',
      label: 'Objet du dénombrement',
      key: 'id_nomenclature_obj_count',
      idComponent: 6,
      required: false
    },
    {
      controlType: 'nomenclature',
      label: 'Type de dénombrement',
      key: 'id_nomenclature_type_count',
      idComponent: 21,
      required: false
    },
    {
      controlType: 'nomenclature',
      label: 'Statut de validation',
      key: 'id_nomenclature_valid_status',
      idComponent: 101,
      required: false
    }
  ];

  @Output() searchClicked = new EventEmitter();
  constructor(
    private _fb: FormBuilder,
    public dataService: DataService,
    public formService: FormService,
    public ngbModal: NgbModal
  ) {}

  ngOnInit() {}

  onSubmitForm() {
    const params = Object.assign({}, this.searchForm.value);
    if (params.cd_nom) {
      params.cd_nom = params.cd_nom.cd_nom;
    }
    this.searchClicked.emit(params);
  }

  openModalCol(e, modalName) {
    this.ngbModal.open(modalName, { size: 'lg' });
  }
}
