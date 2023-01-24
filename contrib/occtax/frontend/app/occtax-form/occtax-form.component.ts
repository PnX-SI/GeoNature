import { Component, OnInit, OnDestroy, HostListener, AfterViewInit } from '@angular/core';
import { Subscription } from 'rxjs';
import { MatDialog } from '@angular/material/dialog';
import { Router, NavigationEnd } from '@angular/router';
import { CommonService } from '@geonature_common/service/common.service';
import { ModuleConfig } from '../module.config';
import { OcctaxFormService } from './occtax-form.service';
import { MapService } from '@geonature_common/map/map.service';
import { OcctaxFormParamService } from './form-param/form-param.service';
import { ConfirmationDialog } from '@geonature_common/others/modal-confirmation/confirmation.dialog';
import { OcctaxFormReleveService } from './releve/releve.service';
import { OcctaxFormOccurrenceService } from './occurrence/occurrence.service';
import { OcctaxTaxaListService } from './taxa-list/taxa-list.service';
import { OcctaxDataService } from '../services/occtax-data.service';
import { OcctaxFormCountingsService } from './counting/countings.service';
import { OcctaxFormMapService } from './map/occtax-map.service';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { filter } from 'rxjs/operators';
import { ModuleService } from '@geonature/services/module.service';

@Component({
  selector: 'pnx-occtax-form',
  templateUrl: './occtax-form.component.html',
  styleUrls: ['./occtax-form.component.scss'],
  providers: [
    OcctaxFormService,
    OcctaxFormReleveService,
    OcctaxFormOccurrenceService,
    OcctaxTaxaListService,
    OcctaxFormCountingsService,
    OcctaxFormMapService,
  ],
})
export class OcctaxFormComponent implements OnInit, AfterViewInit, OnDestroy {
  public occtaxConfig = ModuleConfig;
  public id;
  public disableCancel = false;
  public urlSub: Subscription;
  public currentModulePath: string;
  releveUrl: string = null;
  cardHeight: number;
  cardContentHeight: any;

  constructor(
    public dialog: MatDialog,
    private _router: Router,
    public occtaxFormService: OcctaxFormService,
    private _mapService: MapService,
    public occtaxFormParamService: OcctaxFormParamService,
    public occtaxFormReleveService: OcctaxFormReleveService,
    public occtaxFormOccurrenceService: OcctaxFormOccurrenceService,
    public occtaxTaxaListService: OcctaxTaxaListService,
    private _ds: OcctaxDataService,
    private _commonService: CommonService,
    private _modalService: NgbModal,
    public moduleService: ModuleService
  ) {}

  ngOnInit() {
    this.moduleService.currentModule$.subscribe((module) => {
      this.currentModulePath = module.module_path.toLowerCase();
    });

    this.occtaxFormService.idTaxonList = ModuleConfig.id_taxon_list;

    // set id_releve and tab on initalization (refresh page)
    this.setCurrentTabAndIdReleve(this._router.routerState.snapshot.url);
    // set id_releve and tab on tab navigation
    // when come from map list both are trigger. Manage by distinctUntilChanged on getOcctaxData
    this.urlSub = this._router.events
      .pipe(filter((event) => event instanceof NavigationEnd))
      .subscribe((event: any) => {
        this.setCurrentTabAndIdReleve(event.url);
      });
  }

  setCurrentTabAndIdReleve(url) {
    let urlSegments = url.split('/');
    if (urlSegments[urlSegments.length - 1] === 'taxons') {
      const idReleve = urlSegments[urlSegments.length - 2];
      if (idReleve && Number.isInteger(Number(idReleve))) {
        this.occtaxFormService.disabled = false;
        this.occtaxFormService.id_releve_occtax.next(idReleve);
      } else {
        // if no idReleve on taxon tab -> redirect
        this._router.navigate([`${this.currentModulePath}/form/releve`]);
        this.occtaxFormService.id_releve_occtax.next(null);
      }
      this.occtaxFormService.currentTab = <'releve' | 'taxons'>urlSegments.pop();
    } else {
      this.occtaxFormService.currentTab = 'releve';
      const idReleve = urlSegments[urlSegments.length - 1];
      if (idReleve && Number.isInteger(Number(idReleve))) {
        this.occtaxFormService.disabled = false;
        this.occtaxFormService.id_releve_occtax.next(idReleve);
      } else {
        this.occtaxFormService.id_releve_occtax.next(null);
      }
    }
  }
  navigate(tab) {
    const idReleve = this.occtaxFormService.id_releve_occtax.getValue();
    if (tab == 'releve') {
      if (idReleve) {
        this._router.navigate([`${this.currentModulePath}/form/releve/${idReleve}`]);
        this.occtaxFormService.currentTab = 'releve';
      }
    } else {
      this._router.navigate([`${this.currentModulePath}/form/${idReleve}/taxons`]);
      this.occtaxFormService.currentTab = 'taxons';
    }
  }

  ngAfterViewInit() {
    setTimeout(() => this.calcCardContentHeight(), 500);
  }

  @HostListener('window:resize', ['$event'])
  onResize(event) {
    this.calcCardContentHeight();
  }

  calcCardContentHeight() {
    let minusHeight = <HTMLScriptElement>(<any>document.querySelector('pnx-occtax-form .tab'))
      ? (<HTMLScriptElement>(<any>document.querySelector('pnx-occtax-form .tab'))).offsetHeight
      : 0;

    this.cardContentHeight = this._commonService.calcCardContentHeight(minusHeight + 20);

    // resize map after resize container
    if (this._mapService.map) {
      setTimeout(() => {
        this._mapService.map.invalidateSize();
      }, 10);
    }
  }

  openParametersDialog(modalComponent): void {
    this._modalService.open(modalComponent.modalContent, { windowClass: 'large-modal' });
  }
  /**
   *
   * @param cancel : boolean. Action vient du bouton annuler = true, sinon false
   */
  leaveTheForm(cancel) {
    this.occtaxFormService.disabled = true;
    this.disableCancel = true;
    let url;
    if (this.occtaxFormService.chainRecording) {
      url = [`/${this.currentModulePath}/form`];
    } else {
      url = [`/${this.currentModulePath}`];
      this.occtaxFormService.previousReleve = null;
    }

    // si le formulair est en cour d'édition
    if (
      (this.occtaxFormService.currentTab === 'releve' &&
        this.occtaxFormReleveService.releveForm.dirty) ||
      (this.occtaxFormService.currentTab === 'taxons' &&
        this.occtaxFormOccurrenceService.form.dirty)
    ) {
      //si un des 2 formulaires a été modifié mais non sauvegardé
      const message =
        'Êtes-vous sûr de vouloir fermer le formulaire ?<br>Des modifications non sauvegardées seront perdues.';
      const dialogRef = this.dialog.open(ConfirmationDialog, {
        width: 'auto',
        position: { top: '5%' },
        data: { message: message },
      });

      dialogRef.afterClosed().subscribe((result) => {
        if (result) {
          if (this.occtaxFormService.chainRecording) {
            this.occtaxFormService.currentTab = 'releve';
          }
          if (cancel) {
            this.deleteReleveIfNoOcc();
          }
          this._router.navigate(url);
          this.occtaxTaxaListService.cleanOccurrenceInProgress();
        }
      });
    } else {
      if (this.occtaxFormService.chainRecording) {
        this.occtaxFormService.currentTab = 'releve';
      }
      if (cancel) {
        this.deleteReleveIfNoOcc();
      }
      this._router.navigate(url);
      this.occtaxTaxaListService.cleanOccurrenceInProgress();
    }
  }

  /** Action sur le bouton annuler
   * Redirige vers la liste occtax
   * Si aucun taxon saisi, alors on supprime le releve
   */
  deleteReleveIfNoOcc() {
    const occ = this.occtaxTaxaListService.occurrences$.getValue();
    if (occ.length === 0) {
      this._ds
        .deleteReleve(this.occtaxFormService.id_releve_occtax.getValue())
        .subscribe((d) => {});
    }
  }

  ngOnDestroy() {
    this.urlSub.unsubscribe();
  }
}
