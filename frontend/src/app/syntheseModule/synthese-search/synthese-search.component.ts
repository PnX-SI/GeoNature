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
import { TaxonAdvancedModalComponent } from './taxon-advanced/taxon-advanced.component';
import { DataFormService } from '../../GN2CommonModule/form/data-form.service';

@Component({
  selector: 'pnx-synthese-search',
  templateUrl: 'synthese-search.component.html',
  styleUrls: ['synthese-search.component.scss'],
  providers: []
})
export class SyntheseSearchComponent implements OnInit {
  public AppConfig = AppConfig;
  public nomenclaturesForms = [
    {
      type_widget: 'nomenclature',
      attribut_label: "Technique d'observation",
      attribut_name: 'cd_nomenclature_obs_technique',
      code_nomenclature_type: 'TECHNIQUE_OBS',
      required: false,
      multi_select: true
    },
    {
      type_widget: 'nomenclature',
      attribut_label: 'Type de regroupement',
      attribut_name: 'cd_nomenclature_grp_typ',
      code_nomenclature_type: 'TYP_GRP',
      required: false,
      multi_select: true
    },
    {
      type_widget: 'nomenclature',
      attribut_label: "Statut d'observation",
      attribut_name: 'cd_nomenclature_observation_status',
      code_nomenclature_type: 'STATUT_OBS',
      required: false,
      multi_select: true
    },
    {
      type_widget: 'nomenclature',
      attribut_label: "Méthode d'observation",
      attribut_name: 'cd_nomenclature_obs_meth',
      code_nomenclature_type: 'METH_OBS',
      required: false,
      multi_select: true
    },
    {
      type_widget: 'nomenclature',
      attribut_label: 'Etat biologique',
      attribut_name: 'cd_nomenclature_bio_condition',
      code_nomenclature_type: 'ETA_BIO',
      required: false,
      multi_select: true
    },
    {
      type_widget: 'nomenclature',
      attribut_label: 'Statut biologique',
      attribut_name: 'cd_nomenclature_bio_status',
      code_nomenclature_type: 'STATUT_BIO',
      required: false,
      multi_select: true
    },
    {
      type_widget: 'nomenclature',
      attribut_label: 'Naturalité',
      attribut_name: 'cd_nomenclature_naturalness',
      code_nomenclature_type: 'NATURALITE',
      required: false,
      multi_select: true
    },
    {
      type_widget: 'nomenclature',
      attribut_label: 'Méthode de détermination',
      attribut_name: 'cd_nomenclature_determination_method',
      code_nomenclature_type: 'METH_DETERMIN',
      required: false,
      multi_select: true
    },
    {
      type_widget: 'nomenclature',
      attribut_label: "Preuve d'existence",
      attribut_name: 'cd_nomenclature_exist_proof',
      code_nomenclature_type: 'PREUVE_EXIST',
      required: false,
      multi_select: true
    },
    {
      type_widget: 'nomenclature',
      attribut_label: 'Niveau de diffusion',
      attribut_name: 'cd_nomenclature_diffusion_level',
      code_nomenclature_type: 'NIV_PRECIS',
      required: false,
      multi_select: true
    },
    {
      type_widget: 'nomenclature',
      attribut_label: 'Statut source',
      attribut_name: 'cd_nomenclature_source_status',
      code_nomenclature_type: 'STATUT_SOURCE',
      required: false,
      multi_select: true
    },
    {
      type_widget: 'nomenclature',
      attribut_label: 'Floutage',
      attribut_name: 'cd_nomenclature_blurring',
      code_nomenclature_type: 'DEE_FLOU',
      required: false,
      multi_select: true
    },
    // counting
    {
      type_widget: 'nomenclature',
      attribut_label: 'Stade de vie',
      attribut_name: 'cd_nomenclature_life_stage',
      code_nomenclature_type: 'STADE_VIE',
      required: false,
      multi_select: true
    },
    {
      type_widget: 'nomenclature',
      attribut_label: 'Sexe',
      attribut_name: 'cd_nomenclature_sex',
      code_nomenclature_type: 'SEXE',
      required: false,
      multi_select: true
    },
    {
      type_widget: 'nomenclature',
      attribut_label: 'Objet du dénombrement',
      attribut_name: 'cd_nomenclature_obj_count',
      code_nomenclature_type: 'OBJ_DENBR',
      required: false,
      multi_select: true
    },
    {
      type_widget: 'nomenclature',
      attribut_label: 'Type de dénombrement',
      attribut_name: 'cd_nomenclature_type_count',
      code_nomenclature_type: 'TYP_DENBR',
      required: false,
      multi_select: true
    },
    {
      type_widget: 'nomenclature',
      attribut_label: 'Statut de validation',
      attribut_name: 'cd_nomenclature_valid_status',
      code_nomenclature_type: 'STATUT_VALID',
      required: false,
      multi_select: true
    },
    {
      type_widget: 'nomenclature',
      attribut_label: "Type d'objet géographique",
      attribut_name: 'cd_nomenclature_geo_object_nature',
      code_nomenclature_type: 'NAT_OBJ_GEO',
      required: false,
      multi_select: true
    },
    {
      type_widget: 'nomenclature',
      attribut_label: 'Sensibilité',
      attribut_name: 'cd_nomenclature_sensitivity',
      code_nomenclature_type: 'SENSIBILITE',
      required: false,
      multi_select: true
    },
    {
      type_widget: 'nomenclature',
      attribut_label: 'Sensibilité',
      attribut_name: 'cd_nomenclature_sensitivity',
      code_nomenclature_type: 'cd_nomenclature_info_geo_type',
      required: false,
      multi_select: true
    },
    {
      type_widget: 'text',
      attribut_label: 'Preuve numérique',
      attribut_name: 'digital_proof',
      required: false
    },
    {
      type_widget: 'text',
      attribut_label: 'Preuve non numérique',
      attribut_name: 'non_digital_proof',
      required: false
    }
  ];
  public taxonApiEndPoint = `${AppConfig.API_ENDPOINT}/synthese/taxons_autocomplete`;
  @Output() searchClicked = new EventEmitter();
  constructor(
    private _fb: FormBuilder,
    public dataService: DataService,
    public formService: SyntheseFormService,
    public ngbModal: NgbModal,
    public mapService: MapService,
    private _dfs: DataFormService
  ) {}

  ngOnInit() {}

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
    const taxonModal = this.ngbModal.open(TaxonAdvancedModalComponent, {
      size: 'lg',
      backdrop: 'static',
      keyboard: false
    });
    // this.taxonModal.componentInstance.closeBtnName = 'close';
  }
}
