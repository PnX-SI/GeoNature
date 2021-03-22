import { Component, OnInit, Input } from '@angular/core';
import { TranslateService } from "@ngx-translate/core";
import { MatDialog } from "@angular/material";
import { BehaviorSubject } from "rxjs";
import { tap, map } from "rxjs/operators";

import { DataFormService } from '@geonature_common/form/data-form.service';
import { ModuleService } from '@geonature/services/module.service';
import { ConfirmationDialog } from "@geonature_common/others/modal-confirmation/confirmation.dialog";
import { MetadataService } from './services/metadata.service';
import { MetadataDataService } from './services/metadata-data.service';
import { CommonService } from "@geonature_common/service/common.service";

@Component({
  selector: '[pnx-metadata-dataset]',
  templateUrl: './metadata-dataset.component.html',
  styleUrls: ['./metadata.component.scss']
})
export class MetadataDatasetComponent implements OnInit {

  @Input() dataset: any;
  stateChangeSaving: boolean = false;

  private _moduleImportIsAuthorized: BehaviorSubject<boolean> = new BehaviorSubject(false);
  get moduleImportIsAuthorized() {
    return this._moduleImportIsAuthorized.getValue();
  }
  
  constructor(
    private _dfs: DataFormService,
    private translate: TranslateService,
    public dialog: MatDialog,
    public moduleService: ModuleService,
    public metadataS: MetadataService,
    public metadataDataS: MetadataDataService,
    private _commonService: CommonService,
  ) { }

  ngOnInit() {
    //vérification que l'utilisateur est autorisé à utiliser le module d'import
    this.moduleService.moduleSub
      .pipe(
        map((modules: any[]): boolean => {
          if (modules) {
            for (let i = 0; i < modules.length; i++) {
              //recherche du module d'import et test si l'utilisateur a des droits dessus
              if (modules[i].module_code == 'IMPORT' && modules[i].cruved['C'] > 0) {
                return true;
              }
            }
          }
          return false;
        })
      )
      .subscribe((importIsAuthorized: boolean) => this._moduleImportIsAuthorized.next(importIsAuthorized));
  }
  

  switchDatasetState(event) {
    this.stateChangeSaving = true;
    this.metadataDataS.patchDataset(this.dataset.id_dataset, {active: event.checked})
      .pipe(
        tap(() => this.stateChangeSaving = false),
        map((res: any): boolean => res.active),
      )
      .subscribe((state: boolean) => this.dataset.active = state);
  }

  deleteDs(dataset) {
    const message = `${this.translate.instant("Delete")} ${dataset.dataset_name} ?`;
    const dialogRef = this.dialog.open(ConfirmationDialog, {
      width: "350px",
      position: { top: "5%" },
      data: { message: message },
    });

    dialogRef.afterClosed().subscribe((result) => {
      if (result) {
        this._dfs.deleteDs(dataset.id_dataset)
          .pipe(
            tap(() => this.metadataS.getMetadata())
          )
          .subscribe(
            () => this._commonService.translateToaster("success", "MetaData.DatasetRemoved"),
            err => {
              if (err.error.message) {
                this._commonService.regularToaster("error", err.error.message);
              } else {
                this._commonService.translateToaster("error", "ErrorMessage");
              }
             }
          );
      }
    });
  }
}
