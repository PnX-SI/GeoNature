import { Injectable } from "@angular/core";
import { FormControl } from "@angular/forms";
import { BehaviorSubject } from "rxjs";
import { filter, tap } from "rxjs/operators";

import { AppConfig } from "@geonature_config/app.config";
import { HttpClient, HttpParams } from "@angular/common/http";
import { Router, ActivatedRoute } from "@angular/router";
import { ModuleConfig } from "../module.config";
import { AuthService, User } from "@geonature/components/auth/auth.service";
import { CommonService } from "@geonature_common/service/common.service";
import { OcctaxDataService } from "../services/occtax-data.service";

@Injectable()
export class OcctaxFormService {
  
  //id du relevé récupérer en GET
  public id_releve_occtax: BehaviorSubject<number> = new BehaviorSubject(null);
  //si ID en get récupération des données du relevé
  public occtaxData: BehaviorSubject<any> = new BehaviorSubject(null);

  public currentUser: User;
  public disabled = true;
  public editionMode: BehaviorSubject<boolean> = new BehaviorSubject(false); // boolean to check if its editionMode
  public stayOnFormInterface = new FormControl(false);
  
  constructor(
    private _http: HttpClient,
    private _route: ActivatedRoute,
    private _router: Router,
    private _auth: AuthService,
    private _commonService: CommonService,
    private _dataS: OcctaxDataService,
  ) {
    this.currentUser = this._auth.getCurrentUser();
    
    //observation de l'URL
    this.id_releve_occtax
            .pipe(
              tap(()=>this.editionMode.next(false)), //reinitialisation du mode edition à faux
              filter(id=>id !== null)
            )
            .subscribe(id=>this.getOcctaxData(id))
  }

  getOcctaxData(id) {
    this._dataS.getOneReleve(id)
                .pipe()
                .subscribe(data=>{
                  this.occtaxData.next(data);
                  this.editionMode.next(true);
                });
  }

  getDefaultValues(idOrg?: number, regne?: string, group2_inpn?: string) {
    let params = new HttpParams();
    if (idOrg) {
      params = params.set("organism", idOrg.toString());
    }
    if (group2_inpn) {
      params = params.append("regne", regne);
    }
    if (regne) {
      params = params.append("group2_inpn", group2_inpn);
    }
    return this._http.get<any>(
      `${AppConfig.API_ENDPOINT}/occtax/defaultNomenclatures`,
      {
        params: params
      }
    );
  }

  onEditReleve(id) {
    this._router.navigate(["occtax/form", id]);
  }
  backToList() {
    this._router.navigate(["occtax"]);
  }

  formDisabled() {
    if (this.disabled) {
      this._commonService.translateToaster(
        "warning",
        "Releve.FillGeometryFirst"
      );
    }
  }
}
