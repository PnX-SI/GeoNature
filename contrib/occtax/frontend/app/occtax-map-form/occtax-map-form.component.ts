import { Component, OnInit, OnDestroy } from "@angular/core";
import { MapService } from "@geonature_common/map/map.service";
import { leafletDrawOption } from "@geonature_common/map/leaflet-draw.options";
import { ActivatedRoute, Router } from "@angular/router";
import { Subscription } from "rxjs/Subscription";
import { ModuleConfig } from "../module.config";

@Component({
  selector: "pnx-occtax-map-form",
  templateUrl: "./occtax-map-form.component.html",
  styleUrls: ["./occtax-map-form.component.scss"],
  providers: [MapService]
})
export class OcctaxMapFormComponent implements OnInit, OnDestroy {
  public leafletDrawOptions: any;
  private _sub: Subscription;
  public id: number;
  public occtaxConfig = ModuleConfig;
  constructor(
    private _ms: MapService,
    private _route: ActivatedRoute,
    private _router: Router
  ) {}

  ngOnInit() {
    // overight the leaflet draw object to set options
    // examples: enable circle =>  leafletDrawOption.draw.circle = true;
    this.leafletDrawOptions = leafletDrawOption;
    // get the id from the route
    this._sub = this._route.params.subscribe(params => {
      this.id = +params["id"];
    });
  }

  sendGeoInfo(geojson) {
    this._ms.setGeojsonCoord(geojson);
  }

  ngOnDestroy() {
    this._sub.unsubscribe();
  }
}
