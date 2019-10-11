import { Component, OnInit } from "@angular/core";
import { OcchabStoreService } from "../services/store.service";

@Component({
  selector: "pnx-occhab-map-list",
  templateUrl: "occhab-map-list.component.html"
})
export class OccHabMapListComponent implements OnInit {
  constructor(public storeService: OcchabStoreService) {}
  ngOnInit() {}
}
