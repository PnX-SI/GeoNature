import {
  Component,
  OnInit,
  Input,
  OnChanges,
  DoCheck,
  IterableDiffers,
  IterableDiffer
} from '@angular/core';
import { DataFormService } from '../data-form.service';
import { AppConfig } from '../../../../conf/app.config';
import { GenericFormComponent } from '@geonature_common/form/genericForm.component';
import { CommonService } from '../../service/common.service';
import { DatasetStoreService } from "./dataset.service";

/**
 *  Ce composant permet de créer un "input" de type "select" ou "multiselect" affichant l'ensemble des jeux de données sur lesquels l'utilisateur connecté a des droits (table ``gn_meta.t_datasets`` et ``gn_meta.cor_dataset_actor``)
 *
 * @example
 * <pnx-datasets
 * [idAcquisitionFrameworks]="formService.searchForm.controls.id_acquisition_frameworks.value"
 * [multiSelect]='true'
 *  [displayAll]="true"
 * [parentFormControl]="formService.searchForm.controls.id_dataset"
 * label="{{ 'MetaData.Datasets' | translate}}"
 * </pnx-datasets>
 */
@Component({
  selector: 'pnx-datasets',
  templateUrl: 'datasets.component.html',
})
export class DatasetsComponent extends GenericFormComponent implements OnInit, OnChanges, DoCheck {
  public iterableDiffer: IterableDiffer<any>;
  /**
   * Permet de filtrer les JDD en fonction d'un tableau d'ID cadre d'acqusition. A connecter avec le formControl du composant ``pnx-acquisition-framework``.
   * Utiliser cet Input lorsque le composant ``pnx-acquisition-framework`` est en mode multiselect.
   */
  @Input() idAcquisitionFrameworks: Array<number> = [];
  /**
   *  Permet de filtrer les JDD en fonction de l'ID cadre d'acqusition. A connecter avec le formControl du composant ``pnx-acquisition-framework``.
   *  Utiliser cet Input lorsque le composant ``pnx-acquisition-framework`` est en mode select simple.
   */
  @Input() idAcquisitionFramework: number;
  /**
   * Est-ce que le composant doit afficher l'item "tous" dans les options du select ? (facultatif)
   */
  @Input() bindAllItem: boolean = false;
  /**
   * Booléan qui controle si on affiche seulement les JDD actifs ou également ceux qui sont inatif
   */
  @Input() displayOnlyActive: boolean = true;

  /**
   * code du module pour n'afficher que les JDD associés au module
   */
  @Input() moduleCode: string;

  constructor(
    private _dfs: DataFormService,
    private _commonService: CommonService,
    private _iterableDiffers: IterableDiffers,
    public datasetStore: DatasetStoreService
  ) {
    super();
    this.iterableDiffer = this._iterableDiffers.find([]).create(null);
  }

  ngOnInit() {
    this.getDatasets();
  }

  getDatasets(params?) {
    const filter_param = {};
    if (this.displayOnlyActive) {
      filter_param['active'] = true;
    }
    if (this.moduleCode) {
      filter_param['module_code'] = this.moduleCode;
    }
    this._dfs.getDatasets((params = filter_param)).subscribe(
      res => {
        this.datasetStore.filteredDataSets = res.data;
        this.datasetStore.datasets = res.data;        
        this.valueLoaded.emit({ value: this.datasetStore.datasets });
        if (res['with_mtd_errors']) {
          this._commonService.translateToaster('error', 'MetaData.JddErrorMTD');
        }
      },
      error => {
        if (error.status === 500) {
          this._commonService.translateToaster('error', 'MetaData.JddError');
        } else if (error.status === 404) {
          if (AppConfig.CAS_PUBLIC.CAS_AUTHENTIFICATION) {
            this._commonService.translateToaster('warning', 'MetaData.NoJDDMTD');
          } else {
            this._commonService.translateToaster('warning', 'MetaData.NoJDD');
          }
        }
      }
    );
  }

  filterItems(event) {
    this.datasetStore.filteredDataSets = super.filterItems(event, this.datasetStore.datasets, 'dataset_shortname');
  }

  ngOnChanges(changes) {
    // detetch change on input idAcquisitionFramework
    // (the number, if the AFcomponent is not multiSelect) to reload datasets
    if (
      changes['idAcquisitionFramework'] &&
      changes['idAcquisitionFramework'].currentValue !== undefined
    ) {
      const params = { id_acquisition_framework: changes['idAcquisitionFramework'].currentValue };
      this.getDatasets(params);
    }
  }

  ngDoCheck() {
    // detetch change on input idAcquisitionFrameworks (the array of id_af) to reload datasets
    // because its an array we have to detect change on value not on reference
    const changes = this.iterableDiffer.diff(this.idAcquisitionFrameworks);
    if (changes) {
      const idAcquisitionFrameworks = [];
      changes.forEachItem(it => {
        idAcquisitionFrameworks.push(it.item);
      });
      const params = { id_acquisition_frameworks: idAcquisitionFrameworks };
      this.getDatasets(params);
    }
  }
}
