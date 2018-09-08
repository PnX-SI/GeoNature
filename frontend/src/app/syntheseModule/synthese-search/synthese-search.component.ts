import { Component, OnInit, Output, EventEmitter, ViewChild } from '@angular/core';
import { FormBuilder } from '@angular/forms';
import { DataService } from '../services/data.service';
import { SyntheseFormService } from '../services/form.service';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { AppConfig } from '@geonature_config/app.config';
import { MapService } from '@geonature_common/map/map.service';
import {
  TreeComponent,
  TreeModel,
  TreeNode,
  TREE_ACTIONS,
  IActionMapping,
  ITreeOptions
} from 'angular-tree-component';
import { TaxonTreeModalComponent } from './taxon-tree/taxon-tree.component';

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
      keyValue: 'id_nomenclature',
      multiSelect: true
    },
    {
      controlType: 'nomenclature',
      label: 'Type de regroupement',
      key: 'cd_nomenclature_grp_typ',
      codeNomenclatureType: 'TYP_GRP',
      required: false,
      keyValue: 'id_nomenclature',
      multiSelect: true
    },
    {
      controlType: 'nomenclature',
      label: "Statut d'observation",
      key: 'cd_nomenclature_observation_status',
      codeNomenclatureType: 'STATUT_OBS',
      required: false,
      keyValue: 'id_nomenclature',
      multiSelect: true
    },
    {
      controlType: 'nomenclature',
      label: "Méthode d'observation",
      key: 'cd_nomenclature_obs_meth',
      codeNomenclatureType: 'METH_OBS',
      required: false,
      keyValue: 'id_nomenclature',
      multiSelect: true
    },
    {
      controlType: 'nomenclature',
      label: 'Etat biologique',
      key: 'cd_nomenclature_bio_condition',
      codeNomenclatureType: 'ETA_BIO',
      required: false,
      keyValue: 'id_nomenclature',
      multiSelect: true
    },
    {
      controlType: 'nomenclature',
      label: 'Statut biologique',
      key: 'cd_nomenclature_bio_status',
      codeNomenclatureType: 'STATUT_BIO',
      required: false,
      keyValue: 'id_nomenclature',
      multiSelect: true
    },
    {
      controlType: 'nomenclature',
      label: 'Naturalité',
      key: 'cd_nomenclature_naturalness',
      codeNomenclatureType: 'NATURALITE',
      required: false,
      keyValue: 'id_nomenclature',
      multiSelect: true
    },
    {
      controlType: 'nomenclature',
      label: 'Méthode de détermination',
      key: 'cd_nomenclature_determination_method',
      codeNomenclatureType: 'METH_DETERMIN',
      required: false,
      keyValue: 'id_nomenclature',
      multiSelect: true
    },
    {
      controlType: 'nomenclature',
      label: "Preuve d'existence",
      key: 'cd_nomenclature_exist_proof',
      codeNomenclatureType: 'PREUVE_EXIST',
      required: false,
      keyValue: 'id_nomenclature',
      multiSelect: true
    },
    {
      controlType: 'nomenclature',
      label: 'Niveau de diffusion',
      key: 'cd_nomenclature_diffusion_level',
      codeNomenclatureType: 'NIV_PRECIS',
      required: false,
      keyValue: 'id_nomenclature',
      multiSelect: true
    },
    {
      controlType: 'nomenclature',
      label: 'Statut source',
      key: 'cd_nomenclature_source_status',
      codeNomenclatureType: 'STATUT_SOURCE',
      required: false,
      keyValue: 'id_nomenclature',
      multiSelect: true
    },
    {
      controlType: 'nomenclature',
      label: 'Floutage',
      key: 'cd_nomenclature_blurring',
      codeNomenclatureType: 'DEE_FLOU',
      required: false,
      keyValue: 'id_nomenclature',
      multiSelect: true
    },
    // counting
    {
      controlType: 'nomenclature',
      label: 'Stade de vie',
      key: 'cd_nomenclature_life_stage',
      codeNomenclatureType: 'STADE_VIE',
      required: false,
      keyValue: 'id_nomenclature',
      multiSelect: true
    },
    {
      controlType: 'nomenclature',
      label: 'Sexe',
      key: 'cd_nomenclature_sex',
      codeNomenclatureType: 'SEXE',
      required: false,
      keyValue: 'id_nomenclature',
      multiSelect: true
    },
    {
      controlType: 'nomenclature',
      label: 'Objet du dénombrement',
      key: 'cd_nomenclature_obj_count',
      codeNomenclatureType: 'OBJ_DENBR',
      required: false,
      keyValue: 'id_nomenclature',
      multiSelect: true
    },
    {
      controlType: 'nomenclature',
      label: 'Type de dénombrement',
      key: 'cd_nomenclature_type_count',
      codeNomenclatureType: 'TYP_DENBR',
      required: false,
      keyValue: 'id_nomenclature',
      multiSelect: true
    },
    {
      controlType: 'nomenclature',
      label: 'Statut de validation',
      key: 'cd_nomenclature_valid_status',
      codeNomenclatureType: 'STATUT_VALID',
      required: false,
      keyValue: 'id_nomenclature',
      multiSelect: true
    }
  ];
  public taxonApiEndPoint = `${AppConfig.API_ENDPOINT}/synthese/taxons_autocomplete`;
  @Output() searchClicked = new EventEmitter();
  constructor(
    private _fb: FormBuilder,
    public dataService: DataService,
    public formService: SyntheseFormService,
    public ngbModal: NgbModal,
    public mapService: MapService
  ) { }

  ngOnInit() {

  }

  onSubmitForm() {
    const updatedParams = this.formService.formatParams();
    this.searchClicked.emit(updatedParams);
  }

  refreshFilters() {
    this.formService.selectedtaxonFromComponent = [];
    this.formService.selectedCdRefFromTree = [];
    this.formService.searchForm.reset();
    // remove layers draw in the map
    console.log(this.mapService.releveFeatureGroup);
    this.mapService.removeAllLayers(this.mapService.map, this.mapService.releveFeatureGroup);
  }

  openModal(e, modalName) {
    const taxonModal = this.ngbModal.open(TaxonTreeModalComponent, {
      size: 'lg',
      backdrop: 'static',
      keyboard: false
    });
    // this.taxonModal.componentInstance.closeBtnName = 'close';
  }
}
