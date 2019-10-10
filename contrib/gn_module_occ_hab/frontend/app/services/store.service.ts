import { Injectable } from "@angular/core";
import { DataFormService } from "@geonature_common/form/data-form.service";
import { ModuleConfig } from "../module.config";
import { OccHabDataService } from "./data.service";
import { Observable, BehaviorSubject } from "rxjs";

@Injectable()
export class OcchabStoreService {
  public nomenclatureItems = {};
  public typoHabitat: Array<any>;
  public stations: Array<any>;
  private _state$: BehaviorSubject<any> = new BehaviorSubject({});
  public state$: Observable<any> = this._state$.asObservable();
  constructor(
    private _gnDataService: DataFormService,
    private _occHabDataService: OccHabDataService
  ) {
    this._gnDataService
      .getNomenclatures([
        "METHOD_CALCUL_SURFACE",
        "DETERMINATION_TYP_HAB",
        "TECHNIQUE_COLLECT_HAB",
        "HAB_INTERET_COM",
        "EXPOSITION",
        "NAT_OBJ_GEO",
        "HAB_INTERET_COM",
        "ABONDANCE_HAB"
      ])
      .subscribe(data => {
        data.forEach(element => {
          this.nomenclatureItems[element.mnemonique] = element.values;
        });
      });
    this._gnDataService
      .getTypologyHabitat(ModuleConfig.CODE_TYPO_HABITAT)
      .subscribe(data => {
        this.typoHabitat = data;
      });
    this._occHabDataService.getStations().subscribe(data => {
      this.stations = data;
    });
  }

  get state() {
    return this._state$.getValue();
  }

  setState(nextState): void {
    this._state$.next(nextState);
  }

  getOnStation(id_station) {
    this._occHabDataService.getOneStation(id_station).subscribe(data => {
      this.setState({
        ...this.state,
        station: data
      });
    });
  }
}
