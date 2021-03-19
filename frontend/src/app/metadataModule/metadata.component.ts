import { Component, OnInit, ViewChild } from '@angular/core';
import { PageEvent, MatPaginator } from '@angular/material';
import { CruvedStoreService } from '../GN2CommonModule/service/cruved-store.service';
import { AppConfig } from '@geonature_config/app.config';
import { Router, NavigationExtras } from "@angular/router";
import { NgbModal } from "@ng-bootstrap/ng-bootstrap";
import { MatDialog } from "@angular/material";
import { NgbDateStruct } from '@ng-bootstrap/ng-bootstrap';
import { forkJoin, Observable, BehaviorSubject, combineLatest } from 'rxjs';
import { tap, map, startWith, distinctUntilChanged, debounceTime, filter  } from 'rxjs/operators';
import { TranslateService } from "@ngx-translate/core";

import { DataFormService } from '@geonature_common/form/data-form.service';
import { CommonService } from "@geonature_common/service/common.service";
import { ModuleService } from '@geonature/services/module.service';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { MetadataService } from './services/metadata.service';
import { ConfirmationDialog } from "@geonature_common/others/modal-confirmation/confirmation.dialog";


@Component({
  selector: 'pnx-metadata',
  templateUrl: './metadata.component.html',
  styleUrls: ['./metadata.component.scss']
})
export class MetadataComponent implements OnInit {

  @ViewChild(MatPaginator) paginator: MatPaginator;

  /* getter this.metadataService.filteredAcquisitionFrameworks */
  acquisitionFrameworks: Observable<any[]>;

  get expandAccordions(): boolean {
    return this.metadataService.expandAccordions;
  }
  /* liste des organismes issues de l'API pour le select. */
  public organisms: any[] = [];
  /* liste des roles issues de l'API pour le select. */
  public roles: any[] = [];

  get isLoading(): boolean {
    return this.metadataService.isLoading;
  }

  searchTerms: any = {};
  afPublishModalId: number;
  afPublishModalLabel: string;
  afPublishModalContent: string;
  APP_CONFIG = AppConfig;

  pageSize: number;
  pageIndex: number;

  private _moduleImportIsAuthorized: BehaviorSubject<boolean> = new BehaviorSubject(false);
  get moduleImportIsAuthorized() {
    return this._moduleImportIsAuthorized.getValue();
  }

  constructor(
    public _cruvedStore: CruvedStoreService,
    public dialog: MatDialog,
    private translate: TranslateService,
    private _dfs: DataFormService,
    private _router: Router,
    private modal: NgbModal,
    public moduleService: ModuleService,
    public metadataService: MetadataService,
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

    this._dfs.getOrganisms()
      .subscribe(organisms => this.organisms = organisms);

    this._dfs.getRoles({ 'group': false })
      .subscribe(roles => this.roles = roles);;

    this.afPublishModalLabel = AppConfig.METADATA.CLOSED_MODAL_LABEL;
    this.afPublishModalContent = AppConfig.METADATA.CLOSED_MODAL_CONTENT;

    //Combinaison des observables pour afficher les éléments filtrés en fonction de l'état du paginator
    this.acquisitionFrameworks = combineLatest(
      this.metadataService.filteredAcquisitionFrameworks
        .pipe(distinctUntilChanged()),
      this.metadataService.pageIndex.asObservable()
        .pipe(distinctUntilChanged()),
      this.metadataService.pageSize.asObservable()
        .pipe(distinctUntilChanged())
    )
      .pipe(
        map(([afs, pageIndex, pageSize]) => afs.slice(pageIndex*pageSize, (pageIndex + 1)*pageSize)),
      )
  }
  
  refreshFilters() {
    this.metadataService.resetForm();
    this.advancedSearch();
    this.metadataService.expandAccordions = false;
  }

  private advancedSearch() {
    const formValue = this.metadataService.formatFormValue(
      Object.assign({}, this.metadataService.form.value)
    );
    this.metadataService.getMetadata(formValue);
    this.metadataService.expandAccordions = true;
  }

  openSearchModal(searchModal) {
    this.metadataService.resetForm();
    this.modal.open(searchModal);
  }

  changePaginator(event: PageEvent) {
    this.metadataService.pageSize.next(event.pageSize);
    this.metadataService.pageIndex.next(event.pageIndex);
  }

  deleteAf(af_id) {
    this._dfs.deleteAf(af_id).subscribe(
      res => this.metadataService.getMetadata()
    );
  }

  openPublishModalAf(e, af_id, publishModal) {
    this.afPublishModalId = af_id;
    this.modal.open(publishModal, { size: 'lg' });
  }

  publishAf() {
    this._dfs.publishAf(this.afPublishModalId).subscribe(
      res => this.metadataService.getMetadata(),
      error => {
        this._commonService.regularToaster(
          'error', "Une erreur s'est produite lors de la fermeture du cadre d'acquisition. Contactez l'administrateur"
          )
    }
    )

    this.modal.dismissAll();
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
            tap(() => this.metadataService.getMetadata())
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
