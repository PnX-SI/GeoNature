import { Component, OnInit, Output, EventEmitter } from '@angular/core';
import { FormBuilder, FormGroup } from '@angular/forms';
import { DataService } from '../services/data.service';
import { FormService } from '../services/form.service';
import { NgbModal, ModalDismissReasons } from '@ng-bootstrap/ng-bootstrap';
import { AppConfig } from '@geonature_config/app.config';

@Component({
  selector: 'pnx-synthese-search',
  templateUrl: 'synthese-search.component.html',
  styleUrls: ['synthese-search.component.scss']
})
export class SyntheseSearchComponent implements OnInit {
  public AppConfig = AppConfig;
  public nomenclaturesForms = [
    {
      controlType: 'nomenclature',
      label: "Technique d'observation",
      key: 'cd_nomenclature_obs_technique',
      codeNomenclatureType: 'TECHNIQUE_OBS',
      required: false,
      keyValue: 'cd_nomenclature',
      multiSelect: true
    },
    {
      controlType: 'nomenclature',
      label: 'Type de regroupement',
      key: 'cd_nomenclature_grp_typ',
      codeNomenclatureType: 'TYP_GRP',
      required: false,
      keyValue: 'cd_nomenclature',
      multiSelect: true
    },
    {
      controlType: 'nomenclature',
      label: "Statut d'observation",
      key: 'cd_nomenclature_observation_status',
      codeNomenclatureType: 'STATUT_OBS',
      required: false,
      keyValue: 'cd_nomenclature',
      multiSelect: true
    },
    {
      controlType: 'nomenclature',
      label: "Méthode d'observation",
      key: 'cd_nomenclature_obs_meth',
      codeNomenclatureType: 'METH_OBS',
      required: false,
      keyValue: 'cd_nomenclature',
      multiSelect: true
    },
    {
      controlType: 'nomenclature',
      label: 'Etat biologique',
      key: 'cd_nomenclature_bio_condition',
      codeNomenclatureType: 'ETA_BIO',
      required: false,
      keyValue: 'cd_nomenclature',
      multiSelect: true
    },
    {
      controlType: 'nomenclature',
      label: 'Statut biologique',
      key: 'cd_nomenclature_bio_status',
      codeNomenclatureType: 'STATUT_BIO',
      required: false,
      keyValue: 'cd_nomenclature',
      multiSelect: true
    },
    {
      controlType: 'nomenclature',
      label: 'Naturalité',
      key: 'cd_nomenclature_naturalness',
      codeNomenclatureType: 'NATURALITE',
      required: false,
      keyValue: 'cd_nomenclature',
      multiSelect: true
    },
    {
      controlType: 'nomenclature',
      label: 'Méthode de détermination',
      key: 'cd_nomenclature_determination_method',
      codeNomenclatureType: 'METH_DETERMIN',
      required: false,
      keyValue: 'cd_nomenclature',
      multiSelect: true
    },
    {
      controlType: 'nomenclature',
      label: "Preuve d'existence",
      key: 'cd_nomenclature_exist_proof',
      codeNomenclatureType: 'PREUVE_EXIST',
      required: false,
      keyValue: 'cd_nomenclature',
      multiSelect: true
    },
    {
      controlType: 'nomenclature',
      label: 'Niveau de diffusion',
      key: 'cd_nomenclature_diffusion_level',
      codeNomenclatureType: 'NIV_PRECIS',
      required: false,
      keyValue: 'cd_nomenclature',
      multiSelect: true
    },
    {
      controlType: 'nomenclature',
      label: 'Statut source',
      key: 'cd_nomenclature_source_status',
      codeNomenclatureType: 'STATUT_SOURCE',
      required: false,
      keyValue: 'cd_nomenclature',
      multiSelect: true
    },
    {
      controlType: 'nomenclature',
      label: 'Floutage',
      key: 'cd_nomenclature_blurring',
      codeNomenclatureType: 'DEE_FLOU',
      required: false,
      keyValue: 'cd_nomenclature',
      multiSelect: true
    },
    // counting
    {
      controlType: 'nomenclature',
      label: 'Stade de vie',
      key: 'cd_nomenclature_life_stage',
      codeNomenclatureType: 'STADE_VIE',
      required: false,
      keyValue: 'cd_nomenclature',
      multiSelect: true
    },
    {
      controlType: 'nomenclature',
      label: 'Sexe',
      key: 'cd_nomenclature_sex',
      codeNomenclatureType: 'SEXE',
      required: false,
      keyValue: 'cd_nomenclature',
      multiSelect: true
    },
    {
      controlType: 'nomenclature',
      label: 'Objet du dénombrement',
      key: 'cd_nomenclature_obj_count',
      codeNomenclatureType: 'OBJ_DENBR',
      required: false,
      keyValue: 'cd_nomenclature',
      multiSelect: true
    },
    {
      controlType: 'nomenclature',
      label: 'Type de dénombrement',
      key: 'cd_nomenclature_type_count',
      codeNomenclatureType: 'TYP_DENBR',
      required: false,
      keyValue: 'cd_nomenclature',
      multiSelect: true
    },
    {
      controlType: 'nomenclature',
      label: 'Statut de validation',
      key: 'cd_nomenclature_valid_status',
      codeNomenclatureType: 'STATUT_VALID',
      required: false,
      keyValue: 'cd_nomenclature',
      multiSelect: true
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
    const params = Object.assign({}, this.formService.searchForm.value);
    const updatedParams = {};
    for (let key in params) {
      // if cd_nom
      if (params.cd_nom && params.cd_nom.length > 0) {
        updatedParams['cd_nom'] = [];
        params.cd_nom.forEach(el => {
          params.cd_nom = params.cd_nom.cd_nom;
          updatedParams['cd_nom'].push(el.cd_nom);
        });
        // if other key an value not null or undefined
      } else if (params[key]) {
        // if its an Array push only if > 0
        if (Array.isArray(params[key]) && params[key].length > 0) {
          updatedParams[key] = params[key];
          // else if its not an array, alway send the parameter
        } else if (!Array.isArray(params[key])) {
          updatedParams[key] = params[key];
        }
      }
    }
    console.log(updatedParams);
    this.searchClicked.emit(updatedParams);
  }

  openModalCol(e, modalName) {
    this.ngbModal.open(modalName, { size: 'lg' });
  }
}
