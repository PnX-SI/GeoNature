import { Component, OnInit, OnDestroy, ViewChild } from "@angular/core";
import { Http } from "@angular/http";
import { GeoJSON } from "leaflet";
import { MapListService } from "@geonature_common/map-list/map-list.service";
import { Subscription } from "rxjs/Subscription";
import { OcctaxService } from "../services/occtax.service";
import { CommonService } from "@geonature_common/service/common.service";
import { TranslateService } from "@ngx-translate/core";
import { Router } from "@angular/router";
import { FormControl } from "@angular/forms";
import { NgbModal, ModalDismissReasons } from "@ng-bootstrap/ng-bootstrap";
import { ModuleConfig } from "../module.config";
import { TaxonomyComponent } from "@geonature_common/form/taxonomy/taxonomy.component";
import { DatatableComponent } from "@swimlane/ngx-datatable";
import { FormGroup, FormBuilder } from "@angular/forms";
import { DynamicFormComponent } from "@geonature_common/form/dynamic-form/dynamic-form.component";
import { DynamicFormService } from "@geonature_common/form/dynamic-form/dynamic-form.service";
import { NgbDateParserFormatter } from "@ng-bootstrap/ng-bootstrap";
import { FILTERSLIST } from "./filters-list";
import { AppConfig } from "@geonature_config/app.config";

@Component({
  selector: "pnx-occtax-map-list",
  templateUrl: "occtax-map-list.component.html",
  styleUrls: ["./occtax-map-list.component.scss"],
  providers: [MapListService]
})
export class OcctaxMapListComponent implements OnInit {
  public displayColumns: Array<any>;
  public availableColumns: Array<any>;
  public pathEdit: string;
  public pathInfo: string;
  public idName: string;
  public apiEndPoint: string;
  public occtaxConfig: any;
  public formsDefinition = FILTERSLIST;
  public dynamicFormGroup: FormGroup;
  public filterControl = new FormControl();
  public formsSelected = [];
  // provisoire
  public tableMessages = {
    emptyMessage: "Aucune observation à afficher",
    totalMessage: "observation(s) au total"
  };
  advandedFilterOpen = false;
  @ViewChild(NgbModal) public modalCol: NgbModal;
  @ViewChild(TaxonomyComponent) public taxonomyComponent: TaxonomyComponent;
  constructor(
    private _http: Http,
    private mapListService: MapListService,
    private _occtaxService: OcctaxService,
    private _commonService: CommonService,
    private _translate: TranslateService,
    private _router: Router,
    public ngbModal: NgbModal,
    private _fb: FormBuilder,
    private _dynformService: DynamicFormService,
    private _dateParser: NgbDateParserFormatter
  ) {}

  ngOnInit() {
    this.dynamicFormGroup = this._fb.group({
      cd_nom: null,
      observers: null,
      dataset: null,
      observers_txt: null,
      id_dataset: null,
      date_up: null,
      date_low: null,
      municipality: null
    });

    this.filterControl.valueChanges
      .filter(value => value !== null)
      .subscribe(formDef => {
        this.addFormControl(formDef);
      });

    this.occtaxConfig = ModuleConfig;

    // parameters for maplist
    // columns to be default displayed
    this.displayColumns = ModuleConfig.default_maplist_columns;
    this.mapListService.displayColumns = this.displayColumns;

    // columns available for display

    this.mapListService.availableColumns = this.occtaxConfig.available_maplist_column;

    this.idName = "id_releve_occtax";
    this.apiEndPoint = "occtax/vreleve";

    // FETCH THE DATA
    this.mapListService.getData(
      "occtax/vreleve",
      [{ param: "limit", value: 12 }],
      this.customColumns
    );
    // end OnInit
  }

  addFormControl(formDef) {
    this.formsSelected.push(formDef);
    this.formsDefinition = this.formsDefinition.filter(form => {
      return form.key != formDef.key;
    });
    this._dynformService.addNewControl(formDef, this.dynamicFormGroup);
  }

  removeFormControl(i) {
    const formDef = this.formsSelected[i];
    this.formsSelected.splice(i, 1);
    this.formsDefinition.push(formDef);
    this.dynamicFormGroup.removeControl(formDef.key);
    this.filterControl.setValue(null);
  }

  toggleAdvancedFilters() {
    this.advandedFilterOpen = !this.advandedFilterOpen;
  }

  closeAdvancedFilters() {
    this.advandedFilterOpen = false;
  }

  searchData() {
    this.mapListService.refreshUrlQuery(12);
    const params = [];
    for (let key in this.dynamicFormGroup.value) {
      let value = this.dynamicFormGroup.value[key];
      if (key === "cd_nom" && value) {
        value = this.dynamicFormGroup.value[key].cd_nom;
        params.push({ param: key, value: value });
      } else if ((key === "date_up" || key === "date_low") && value) {
        value = this._dateParser.format(this.dynamicFormGroup.value[key]);
        params.push({ param: key, value: value });
      } else if (key === "observers" && value) {
        this.dynamicFormGroup.value.observers.forEach(observer => {
          params.push({ param: "observers", value: observer.id_role });
        });
      } else if (value && value !== "") {
        params.push({ param: key, value: value });
      }
    }
    this.closeAdvancedFilters();
    this.mapListService.refreshData(this.apiEndPoint, "set", params);
  }

  onEditReleve(id_releve) {
    this._router.navigate(["occtax/form", id_releve]);
  }

  onDetailReleve(id_releve) {
    this._router.navigate(["occtax/info", id_releve]);
  }

  onDeleteReleve(id) {
    this._occtaxService.deleteReleve(id).subscribe(
      data => {
        this.deleteObsFront(id);
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

  deleteObsFront(idDelete) {
    this.mapListService.tableData = this.mapListService.tableData.filter(
      row => {
        return row[this.idName] !== idDelete;
      }
    );

    this.mapListService.geojsonData.features = this.mapListService.geojsonData.features.filter(
      row => {
        return row.properties[this.idName] !== idDelete;
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

  onAddReleve() {
    this._router.navigate(["occtax/form"]);
  }

  customColumns(feature) {
    // function pass to the getData and the maplist service to format date
    // on the table
    // must return a feature
    const date_min = new Date(feature.properties.date_min);
    const date_max = new Date(feature.properties.date_max);
    feature.properties.date_min = date_min.toLocaleDateString("fr-FR");
    feature.properties.date_max = date_max.toLocaleDateString("fr-FR");
    return feature;
  }
  refreshFilters() {
    this.taxonomyComponent.refreshAllInput();
    this.dynamicFormGroup.reset();
    this.mapListService.refreshUrlQuery(12);
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
    const url = `${
      AppConfig.API_ENDPOINT
    }/occtax/export?${this.mapListService.urlQuery.toString()}&format=${format}`;

    document.location.href = url;
  }

  onChangeFilterOps(col) {
    // reset url query
    this.mapListService.urlQuery.delete(this.mapListService.colSelected.prop);
    this.mapListService.colSelected = col; // change filter selected
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
}
