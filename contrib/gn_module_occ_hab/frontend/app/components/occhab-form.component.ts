import { Component, OnInit } from "@angular/core";
import { OcchabFormService } from "../services/form-service";
import { OcchabStoreService } from "../services/store.service";
import { OccHabDataService } from "../services/data.service";
import { leafletDrawOption } from "@geonature_common/map/leaflet-draw.options";
import { ActivatedRoute, Router } from "@angular/router";
import { Subscription } from "rxjs/Subscription";
import { CommonService } from "@geonature_common/service/common.service";
import { AppConfig } from "@geonature_config/app.config";

@Component({
  selector: "pnx-occhab-form",
  templateUrl: "occhab-form.component.html",
  styleUrls: ["./occhab-form.component.scss"],
  providers: [OcchabFormService]
})
export class OccHabFormComponent implements OnInit {
  public showDepth = false;
  public showHabForm = true;
  public leafletDrawOptions = leafletDrawOption;
  public filteredHab: any;
  private _sub: Subscription;
  public currentlyEditingHab = false;
  public currentIdHabEdition: number;
  public MAP_SMALL_HEIGHT = "50vh";
  public MAP_FULL_HEIGHT = "87vh";
  public mapHeight = this.MAP_FULL_HEIGHT;
  public appConfig = AppConfig;

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

  ngAfterViewInit() {
    // get the id from the route
    this._sub = this._route.params.subscribe(params => {
      this._occHabDataService
        .getOneStation(params["id_station"])
        .subscribe(station => {
          this.occHabForm.patchStationForm(station);

          this.mapHeight = this.MAP_SMALL_HEIGHT;
        });
    });
  }

  // toggle the hab form and call the editHab function of form service
  editHab(index) {
    this.showHabForm = true;
    // check if the form hab is not currently edited
    if (!this.occHabForm.habitatForm.pristine) {
      const r = confirm(
        "Attention, le formulaire habitat est en cours d'édition, êtes vous sur de supprimer l'édition en cours ?"
      );
      if (r == true) {
        this.occHabForm.editHab(index);
        this.currentlyEditingHab = true;
        this.currentIdHabEdition = index;
      }
    } else {
      this.occHabForm.editHab(index);
      this.currentIdHabEdition = index;
      this.currentlyEditingHab = true;
    }
  }

  cancelHab() {
    this.showHabForm = false;
    this.occHabForm.cancelHab(
      this.currentlyEditingHab,
      this.currentIdHabEdition
    );
    this.currentlyEditingHab = false;
  }

  toggleShowHabForm() {
    this.showHabForm = !this.showHabForm;
  }

  toggleDepth() {
    this.showDepth = !this.showDepth;
  }

  addHabitat() {
    this.mapHeight = this.MAP_SMALL_HEIGHT;
    this.toggleShowHabForm();
    this.occHabForm.addHabitat();
  }

  postStation() {
    const station = this.occHabForm.formatStationBeforePost();
    this._occHabDataService.postStation(station).subscribe(
      data => {
        this.occHabForm.resetAllForm();
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
