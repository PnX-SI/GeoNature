import { MapListService } from "@geonature_common/map-list/map-list.service";
import {
  Component,
  OnInit,
  Input,
  Output,
  ViewChild,
  HostListener,
  AfterContentChecked,
  OnChanges,
  ChangeDetectorRef
} from "@angular/core";

import { GeoJSON, FeatureGroup, Marker } from "leaflet";

import { MapService } from "@geonature_common/map/map.service";
import { DataService } from "../../services/data.service";
import { NgbModal } from "@ng-bootstrap/ng-bootstrap";
import { CommonService } from "@geonature_common/service/common.service";
import { ModuleConfig } from "../../module.config";
import { DomSanitizer } from "@angular/platform-browser";
import { DatatableComponent } from "@swimlane/ngx-datatable";
import { ValidationModalInfoObsComponent } from "../validation-modal-info-obs/validation-modal-info-obs.component";
import { FormService } from "../../services/form.service";
import { ToastrService } from "ngx-toastr";

@Component({
  selector: "pnx-validation-synthese-list",
  templateUrl: "validation-synthese-list.component.html",
  styleUrls: ["validation-synthese-list.component.scss"]
})
export class ValidationSyntheseListComponent
  implements OnInit, OnChanges, AfterContentChecked {
  public VALIDATION_CONFIG = ModuleConfig;
  selectedObs: Array<number> = []; // list of id_synthese values for selected rows
  selectedIndex: Array<number> = [];
  selectedPages = [];
  coordinates_list = []; // list of coordinates for selected rows
  group: FeatureGroup;
  marker: MediaTrackSupportedConstraints;
  public rowNumber: number;
  private _latestWidth: number;
  public id_same_coordinates = []; // list of observation ids having same geographic coordinates
  public validationStatus;
  public modif_text =
    "Attention données modifiées depuis la dernière validation";
  public npage;

  @Input() inputSyntheseData: GeoJSON;
  @Input() statusNames: any;
  @Input() statusKeys: any;
  @ViewChild("table") table: DatatableComponent;
  @Output() pageChange: EventEmitter<number>;

  constructor(
    public mapListService: MapListService,
    private _ds: DataService,
    public ngbModal: NgbModal,
    private _commonService: CommonService,
    //private _fs: SyntheseFormService,
    public sanitizer: DomSanitizer,
    public ref: ChangeDetectorRef,
    private _ms: MapService,
    public formService: FormService,
    private toastr: ToastrService
  ) {}

  ngOnInit() {
    //console.log(this.VALIDATION_CONFIG.STATUS_INFO[318].color);
    // get wiewport height to set the number of rows in the tabl
    const h = document.documentElement.clientHeight;
    this.rowNumber = Math.trunc(h / 37);

    this.group = new FeatureGroup();
    this.onMapClick();
    this.onTableClick();
    //console.log(this.mapListService.tableData);
    this.npage = 1;
  }

  onMapClick() {
    this.mapListService.onMapClik$.subscribe(id => {
      // create list of observation ids having coordinates = to id value
      const selected_id_coordinates = this.mapListService.layerDict[id].feature
        .geometry.coordinates;
      this.id_same_coordinates = [];
      for (let obs in this.mapListService.geojsonData.features) {
        if (
          JSON.stringify(selected_id_coordinates) ==
          JSON.stringify(
            this.mapListService.geojsonData.features[obs].geometry.coordinates
          )
        ) {
          this.id_same_coordinates.push(
            parseInt(this.mapListService.geojsonData.features[obs].id)
          );
        }
      }

      // select rows having id_synthese = to one of the id_same_coordinates values
      this.mapListService.selectedRow = [];
      for (let id of this.id_same_coordinates) {
        for (let i = 0; i < this.mapListService.tableData.length; i++) {
          if (this.mapListService.tableData[i]["id_synthese"] === id) {
            this.mapListService.selectedRow.push(
              this.mapListService.tableData[i]
            );
          }
        }
      }
      this.setSelectedObs();
    });
  }

  getStatusNames() {
    this._ds.getStatusNames().subscribe(
      result => {
        // get status names
        this.statusNames = result;
        this.statusKeys = Object.keys(this.VALIDATION_CONFIG.STATUS_INFO);
      },
      err => {
        if (err.statusText === "Unknown Error") {
          // show error message if no connexion
          this.toastr.error(
            "ERROR: IMPOSSIBLE TO CONNECT TO SERVER (check your connexion)"
          );
        } else {
          // show error message if other server error
          this.toastr.error(err.error);
        }
      },
      () => {
        this.deselectAll();
      }
    );
  }

  onTableClick() {
    this.setSelectedObs();
    this.mapListService.onTableClick$.subscribe(id => {
      this.setSelectedObs();
      this.setOriginStyleToAll();
      this.setSelectedSyleToSelectedRows();
    });
  }

  ngAfterContentChecked() {
    if (this.table && this.table.element.clientWidth !== this._latestWidth) {
      this._latestWidth = this.table.element.clientWidth;
    }
  }

  handlePageChange(event): void {
    this.npage = event.page;
  }

  setOriginStyleToAll() {
    for (let obs in this.mapListService.layerDict) {
      this.mapListService.layerDict[obs].setStyle(
        this.VALIDATION_CONFIG.MAP_POINT_STYLE.originStyle
      );
    }
  }

  setSelectedSyleToSelectedRows() {
    for (let obs of this.selectedObs) {
      this.mapListService.layerDict[obs].setStyle(
        this.VALIDATION_CONFIG.MAP_POINT_STYLE.selectedStyle
      );
    }
  }

  selectAll() {
    this.mapListService.selectedRow = [...this.mapListService.tableData];
    this.setSelectedObs();
    this.viewFitList(this.selectedObs);
    this.setSelectedSyleToSelectedRows();
  }

  deselectAll() {
    this.mapListService.selectedRow = [];
    this.setSelectedObs();
    if (this.mapListService.selectedRow.length === 0) {
      this.setOriginStyleToAll();
    }
  }

  onActivate(event) {
    if (event.type == "checkbox" || event.type == "click") {
      this.setSelectedObs();
      this.viewFitList(this.selectedObs);
      if (this.mapListService.selectedRow.length === 0) {
        this.setOriginStyleToAll();
      }
    }
  }

  viewFitList(id_observations) {
    console.log(id_observations);
    // create an empty featre group
    // and fill it with the selected layer to get bounds
    this.group = new FeatureGroup();
    id_observations.forEach(id_obs => {
      this.group.addLayer(this.mapListService.layerDict[id_obs]);
    });
    this._ms.getMap().fitBounds(this.group.getBounds());
  }

  setSelectedObs() {
    // array of id_sythese values of selected observations
    this.selectedObs = [];
    this.selectedIndex = [];
    this.selectedPages = [];
    if (this.mapListService.selectedRow.length === 0) {
      this.selectedObs = [];
    } else {
      for (let obs in this.mapListService.selectedRow) {
        this.selectedObs.push(
          this.mapListService.selectedRow[obs]["id_synthese"]
        );
      }
    }

    for (let obs of this.selectedObs) {
      // find position of selected observations in the ngxtable from id_synthese of selected observations
      this.selectedIndex.push(
        this.mapListService.tableData.findIndex(i => i.id_synthese === obs)
      );
    }

    // find page from an ngxindex
    for (let ind of this.selectedIndex) {
      let PageIndex = (ind + 1) / this.table._limit;
      this.selectedPages.push(Math.ceil(PageIndex));
    }
  }

  onStatusChange(status) {
    //console.log('status change : ' + status);
    for (let obs in this.mapListService.selectedRow) {
      this.mapListService.selectedRow[obs][
        "id_nomenclature_valid_status"
      ] = status;
      this.mapListService.selectedRow[obs]["validation_auto"] = "";
    }
    this.mapListService.selectedRow = [...this.mapListService.selectedRow];
  }

  onValidationDateChange(date) {
    for (let obs in this.mapListService.selectedRow) {
      this.mapListService.selectedRow[obs]["validation_date"] = date;
    }
    this.mapListService.selectedRow = [...this.mapListService.selectedRow];
  }

  // update the number of row per page when resize the window
  @HostListener("window:resize", ["$event"])
  onResize(event) {
    this.rowNumber = Math.trunc(event.target.innerHeight / 37);
  }

  backToModule(url_source, id_pk_source) {
    const link = document.createElement("a");
    link.target = "_blank";
    link.href = url_source + "/" + id_pk_source;
    link.setAttribute("visibility", "hidden");
    document.body.appendChild(link);
    link.click();
    link.remove();
  }

  getRowClass() {
    return "row-sm clickable";
  }

  ngOnChanges(changes) {
    if (changes.inputSyntheseData && changes.inputSyntheseData.currentValue) {
      // reset page 0 when new data appear
      this.table.offset = 0;
    }
    this.statusNames = [];
    this.getStatusNames();
  }

  openInfoModal(row) {
    const modalRef = this.ngbModal.open(ValidationModalInfoObsComponent, {
      size: "lg",
      windowClass: "large-modal"
    });
    modalRef.componentInstance.oneObsSynthese = row;
    modalRef.componentInstance.statusNames = this.statusNames;
    modalRef.componentInstance.mapListService = this.mapListService;
    modalRef.componentInstance.modifiedStatus.subscribe(modifiedStatus => {
      for (let obs in this.mapListService.tableData) {
        if (
          this.mapListService.tableData[obs].id_synthese ==
          modifiedStatus.id_synthese
        ) {
          this.mapListService.tableData[obs].id_nomenclature_valid_status =
            modifiedStatus.new_status;
          this.mapListService.tableData[obs].validation_auto = "";
        }
      }
    });
    modalRef.componentInstance.valDate.subscribe(data => {
      for (let obs in this.mapListService.selectedRow) {
        this.mapListService.selectedRow[obs]["validation_date"] = data;
      }
      this.mapListService.selectedRow = [...this.mapListService.selectedRow];
    });
  }
}
