import { Injectable } from "@angular/core";
import { DataFormService } from "@geonature_common/form/data-form.service";
import { OccHabDataService } from "./data.service";
import { Observable, BehaviorSubject } from "rxjs";
import { ConfigService } from "@geonature/utils/configModule/core";
import { moduleCode } from "../module.code.config";

@Injectable()
export class OcchabStoreService {
  public moduleConfig: any;
  public nomenclatureItems = {};
  public typoHabitat: Array<any>;
  public stations: Array<any>;
  public firstMessageMapList = true;
  /** Current list of id_station in the map list */
  public idsStation: Array<number>;
  private _defaultNomenclature$: BehaviorSubject<any> = new BehaviorSubject(
    null
  );
  public defaultNomenclature$: Observable<
    any
  > = this._defaultNomenclature$.asObservable();
  constructor(
    private _gnDataService: DataFormService,
    private _occHabDataService: OccHabDataService,
    private _configService: ConfigService,
  ) {
    this.moduleConfig = this._configService.getSettings(moduleCode);
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
      .getTypologyHabitat(this.moduleConfig.ID_LIST_HABITAT)
      .subscribe(data => {
        this.typoHabitat = data;
      });
    this._gnDataService
      .getDefaultNomenclatureValue("occhab")
      .subscribe(data => {
        this._defaultNomenclature$.next(data);
      });
  }

  get defaultNomenclature() {
    return this._defaultNomenclature$.getValue();
  }
}
