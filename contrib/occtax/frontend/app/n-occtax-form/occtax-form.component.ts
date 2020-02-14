import { Component, OnInit } from "@angular/core";
import { ActivatedRoute, Router } from "@angular/router";
import { ModuleConfig } from "../module.config";
import { OcctaxFormService } from "./occtax-form.service";
import { DataFormService } from "@geonature_common/form/data-form.service";
import { MarkerComponent } from "@geonature_common/map/marker/marker.component";
import { AuthService } from "@geonature/components/auth/auth.service";

@Component({
  selector: "pnx-occtax-form",
  templateUrl: "./occtax-form.component.html",
  styleUrls: ["./occtax-form.component.scss"],
  //providers: [OcctaxFormService]
})
export class OcctaxFormComponent implements OnInit {

  public occtaxConfig = ModuleConfig;

  constructor(
    private _route: ActivatedRoute,
    private _router: Router,
    public fs: OcctaxFormService,
    private _dfs: DataFormService,
    private _authService: AuthService
  ) {}

  ngOnInit() {
    //si modification, récuperation de l'ID du relevé
    let id = this._route.snapshot.paramMap.get('id');
    if ( id && Number.isInteger(Number(id)) ) {
      this.fs.id_releve_occtax.next(Number(id));
    } 
  }
}
