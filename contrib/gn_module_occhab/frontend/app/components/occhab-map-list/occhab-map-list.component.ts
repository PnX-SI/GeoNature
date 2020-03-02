import { Component, OnInit, ViewChild, HostListener } from "@angular/core";
import { OcchabStoreService } from "../../services/store.service";
import { MapListService } from "@geonature_common/map-list/map-list.service";
import { OccHabDataService } from "../../services/data.service";
import { DatatableComponent } from "@swimlane/ngx-datatable/release";
import { OccHabModalDownloadComponent } from "./modal-download.component";
import { NgbModal, NgbActiveModal } from "@ng-bootstrap/ng-bootstrap";
import { CommonService } from "@geonature_common/service/common.service";
import * as moment from "moment";
import { ModuleConfig } from "../../../../../../external_modules/occhab/frontend/app/module.config";

@Component({
  selector: "pnx-occhab-map-list",
  templateUrl: "occhab-map-list.component.html",
  styleUrls: ["./occhab-map-list.component.scss", "../responsive-map.scss"],
  providers: [NgbActiveModal]
})
export class OccHabMapListComponent implements OnInit {
  public displayedColumns = [
    { name: "Date", prop: "date_min", width: "100" },
    { name: "Habitats", prop: "habitats", width: "300" },
    { name: "Jeu de données", prop: "dataset_name", width: "200" }
  ];
  @ViewChild("dataTable") dataTable: DatatableComponent;
  public rowNumber: number;
  public dataLoading = true;
  public deleteOne: any;
  constructor(
    public storeService: OcchabStoreService,
    private _occHabDataService: OccHabDataService,
    public mapListService: MapListService,
    private _ngbModal: NgbModal,
    private _commonService: CommonService
  ) {}
  ngOnInit() {
    if (this.storeService.firstMessageMapList) {
      this._commonService.regularToaster(
        "info",
        "Les 50 dernières stations saisies"
      );
      this.storeService.firstMessageMapList = false;
    }

    this.getStations({ limit: 50 });
    // get wiewport height to set the number of rows in the tabl
    const h = document.documentElement.clientHeight;

    this.rowNumber = this.calculeteRowNumber(h);
    // observable on mapListService.currentIndexRow to find the current page
    this.mapListService.currentIndexRow$.subscribe(indexRow => {
      const currentPage = Math.trunc(indexRow / this.rowNumber);
      this.dataTable.offset = currentPage;
    });
  }

  /** Calculate the number of row with the client screen height */
  calculeteRowNumber(screenHeight: number): number {
    //if(scr)
    if (screenHeight > 1000) {
      return Math.trunc(screenHeight / 52);
    } else if (screenHeight > 800) {
      return Math.trunc(screenHeight / 55);
    } else if (screenHeight <= 800) {
      return Math.trunc(screenHeight / 62);
    }
  }

  // update the number of row per page when resize the window
  @HostListener("window:resize", ["$event"])
  onResize(event) {
    this.rowNumber = this.calculeteRowNumber(event.target.innerHeight);
  }

  getStations(params?) {
    this.dataLoading = true;
    this._occHabDataService.getStations(params).subscribe(
      featuresCollection => {
        // store the idsStation in the store service
        if (
          featuresCollection.features.length === ModuleConfig.NB_MAX_MAP_LIST
        ) {
          this.openModal(true);
        }
        this.storeService.idsStation = featuresCollection.features.map(
          feature => feature.id
        );
        // this.stations = data;
        this.mapListService.tableData = [];
        featuresCollection.features.forEach(feature => {
          // add leaflet popup
          this.displayLeafletPopupCallback(feature);
          // push the data in the dataTable array
          this.mapListService.tableData.push(feature.properties);
        });
        this.mapListService.geojsonData = featuresCollection;
        this.dataLoading = false;
      },
      // error callback
      e => {
        if (e.status == 500) {
          this._commonService.translateToaster("error", "ErrorMessage");
        }
        this.dataLoading = false;
      }
    );
  }

  searchData(params) {
    this.getStations(params);
  }

  openModal(tooManyObs = false) {
    const ref = this._ngbModal.open(OccHabModalDownloadComponent, {
      size: "lg"
    });
    ref.componentInstance.tooManyObs = tooManyObs;
  }

  toggleExpandRow(row) {
    this.dataTable.rowDetail.toggleExpandRow(row);
  }

  displayHabTooltip(row): string[] {
    let tooltip = [];
    if (row.t_habitats === undefined) {
      tooltip.push("Aucun habitat");
    } else {
      for (let i = 0; i < row.t_habitats.length; i++) {
        let occ = row.t_habitats[i];
        tooltip.push(occ.nom_cite);
      }
    }
    return tooltip.sort();
  }

  displayObservateursTooltip(row): string[] {
    let tooltip = [];
    if (row.observers === undefined) {
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

  displayDateTooltip(element): string {
    return element.date_min == element.date_max
      ? moment(element.date_min).format("DD-MM-YYYY")
      : `Du ${moment(element.date_min).format("DD-MM-YYYY")} au ${moment(
          element.date_max
        ).format("DD-MM-YYYY")}`;
  }

  displayLeafletPopupCallback(feature): any {
    const leafletPopup: HTMLElement = document.createElement("div");
    leafletPopup.style.maxHeight = "80vh";
    leafletPopup.style.overflowY = "auto";

    const divObservateurs = document.createElement("div");
    divObservateurs.innerHTML = "<b> Observateurs : </b> <br>";
    divObservateurs.innerHTML =
      divObservateurs.innerHTML +
      this.displayObservateursTooltip(feature.properties).join(", ");

    const divDate = document.createElement("div");
    divDate.innerHTML = "<b> Date : </b> <br>";
    divDate.innerHTML =
      divDate.innerHTML + this.displayDateTooltip(feature.properties);

    const divHab = document.createElement("div");
    divHab.innerHTML = "<b> Habitats : </b> <br>";

    divHab.style.marginTop = "5px";
    let taxons = this.displayHabTooltip(feature.properties).join("<br>");
    divHab.innerHTML = divHab.innerHTML + taxons;

    leafletPopup.appendChild(divObservateurs);
    leafletPopup.appendChild(divDate);
    leafletPopup.appendChild(divHab);

    feature.properties["leaflet_popup"] = leafletPopup;
    return feature;
  }

  openDeleteModal(station, deleteModal) {
    this.deleteOne = station;
    this._ngbModal.open(deleteModal);
  }
}
