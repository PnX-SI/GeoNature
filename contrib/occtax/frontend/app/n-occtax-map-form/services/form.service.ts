import { Injectable } from "@angular/core";
import { BehaviorSubject } from "rxjs/BehaviorSubject";

import { AppConfig } from "@geonature_config/app.config";
import { HttpClient, HttpParams } from "@angular/common/http";
import { Router, ActivatedRoute } from "@angular/router";
import { ModuleConfig } from "../../module.config";
import { AuthService, User } from "@geonature/components/auth/auth.service";
import { CommonService } from "@geonature_common/service/common.service";

@Injectable()
export class OcctaxFormService {
  // boolean to check if its editionMode
  public editionMode: boolean;
  // subscription to get edition mode when data loaded in ajax
  public editionMode$: BehaviorSubject<boolean> = new BehaviorSubject(null);
  public id_releve_occtax: BehaviorSubject<number> = new BehaviorSubject(null);

  public currentUser: User;
  public disabled = true;
  //public stayOnFormInterface = new FormControl(false);
  
  constructor(
    private _http: HttpClient,
    private _route: ActivatedRoute,
    private _router: Router,
    private _auth: AuthService,
    private _commonService: CommonService
  ) {
    this.getReleveId();
    this.currentUser = this._auth.getCurrentUser();

    //si modification, récuperation de l'ID du relevé
    let id = this._route.snapshot.paramMap.get('id');
    if ( Number.isInteger(Number(id)) ) {
      this.id_releve_occtax.next(Number(id));
    } 
    
    
  } // end constructor

  private getReleveId(){
    

    //On vérifie si l'id de fichier à changé (pour recharger les infos au besoin)
    //if ( this.fileDataS.file_id.getValue() !== Number(id_fichier) ) {
    //  this.fileDataS.file_id.next(Number(id_fichier));
    //} 
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
