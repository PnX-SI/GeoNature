import { Component, OnInit, ViewChild } from "@angular/core";
import { OcchabStoreService } from "../services/store.service";
import { MapListService } from "@geonature_common/map-list/map-list.service";
import { OccHabDataService } from "../services/data.service";
import { DatatableComponent } from "@swimlane/ngx-datatable/release";
import * as moment from "moment";

@Component({
  selector: "pnx-occhab-map-list",
  templateUrl: "occhab-map-list.component.html",
  styleUrls: ["./occhab-map-list.component.scss"]
})
export class OccHabMapListComponent implements OnInit {
  public displayedColumns = [
    { name: "Date", prop: "date_min" },
    { name: "Habitats", prop: "habitats" },
    { name: "Jeu de données", prop: "dataset_name" }
  ];
  @ViewChild("dataTable") dataTable: DatatableComponent;
  // public tabColumns = this.displayedColumns.map(col => col.prop);
  constructor(
    public storeService: OcchabStoreService,
    private _occHabDataService: OccHabDataService,
    public mapListService: MapListService
  ) {}
  ngOnInit() {
    this.getStations();
  }

  getStations(params?) {
    this._occHabDataService.getStations(params).subscribe(featureCollection => {
      // this.stations = data;
      this.mapListService.tableData = [];
      featureCollection.features.forEach(feature => {
        // add leaflet popup
        this.displayLeafletPopupCallback(feature);
        // push the data in the dataTable array
        this.mapListService.tableData.push(feature.properties);
      });
      this.mapListService.geojsonData = featureCollection;
    });
  }

  searchData(params) {
    this.getStations(params);
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
    divObservateurs.innerHTML = "<b> Observateurs: </b> <br>";
    divObservateurs.innerHTML =
      divObservateurs.innerHTML +
      this.displayObservateursTooltip(feature.properties).join(", ");

    const divDate = document.createElement("div");
    divDate.innerHTML = "<b> Date: </b> <br>";
    divDate.innerHTML =
      divDate.innerHTML + this.displayDateTooltip(feature.properties);

    const divHab = document.createElement("div");
    divHab.innerHTML = "<b> Habitas: </b> <br>";

    divHab.style.marginTop = "5px";
    let taxons = this.displayHabTooltip(feature.properties).join("<br>");
    divHab.innerHTML = divHab.innerHTML + taxons;

    leafletPopup.appendChild(divObservateurs);
    leafletPopup.appendChild(divDate);
    leafletPopup.appendChild(divHab);

    feature.properties["leaflet_popup"] = leafletPopup;
    return feature;
  }
}
