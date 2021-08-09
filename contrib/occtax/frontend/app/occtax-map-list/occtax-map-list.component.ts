import {
  Component,
  OnInit,
  OnDestroy,
  AfterViewInit,
  HostListener,
  ViewChild,
  Renderer2,
} from "@angular/core";
import { MapListService } from "@geonature_common/map-list/map-list.service";
import { MapService } from "@geonature_common/map/map.service";
import { OcctaxDataService } from "../services/occtax-data.service";
import { CommonService } from "@geonature_common/service/common.service";
import { NgbModal } from "@ng-bootstrap/ng-bootstrap";
import { DatatableComponent } from "@swimlane/ngx-datatable/release";
import { ModuleConfig } from "../module.config";
import { TaxonomyComponent } from "@geonature_common/form/taxonomy/taxonomy.component";
import { FormGroup } from "@angular/forms";
import { GenericFormGeneratorComponent } from "@geonature_common/form/dynamic-form-generator/dynamic-form-generator.component";
import { AppConfig } from "@geonature_config/app.config";
import { GlobalSubService } from "@geonature/services/global-sub.service";
import { Subscription } from "rxjs/Subscription";
import * as moment from "moment";
import { MediaService } from '@geonature_common/service/media.service';

import { OcctaxFormReleveService } from "../occtax-form/releve/releve.service";
import { OcctaxFormOccurrenceService } from "../occtax-form/occurrence/occurrence.service";
import { OcctaxFormService } from "../occtax-form/occtax-form.service";
import { OcctaxMapListService } from "./occtax-map-list.service";

// /occurrence/occurrence.service";


@Component({
  selector: "pnx-occtax-map-list",
  templateUrl: "occtax-map-list.component.html",
  styleUrls: ["./occtax-map-list.component.scss"],
})
export class OcctaxMapListComponent
  implements OnInit, OnDestroy, AfterViewInit {
  public userCruved: any;
  public displayColumns: Array<any>;
  public availableColumns: Array<any>;
  public pathEdit: string;
  public pathInfo: string;
  public apiEndPoint: string;
  public occtaxConfig: any;
  // public formsDefinition = FILTERSLIST;
  public dynamicFormGroup: FormGroup;
  public formsSelected = [];
  public moduleSub: Subscription;
  public cardContentHeight: number;

  advandedFilterOpen = false;
  @ViewChild(NgbModal)
  public modalCol: NgbModal;
  @ViewChild(TaxonomyComponent)
  public taxonomyComponent: TaxonomyComponent;
  @ViewChild("dynamicForm")
  public dynamicForm: GenericFormGeneratorComponent;
  @ViewChild("table")
  table: DatatableComponent;

  constructor(
    public mapListService: MapListService,
    private _occtaxService: OcctaxDataService,
    private _commonService: CommonService,
    private _mapService: MapService,
    public ngbModal: NgbModal,
    public globalSub: GlobalSubService,
    private renderer: Renderer2,
    public mediaService: MediaService,
    private occtaxMapListS: OcctaxMapListService

  ) { }

  ngOnInit() {
    // set zoom on layer to true
    // zoom only when search data
    this.mapListService.zoomOnLayer = true;
    //config
    this.occtaxConfig = ModuleConfig;
    this.mapListService.idName = "id_releve_occtax";
    this.apiEndPoint = "occtax/releves";
    // refresh forms
    this.refreshForms();
    // get user cruved
    this.moduleSub = this.globalSub.currentModuleSub
      // filter undefined or null
      .filter((mod) => mod)
      .subscribe((mod) => {
        this.userCruved = mod.cruved;
      });

    // parameters for maplist
    // columns to be default displayed
    this.mapListService.displayColumns = this.occtaxConfig.default_maplist_columns;
    // columns available for display
    this.mapListService.availableColumns = this.occtaxConfig.available_maplist_column;

    // FETCH THE DATA
    this.mapListService.refreshUrlQuery();
    this.calculateNbRow();
    this.mapListService.getData(
      this.apiEndPoint,
      [{ param: "limit", value: this.occtaxMapListS.rowPerPage }],
      this.displayLeafletPopupCallback.bind(this) //afin que le this présent dans displayLeafletPopupCallback soit ce component.
    );
    // end OnInit
  }

  ngAfterViewInit() {
    setTimeout(() => this.calcCardContentHeight(), 500);
    if (this._mapService.currentExtend) {
      this._mapService.map.setView(
        this._mapService.currentExtend.center,
        this._mapService.currentExtend.zoom
      )
    }
    this._mapService.removeLayerFeatureGroups(
      [this._mapService.fileLayerFeatureGroup]
    )
  }



  @HostListener("window:resize", ["$event"])
  onResize(event) {
    this.calcCardContentHeight();
  }

  calculateNbRow() {
    let wH = window.innerHeight;
    let listHeight = wH - 64 - 150;
    this.occtaxMapListS.rowPerPage = Math.round(listHeight / 40);
  }

  refreshForms() {
    // when navigate to list refresh services forms
    // this._releveFormService.releveForm.reset();
    // this._releveFormService.previousReleve = null;
    // this._occurrenceFormService.form.reset();
    // this._occtaxFormService.occtaxData.next(null);
  }

  calcCardContentHeight() {
    let wH = window.innerHeight;
    let tbH = document.getElementById("app-toolbar")
      ? document.getElementById("app-toolbar").offsetHeight
      : 0;

    let height = wH - (tbH + 40);

    this.cardContentHeight = height >= 350 ? height : 350;
    // resize map after resize container
    if (this._mapService.map) {
      setTimeout(() => {
        this._mapService.map.invalidateSize();
      }, 10);
    }
  }

  onChangePage(event) {
    this.mapListService.setTablePage(event, this.apiEndPoint);
  }

  onDeleteReleve(id) {
    this._occtaxService.deleteReleve(id).subscribe(
      (data) => {
        this.mapListService.deleteObsFront(id);
        this._commonService.translateToaster(
          "success",
          "Releve.DeleteSuccessfully"
        );
      },
      (error) => {
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
        (c) => {
          return c.prop !== col.prop;
        }
      );
    } else {
      this.mapListService.displayColumns = [
        ...this.mapListService.displayColumns,
        col,
      ];
    }
  }

  openModalCol(event, modal) {
    this.ngbModal.open(modal);
  }

  downloadData(format) {
    // bug d'angular: duplication des clés ...
    //https://github.com/angular/angular/issues/20430
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
    this.mapListService.setHttpParam("orderby", event.column.prop);
    this.mapListService.setHttpParam("order", event.newValue);
    this.mapListService.deleteHttpParam("offset");
    this.mapListService.refreshData(this.apiEndPoint, "set");
  }

  /**
   * Retourne la date en période ou non
   * Sert aussi à la mise en forme du tooltip
   */
  displayDateTooltip(element): string {
    return element.date_min == element.date_max
      ? moment(element.date_min).format("DD-MM-YYYY")
      : `Du ${moment(element.date_min).format("DD-MM-YYYY")} au ${moment(
        element.date_max
      ).format("DD-MM-YYYY")}`;
  }

  /**
   * Retourne un tableau des taxon (nom valide ou nom cité) et icons pour tooltip
   * Sert aussi à la mise en forme du tooltip
   */
  displayTaxonsTooltip(row): any[] {
    let tooltip = [];
    if (row.t_occurrences_occtax && row.t_occurrences_occtax.length == 0) {
      tooltip.push({ taxName: "Aucun taxon" });
    } else {
      for (let i = 0; i < row.t_occurrences_occtax.length; i++) {
        let occ = row.t_occurrences_occtax[i];
        const taxKey = ModuleConfig.DISPLAY_VERNACULAR_NAME ? 'nom_vern': 'nom_complet'
        let taxName;
        if(occ.taxref) {                 
          taxName = occ.taxref[taxKey] ? occ.taxref[taxKey] : occ.taxref.nom_complet;
        }
        let medias = [];
        let icons = '';
        if (occ.cor_counting_occtax) {
          medias = occ.cor_counting_occtax
          .map(c => c.medias)
          .flat()
          .filter(m => !!m);
          icons = medias
            .map(media => this.mediaService.tooltip(media))
            .join(' ');
        }
        tooltip.push({ taxName, icons, medias });
      }
    }
    return tooltip.sort((a, b) => a.taxName < b.taxName ? -1 : 1);
  }

  /**
 * Retourne un tableau des taxon (nom valide ou nom cité)
 */

  displayTaxons(row): string[] {
    return this.displayTaxonsTooltip(row).map(t => " "+t.taxName);
  }

  /**
   * Retourne un tableau des observateurs (prenom nom)
   * Sert aussi à la mise en forme du tooltip
   */
  displayObservateursTooltip(row): string[] {    
    let tooltip = [];    
    if (row.observers && row.observers.length == 0) {      
      if (row.observers_txt !== null && row.observers_txt.trim() !== "") {
        tooltip.push(row.observers_txt.trim());
      } else {
        tooltip.push("Aucun observateurs");
      }
    } else {
      for (let i = 0; i < row.observers.length; i++) {
        let obs = row.observers[i];
        tooltip.push([obs.prenom_role, obs.nom_role].join(" "));
      }
    }

    return tooltip.sort();
  }

  displayLeafletPopupCallback(feature): any {
    const leafletPopup = this.renderer.createElement("div");
    leafletPopup.style.maxHeight = "80vh";
    leafletPopup.style.overflowY = "auto";

    const divObservateurs = this.renderer.createElement("div");
    divObservateurs.innerHTML = this.displayObservateursTooltip(
      feature.properties
    ).join(", ");

    const divDate = this.renderer.createElement("div");
    divDate.innerHTML = this.displayDateTooltip(feature.properties);

    const divTaxons = this.renderer.createElement("div");
    divTaxons.style.marginTop = "5px";
    let taxons = this.displayTaxonsTooltip(feature.properties)
      .map(taxon => `${taxon['taxName']}<br>${taxon['icons']}`)
      .join("<br>");
    divTaxons.innerHTML = taxons;

    this.renderer.appendChild(leafletPopup, divObservateurs);
    this.renderer.appendChild(leafletPopup, divDate);
    this.renderer.appendChild(leafletPopup, divTaxons);

    feature.properties["leaflet_popup"] = leafletPopup;
    return feature;
  }
}
