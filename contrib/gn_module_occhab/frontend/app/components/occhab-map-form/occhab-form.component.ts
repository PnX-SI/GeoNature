import { Component, OnInit, OnDestroy } from '@angular/core';
import { OcchabFormService } from '../../services/form-service';
import { OcchabStoreService } from '../../services/store.service';
import { OccHabDataService } from '../../services/data.service';
import { leafletDrawOption } from '@geonature_common/map/leaflet-draw.options';
import { ActivatedRoute, Router } from '@angular/router';
import { Subscription } from 'rxjs/Subscription';
import { CommonService } from '@geonature_common/service/common.service';
import { filter } from 'rxjs/operators';
import { ConfigService } from '@geonature/services/config.service';
import { StationFeature } from '../../models';
import { FormService } from '@geonature_common/form/form.service';

@Component({
  selector: 'pnx-occhab-form',
  templateUrl: 'occhab-form.component.html',
  styleUrls: ['./occhab-form.component.scss', '../responsive-map.scss'],
  providers: [OcchabFormService],
})
export class OccHabFormComponent implements OnInit, OnDestroy {
  public leafletDrawOptions = leafletDrawOption;
  public filteredHab: any;
  private _sub: Array<Subscription> = [];
  public editionMode = false;
  public MAP_SMALL_HEIGHT = '50vh !important;';
  public MAP_FULL_HEIGHT = '87vh';
  public mapHeight = this.MAP_FULL_HEIGHT;
  public showHabForm = false;
  public showTabHab = false;
  public showDepth = false;
  public disabledForm = true;
  public firstFileLayerMessage = true;
  public currentGeoJsonFileLayer;
  public markerCoordinates;
  public currentEditingStation: StationFeature;
  // boolean tocheck if the station has at least one hab (control the validity of the form)
  public atLeastOneHab = false;

  public isCollapseDepth = true;
  public isCollaspeTypo = true;

  constructor(
    public occHabForm: OcchabFormService,
    private _occHabDataService: OccHabDataService,
    public storeService: OcchabStoreService,
    private _route: ActivatedRoute,
    private _router: Router,
    private _commonService: CommonService,
    public config: ConfigService,
    private _formService: FormService
  ) {}

  ngOnInit() {
    this.leafletDrawOptions;
    leafletDrawOption.draw.polyline = false;
    leafletDrawOption.draw.circle = false;
    leafletDrawOption.draw.rectangle = false;

    this.occHabForm.stationForm = this.occHabForm.initStationForm();
    this.occHabForm.stationForm.controls.geom_4326.valueChanges.subscribe((d) => {
      this.disabledForm = false;
    });
    this.storeService.defaultNomenclature$.pipe(filter((val) => val !== null)).subscribe((val) => {
      this.occHabForm.patchDefaultNomenclaureStation(val);
    });
  }

  ngAfterViewInit() {
    // get the id from the route
    this._sub.push(
      this._route.params.subscribe((params) => {
        if (params['id_station']) {
          this.editionMode = true;
          this.atLeastOneHab = true;
          this.showHabForm = false;
          this.showTabHab = true;
          this._occHabDataService.getStation(params['id_station']).subscribe((station) => {
            this.currentEditingStation = station;
            if (station.geometry.type == 'Point') {
              // set the input for the marker component
              this.markerCoordinates = station.geometry.coordinates;
            } else {
              // set the input for leaflet draw component
              this.currentGeoJsonFileLayer = station.geometry;
            }
            this.occHabForm.patchStationForm(station);
          });
        } else {
          this._sub.push(this._formService.autoCompleteDate(this.occHabForm.stationForm));
        }
      })
    );
  }

  formIsDisable() {
    if (this.disabledForm) {
      this._commonService.translateToaster('warning', 'Releve.FillGeometryFirst');
    }
  }

  // display help toaster for filelayer
  infoMessageFileLayer() {
    if (this.firstFileLayerMessage) {
      this._commonService.translateToaster('info', 'Map.FileLayerInfoMessage');
    }
    this.firstFileLayerMessage = false;
  }

  addNewHab() {
    this.occHabForm.addNewHab();
    this.showHabForm = true;
  }

  validateHabitat() {
    this.showHabForm = false;
    this.showTabHab = true;
    this.occHabForm.currentEditingHabForm = null;
    this.atLeastOneHab = true;
  }

  // toggle the hab form and call the editHab function of form service
  editHab(index) {
    this.occHabForm.editHab(index);
    this.showHabForm = true;
  }

  cancelHab() {
    this.showHabForm = false;
    this.occHabForm.cancelHab();
  }

  toggleDepth() {
    this.showDepth = !this.showDepth;
  }

  postStation() {
    const station = this.occHabForm.formatStationBeforePost();
    this._occHabDataService.createOrUpdateStation(station).subscribe((data) => {
      this.occHabForm.resetAllForm();
      this._router.navigate(['occhab']);
    });
  }

  formatter(item) {
    return item.search_name;
  }

  ngOnDestroy() {
    this._sub.forEach((sub) => {
      sub.unsubscribe();
    });
  }
}
