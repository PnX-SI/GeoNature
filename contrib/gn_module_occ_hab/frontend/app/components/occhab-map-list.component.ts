import { Component, OnInit } from "@angular/core";
import { OcchabStoreService } from "../services/store.service";
import { MapListService } from "@geonature_common/map-list/map-list.service";
import { OccHabDataService } from "../services/data.service";

@Component({
  selector: "pnx-occhab-map-list",
  templateUrl: "occhab-map-list.component.html",
  styleUrls: ["./occhab-map-list.component.scss"]
})
export class OccHabMapListComponent implements OnInit {
  public displayedColumns = [
    { name: "ID", prop: "id_station" },
    { name: "Date", prop: "date_min" }
  ];
  // public tabColumns = this.displayedColumns.map(col => col.prop);
  constructor(
    public storeService: OcchabStoreService,
    private _occHabDataService: OccHabDataService,
    public mapListService: MapListService
  ) {}
  ngOnInit() {
    this._occHabDataService.getStations().subscribe(data => {
      // this.stations = data;
      this.mapListService.geojsonData = data;
      this.mapListService.loadTableData(data);
    });
  }
}
