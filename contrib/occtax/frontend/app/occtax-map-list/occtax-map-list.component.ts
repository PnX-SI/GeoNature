import { Component, OnInit, OnDestroy, ViewChild } from "@angular/core";
import { MapListService } from "@geonature_common/map-list/map-list.service";
import { OcctaxDataService } from "../services/occtax-data.service";
import { CommonService } from "@geonature_common/service/common.service";
import { Router } from "@angular/router";
import { NgbModal } from "@ng-bootstrap/ng-bootstrap";
import { ModuleConfig } from "../module.config";
import { TaxonomyComponent } from "@geonature_common/form/taxonomy/taxonomy.component";
import { FormGroup, FormBuilder } from "@angular/forms";
import { GenericFormGeneratorComponent } from "@geonature_common/form/dynamic-form-generator/dynamic-form-generator.component";
import { AppConfig } from "@geonature_config/app.config";
import { GlobalSubService } from "@geonature/services/global-sub.service";
import { Subscription } from "rxjs/Subscription";
import { HttpParams } from '@angular/common/http';

@Component({
  selector: "pnx-occtax-map-list",
  templateUrl: "occtax-map-list.component.html",
  styleUrls: ["./occtax-map-list.component.scss"]
})
export class OcctaxMapListComponent implements OnInit, OnDestroy {
  public userCruved = {};
  public displayColumns: Array<any>;
  public availableColumns: Array<any>;
  public pathEdit: string;
  public pathInfo: string;
  public idName: string;
  public apiEndPoint: string;
  public occtaxConfig: any;
  // public formsDefinition = FILTERSLIST;
  public dynamicFormGroup: FormGroup;
  public formsSelected = [];
  public moduleSub: Subscription;

  advandedFilterOpen = false;
  @ViewChild(NgbModal)
  public modalCol: NgbModal;
  @ViewChild(TaxonomyComponent)
  public taxonomyComponent: TaxonomyComponent;
  @ViewChild("dynamicForm")
  public dynamicForm: GenericFormGeneratorComponent;
  @ViewChild('table') table: any;

  constructor(
    private mapListService: MapListService,
    private _occtaxService: OcctaxDataService,
    private _commonService: CommonService,
    private _router: Router,
    public ngbModal: NgbModal,
    public globalSub: GlobalSubService
  ) {}

  ngOnInit() {
    //config
    this.occtaxConfig = ModuleConfig;
    this.idName = "id_releve_occtax";
    this.apiEndPoint = "occtax/releves";

    // get user cruved
    this.moduleSub = this.globalSub.currentModuleSub
      // filter undefined or null
      .filter(mod => mod)
      .subscribe(mod => {
        this.userCruved = mod.cruved;
      });

    // parameters for maplist
    // columns to be default displayed
    this.mapListService.displayColumns = this.occtaxConfig.default_maplist_columns;
    // columns available for display
    this.mapListService.availableColumns = this.occtaxConfig.available_maplist_column;

    this.mapListService.idName = this.idName;

    // FETCH THE DATA
    this.mapListService.getData(
      this.apiEndPoint,
      [{ param: "limit", value: 12 }]
    );
    // end OnInit
  }

  onChangePage(event) {
    this.mapListService.setTablePage(event, this.apiEndPoint);
  }

  onDeleteReleve(id) {
    this._occtaxService.deleteReleve(id).subscribe(
      data => {
        this.mapListService.deleteObsFront(id);
        this._commonService.translateToaster(
          "success",
          "Releve.DeleteSuccessfully"
        );
      },
      error => {
        if (error.status === 403) {
          this._commonService.translateToaster("error", "NotAllowed");
        } else {
          this._commonService.translateToaster("error", "ErrorMessage");
        }
      }
    );
  }

  openDeleteModal(event, modal, iElement, row) {
    this.mapListService.urlQuery;
    this.mapListService.selectedRow = [];
    this.mapListService.selectedRow.push(row);
    event.stopPropagation();
    // prevent erreur link to the component
    iElement &&
      iElement.parentElement &&
      iElement.parentElement.parentElement &&
      iElement.parentElement.parentElement.blur();
    this.ngbModal.open(modal);
  }

  openModalDownload(event, modal) {
    this.ngbModal.open(modal, { size: "lg" });
  }

  toggle(col) {
    const isChecked = this.isChecked(col);
    if (isChecked) {
      this.mapListService.displayColumns = this.mapListService.displayColumns.filter(
        c => {
          return c.prop !== col.prop;
        }
      );
    } else {
      this.mapListService.displayColumns = [
        ...this.mapListService.displayColumns,
        col
      ];
    }
  }

  openModalCol(event, modal) {
    this.ngbModal.open(modal);
  }

  downloadData(format) {
    let queryString = this.mapListService.urlQuery.delete("limit");
    queryString = queryString.delete("offset");
    const url = `${
      AppConfig.API_ENDPOINT
    }/occtax/export?${queryString.toString()}&format=${format}`;

    document.location.href = url;
  }

  isChecked(col) {
    let i = 0;
    while (
      i < this.mapListService.displayColumns.length &&
      this.mapListService.displayColumns[i].prop !== col.prop
    ) {
      i = i + 1;
    }
    return i === this.mapListService.displayColumns.length ? false : true;
  }

  ngOnDestroy() {
    this.moduleSub.unsubscribe();
  }

  toggleExpandRow(row) {
    this.table.rowDetail.toggleExpandRow(row);
  }

  onColumnSort(event) {
    this.mapListService.setHttpParam('orderby', event.column.prop);
    this.mapListService.setHttpParam('order', event.newValue);
    this.mapListService.deleteHttpParam('offset');
    this.mapListService.refreshData(this.apiEndPoint, 'set');
  }

  /**
  * Retourne un tableau des taxon (nom valide ou nom cité)
  * Sert aussi à la mise en forme du tooltip
  */
  displayTaxonsTooltip(row): string[] {
    let tooltip = [];
    if (row.t_occurrences_occtax === undefined) {
      tooltip.push('Aucun taxon');
    }

    for (let i=0; i<row.t_occurrences_occtax.length; i++) {
      let occ = row.t_occurrences_occtax[i];
      if ( occ.taxref !== undefined ) {
        tooltip.push(occ.taxref.nom_complet);
      } else {
        tooltip.push(occ.nom_cite);
      }
    }

    return tooltip.sort();
  }

  /**
  * Retourne un tableau des observateurs (prenom nom)
  * Sert aussi à la mise en forme du tooltip
  */
  displayObservateursTooltip(row): string[] {
    let tooltip = [];
    if (row.observers === undefined) {
      if(row.observers_txt !== null && row.observers_txt.trim() !== '') {
        tooltip.push(row.observers_txt.trim());
      } else {
        tooltip.push('Aucun observateurs');
      }
    }

    for (let i=0; i<row.observers.length; i++) {
      let obs = row.observers[i];
      tooltip.push([obs.prenom_role, obs.nom_role].join(' '));
    }

    return tooltip.sort();
  }
}
