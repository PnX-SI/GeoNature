import { Component, OnInit, OnDestroy, ViewChild } from "@angular/core";
import { Http } from "@angular/http";
import { GeoJSON } from "leaflet";
import { MapListService } from "@geonature_common/map-list/map-list.service";
import { Subscription } from "rxjs/Subscription";
import { ContactService } from "../services/contact.service";
import { CommonService } from "@geonature_common/service/common.service";
import { TranslateService } from "@ngx-translate/core";
import { Router } from "@angular/router";
import { FormControl } from "@angular/forms";
import { ColumnActions } from "@geonature_common/map-list/map-list.component";
import { NgbModal, ModalDismissReasons } from "@ng-bootstrap/ng-bootstrap";
import { OccTaxConfig } from "../occtax.config";
import { TaxonomyComponent } from "@geonature_common/form/taxonomy/taxonomy.component";
import { DatatableComponent } from "@swimlane/ngx-datatable";
import { FormGroup, FormBuilder } from "@angular/forms";

@Component({
  selector: "pnx-contact-map-list",
  templateUrl: "contact-map-list.component.html",
  styleUrls: ["./contact-map-list.component.scss"],
  providers: [MapListService]
})
export class ContactMapListComponent implements OnInit {
  public displayColumns: Array<any>;
  public availableColumns: Array<any>;
  public filterableColumns: Array<any>;
  public pathEdit: string;
  public pathInfo: string;
  public idName: string;
  public apiEndPoint: string;
  public inputTaxon = new FormControl();
  public inputObservers = new FormControl();
  public dateMinInput = new FormControl();
  public dateMaxInput = new FormControl();
  public observerAsTextInput = new FormControl();
  public datasetInput = new FormControl();
  public nomenclatureForm: FormGroup;
  public columnActions: ColumnActions;
  public occtaxConfig: any;

  // provisoire
  public tableMessages = {
    emptyMessage: "Aucune observation à afficher",
    totalMessage: "observation(s) au total"
  };
  @ViewChild(NgbModal) public modalCol: NgbModal;
  @ViewChild(TaxonomyComponent) public taxonomyComponent: TaxonomyComponent;
  constructor(
    private _http: Http,
    private mapListService: MapListService,
    private _contactService: ContactService,
    private _commonService: CommonService,
    private _translate: TranslateService,
    private _router: Router,
    public ngbModal: NgbModal,
    private _fb: FormBuilder
  ) {}

  ngOnInit() {
    this.occtaxConfig = OccTaxConfig;

    // parameters for maplist
    // columns to be default displayed
    this.displayColumns = OccTaxConfig.default_maplist_columns;
    this.mapListService.displayColumns = this.displayColumns;

    // columns available for display
    this.availableColumns = [
      { prop: "altitude_max", name: "altitude_max" },
      { prop: "altitude_min", name: "altitude_min" },
      { prop: "comment", name: "Commentaire" },
      { prop: "date_max", name: "Date fin" },
      { prop: "date_min", name: "Date début" },
      { prop: "id_dataset", name: "ID dataset" },
      { prop: "id_digitiser", name: "ID rédacteur" },
      { prop: "id_releve_contact", name: "ID relevé" },
      { prop: "observateurs", name: "observateurs" },
      { prop: "taxons", name: "taxons" }
    ];
    this.mapListService.availableColumns = this.availableColumns;
    // column available to filter
    this.filterableColumns = [
      { prop: "altitude_max", name: "altitude_max" },
      { prop: "altitude_min", name: "altitude_min" },
      { prop: "comment", name: "Commentaire" },
      { prop: "id_dataset", name: "ID dataset" },
      { prop: "id_digitiser", name: "Id rédacteur" },
      { prop: "id_releve_contact", name: "Id relevé" }
    ];
    this.mapListService.filterableColumns = this.filterableColumns;
    this.idName = "id_releve_contact";
    this.apiEndPoint = "occtax/vreleve";

    this.nomenclatureForm = this._fb.group({
      // releve
      id_nomenclature_obs_technique: null,
      id_nomenclature_grp_typ: null,
      // occurrence

      id_nomenclature_obs_meth: null,
      id_nomenclature_bio_condition: null,
      id_nomenclature_naturalness: null,
      id_nomenclature_exist_proof: null,
      id_nomenclature_bio_status: null,
      id_nomenclature_observation_status: null,
      id_nomenclature_diffusion_level: null,
      id_nomenclature_blurring: null,
      id_nomenclature_determination_method: null,
      // counting
      id_nomenclature_life_stage: null,
      id_nomenclature_sex: null,
      id_nomenclature_obj_count: null,
      id_nomenclature_type_count: null,
      id_nomenclature_valid_status: null
    });

    // FETCH THE DATA
    this.mapListService.getData(
      "occtax/vreleve",
      [{ param: "limit", value: 12 }],
      this.customColumns
    );
    // end OnInit
  }

  searchData() {
    const params = [];
    for (let key in this.nomenclatureForm.value) {
      if (this.nomenclatureForm.value[key]) {
        params.push({ param: key, value: this.nomenclatureForm.value[key] });
      }
    }
    console.log(params);

    this.mapListService.refreshData(this.apiEndPoint, "set", params);
  }

  taxonChanged(taxonObj) {
    this.mapListService.refreshData(this.apiEndPoint, "set", [
      { param: "cd_nom", value: taxonObj.cd_nom }
    ]);
  }

  observerChanged(observer) {
    this.mapListService.refreshData(this.apiEndPoint, "append", [
      { param: "observer", value: observer.id_role }
    ]);
  }

  observerDeleted(observer) {
    const idObservers = this.mapListService.urlQuery.getAll("observer");
    this.mapListService.urlQuery = this.mapListService.urlQuery.delete(
      "observer"
    );
    idObservers.forEach(id => {
      if (id !== observer.id_role) {
        this.mapListService.urlQuery = this.mapListService.urlQuery.append(
          "observer",
          id
        );
      }
    });
    this.mapListService.refreshData(this.apiEndPoint, "set");
  }

  observerTextChange(observer) {
    this.mapListService.refreshData(this.apiEndPoint, "set", [
      { param: "observateurs", value: observer }
    ]);
  }

  observerTextDelete() {
    this.mapListService.deleteAndRefresh(this.apiEndPoint, "observateurs");
  }

  onDataSetChange(id_dataset) {
    this.mapListService.refreshData(this.apiEndPoint, "set", [
      { param: "id_dataset", value: id_dataset }
    ]);
  }

  onDataSetDelete() {
    this.mapListService.deleteAndRefresh(this.apiEndPoint, "id_dataset");
  }

  dateMinChanged(date) {
    this.mapListService.urlQuery = this.mapListService.urlQuery.delete(
      "date_up"
    );
    if (date.length > 0) {
      this.mapListService.refreshData(this.apiEndPoint, "set", [
        { param: "date_up", value: date }
      ]);
    } else {
      this.mapListService.deleteAndRefresh(this.apiEndPoint, "date_up");
    }
  }
  dateMaxChanged(date) {
    this.mapListService.urlQuery = this.mapListService.urlQuery.delete(
      "date_low"
    );
    if (date.length > 0) {
      this.mapListService.refreshData(this.apiEndPoint, "set", [
        { param: "date_low", value: date }
      ]);
    } else {
      this.mapListService.deleteAndRefresh(this.apiEndPoint, "date_low");
    }
  }

  onEditReleve(id_releve) {
    this._router.navigate(["occtax/form", id_releve]);
  }

  onDetailReleve(id_releve) {
    this._router.navigate(["occtax/info", id_releve]);
  }

  onDeleteReleve(id) {
    this._contactService.deleteReleve(id).subscribe(
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
    this.dateMaxInput.reset();
    this.dateMinInput.reset();
    if (OccTaxConfig.observers_txt) {
      this.observerAsTextInput.reset();
    } else {
      this.inputObservers.reset();
    }
    this.datasetInput.reset();
    this.mapListService.genericFilterInput.reset();
    this.mapListService.refreshUrlQuery(12);
    this.mapListService.refreshData(this.apiEndPoint, "set");
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
