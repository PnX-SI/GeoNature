import { Component, OnInit, OnDestroy } from "@angular/core";
import { OcchabFormService } from "../services/form-service";
import { OcchabStoreService } from "../services/store.service";
import { OccHabDataService } from "../services/data.service";
import { leafletDrawOption } from "@geonature_common/map/leaflet-draw.options";
import { ActivatedRoute, Router } from "@angular/router";
import { Subscription } from "rxjs/Subscription";
import { CommonService } from "@geonature_common/service/common.service";

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
    private _route: ActivatedRoute,
    private _router: Router,
    private _commonService: CommonService
  ) {}

  ngOnInit() {
    this.leafletDrawOptions;
    leafletDrawOption.draw.polyline = false;
  }

  // toggle the hab form and call the editHab function of form service
  editHab(index) {
    this.toggleShowHabForm();
    this.occHabForm.editHab(index);
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

  postStation() {
    const station = this.occHabForm.formatStationBeforePost();
    this._occHabDataService.postStation(station).subscribe(
      data => {
        this.occHabForm.resetAllForm();
        this.occHabForm.height = this.occHabForm.MAP_FULL_HEIGHT;
        this._router.navigate(["occhab"]);
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

  formatter(item) {
    return item.search_name;
  }

  ngOnDestroy() {
    this._sub.unsubscribe();
  }
}
