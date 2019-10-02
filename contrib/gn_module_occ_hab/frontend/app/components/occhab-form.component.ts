import { Component, OnInit } from "@angular/core";
import { OcchabFormService } from "../services/form-service";
import { OcchabStoreService } from "../services/store.service";
import { leafletDrawOption } from "@geonature_common/map/leaflet-draw.options";

@Component({
  selector: "pnx-occhab-form",
  templateUrl: "occhab-form.component.html",
  styleUrls: ["./occhab-form.component.scss"]
})
export class OccHabFormComponent implements OnInit {
  public showDepth = false;
  public leafletDrawOptions = leafletDrawOption;
  constructor(
    public occHabForm: OcchabFormService,
    public storeService: OcchabStoreService
  ) {}

  ngOnInit() {
    this.leafletDrawOptions;
    leafletDrawOption.draw.polyline = false;
  }

  toggleDepth() {
    this.showDepth = !this.showDepth;
  }

  formatter(item) {
    return item.lb_hab_fr_complet.replace(/<[^>]*>/g, "");
  }

  test() {
    this.height = "50vh";
  }
}
