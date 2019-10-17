import { Component, OnInit, OnDestroy } from "@angular/core";
import { OcchabFormService } from "../services/form-service";
import { OcchabStoreService } from "../services/store.service";
import { OccHabDataService } from "../services/data.service";
import { leafletDrawOption } from "@geonature_common/map/leaflet-draw.options";
import { ActivatedRoute } from "@angular/router";
import { Subscription } from "rxjs/Subscription";

@Component({
  selector: "pnx-occhab-form",
  templateUrl: "occhab-form.component.html",
  styleUrls: ["./occhab-form.component.scss"]
})
export class OccHabFormComponent implements OnInit {
  public showDepth = false;
  public showHabForm = false;
  public leafletDrawOptions = leafletDrawOption;
  public filteredHab: any;
  private _sub: Subscription;

  constructor(
    public occHabForm: OcchabFormService,
    private _occHabDataService: OccHabDataService,
    public storeService: OcchabStoreService,
    private _route: ActivatedRoute
  ) {}

  ngOnInit() {
    this.leafletDrawOptions;
    leafletDrawOption.draw.polyline = false;
  }

  toggleShowHabForm() {
    this.showHabForm = !this.showHabForm;
  }

  ngAfterViewInit() {
    // get the id from the route
    this._sub = this._route.params.subscribe(params => {
      this._occHabDataService
        .getOneStation(params["id_station"])
        .subscribe(station => {
          this.occHabForm.patchStationForm(station);
          this.occHabForm.height = this.occHabForm.MAP_SMALL_HEIGHT;
        });
    });
  }

  toggleDepth() {
    this.showDepth = !this.showDepth;
  }

  formatter(item) {
    return item.search_name;
  }

  ngOnDestroy() {
    this._sub.unsubscribe();
  }
}
