import {
  Component,
  OnInit,
  Input,
  Output,
  EventEmitter,
  OnChanges,
  DoCheck,
  IterableDiffers,
  IterableDiffer
} from '@angular/core';
import { DataFormService } from '../data-form.service';
import { AppConfig } from '../../../../conf/app.config';
import { GenericFormComponent } from '@geonature_common/form/genericForm.component';
import { CommonService } from '../../service/common.service';

@Component({
  selector: 'pnx-datasets',
  templateUrl: 'datasets.component.html'
})
export class DatasetsComponent extends GenericFormComponent implements OnInit, OnChanges, DoCheck {
  public dataSets: any;
  public savedDatasets: Array<any>;
  public iterableDiffer: IterableDiffer<any>;
  @Input() idAcquisitionFrameworks: Array<number> = [];
  @Input() idAcquisitionFramework: number;
  @Input() bindAllItem: false;
  @Input() displayOnlyActive = true;
  constructor(
    private _dfs: DataFormService,
    private _commonService: CommonService,
    private _iterableDiffers: IterableDiffers
  ) {
    super();
    this.iterableDiffer = this._iterableDiffers.find([]).create(null);
  }

  ngOnInit() {
    this.getDatasets();
  }

  getDatasets(params?) {
    params = {};
    if (this.displayOnlyActive) {
      params['active'] = true;
    }
    this._dfs.getDatasets(params).subscribe(
      res => {
        this.dataSets = res.data;
        this.savedDatasets = res.data;
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
    this.dataSets = super.filterItems(event, this.savedDatasets, 'dataset_shortname');
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
