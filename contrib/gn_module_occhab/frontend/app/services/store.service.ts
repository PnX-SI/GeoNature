import { Injectable } from "@angular/core";
import { DataFormService } from "@geonature_common/form/data-form.service";
import { Observable, BehaviorSubject, of } from "rxjs";
import { catchError, shareReplay } from "rxjs/operators";
import { ConfigService } from "@geonature/services/config.service";

@Injectable()
export class OcchabStoreService {
  public nomenclatureItems = {};
  public typoHabitat: Array<any>;
  public stations: Array<any>;
  public firstMessageMapList = true;
  /** Current list of id_station in the map list */
  public idsStation: Array<number>;
  private _defaultNomenclature$: BehaviorSubject<any> = new BehaviorSubject(
    null
  );
  public defaultNomenclature$: Observable<any> =
    this._defaultNomenclature$.asObservable();
  /**
   * Définitions des champs additionnels, une requête par niveau du formulaire.
   * Deux appels distincts sont nécessaires : le endpoint combine les object_code
   * multiples avec un ET, une liste ne renverrait donc que les champs rattachés
   * aux deux objets à la fois.
   */
  public stationAdditionalFields$: Observable<Array<any>>;
  public habitatAdditionalFields$: Observable<Array<any>>;
  constructor(
    private _gnDataService: DataFormService,
    public config: ConfigService
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
        "ABONDANCE_HAB",
        "TYPE_SOL",
      ])
      .subscribe((data) => {
        data.forEach((element) => {
          this.nomenclatureItems[element.mnemonique] = element.values;
        });
      });
    this._gnDataService
      .getTypologyHabitat(this.config.OCCHAB.ID_LIST_HABITAT)
      .subscribe((data) => {
        this.typoHabitat = data;
      });
    this._gnDataService
      .getDefaultNomenclatureValue("occhab")
      .subscribe((data) => {
        this._defaultNomenclature$.next(data);
      });
    this.stationAdditionalFields$ = this.getAdditionalFields("OCCHAB_STATION");
    this.habitatAdditionalFields$ = this.getAdditionalFields("OCCHAB_HABITAT");
  }

  private getAdditionalFields(objectCode: string): Observable<Array<any>> {
    return this._gnDataService
      .getadditionalFields({
        module_code: "OCCHAB",
        object_code: objectCode,
      })
      .pipe(
        catchError((error) => {
          console.error("Error while getting additional fields", error);
          return of([]);
        }),
        // le service est fourni à l'échelle du module : une seule requête,
        // partagée entre le formulaire de saisie et la fiche d'information
        shareReplay({ bufferSize: 1, refCount: false })
      );
  }

  get defaultNomenclature() {
    return this._defaultNomenclature$.getValue();
  }
}
