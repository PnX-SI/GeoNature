import {
  Component,
  OnInit,
  Input,
  Output,
  EventEmitter,
  IterableDiffers,
  IterableDiffer
} from '@angular/core';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { DataFormService } from '../data-form.service';
import { AppConfig } from '../../../../conf/app.config';
import { GenericFormComponent } from '@geonature_common/form/genericForm.component';
import { CommonService } from '../../service/common.service';

@Component({
  selector: 'pnx-datasets',
  templateUrl: 'datasets.component.html'
})
export class DatasetsComponent extends GenericFormComponent implements OnInit {
  public dataSets: Observable<any>;
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
  }

  ngOnInit() {
    this.getDatasets();
  }

  getDatasets(params?) {
    params = {};
    if (this.displayOnlyActive) {
      params['active'] = true;
    }
    this.dataSets = this._dfs
                          .getDatasets(params)
                          .pipe(
                            map(
                              res => {
                                if (res['with_mtd_errors']) {
                                  this._commonService.translateToaster('error', 'MetaData.JddErrorMTD');
                                }

                                const c = new Intl.Collator();
                                return res.data.sort((a,b)=> c.compare(a.dataset_name, b.dataset_name));
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
                              })
                          );
  }
}
