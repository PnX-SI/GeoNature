import { Component, OnInit, OnDestroy } from "@angular/core";
import { OcchabFormService } from "../services/form-service";
import { OcchabStoreService } from "../services/store.service";
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
  public leafletDrawOptions = leafletDrawOption;
  public filteredHab: any;
  private _sub: Subscription;

  constructor(
    public occHabForm: OcchabFormService,
    public storeService: OcchabStoreService,
    private _route: ActivatedRoute
  ) {}

  ngOnInit() {
    this.leafletDrawOptions;
    leafletDrawOption.draw.polyline = false;
  }

  ngAfterViewInit() {
    this.storeService.state$.subscribe(state => {
      console.log("subscription to state");
      console.log(state);
    });
    // get the id from the route
    this._sub = this._route.params.subscribe(params => {
      console.log("LOAAAAD");

      console.log(params);
      this.storeService.getOnStation(params["id_station"]);
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
