import { Component, OnInit, HostListener, Inject, ElementRef, AfterViewInit } from "@angular/core";
import { DOCUMENT } from '@angular/common';
import { ActivatedRoute, Router } from "@angular/router";
import { ModuleConfig } from "../module.config";
import { OcctaxFormService } from "./occtax-form.service";
import { DataFormService } from "@geonature_common/form/data-form.service";
import { MarkerComponent } from "@geonature_common/map/marker/marker.component";
import { AuthService } from "@geonature/components/auth/auth.service";
import { NavHomeComponent } from "@geonature/components/nav-home/nav-home.component";

@Component({
  selector: "pnx-occtax-form",
  templateUrl: "./occtax-form.component.html",
  styleUrls: ["./occtax-form.component.scss"]
})
export class OcctaxFormComponent implements OnInit, AfterViewInit {

  public occtaxConfig = ModuleConfig;
  public id;
  cardHeight: number;
  cardContentHeight: any;

  constructor(
    @Inject(DOCUMENT) document,
    private _route: ActivatedRoute,
    private _router: Router,
    public fs: OcctaxFormService,
    private _dfs: DataFormService,
    private _authService: AuthService
  ) { }
  
  ngOnInit() {
    //si modification, récuperation de l'ID du relevé
    let id = this._route.snapshot.paramMap.get('id');
    if ( id && Number.isInteger(Number(id)) ) {
      this.fs.id_releve_occtax.next(Number(id));
    } else {
      this.fs.id_releve_occtax.next(null);
    }

  }

  ngAfterViewInit() {
    setInterval(()=>this.calcCardContentHeight(),500);
  }

  @HostListener('window:resize', ['$event'])
  onResize(event) {
    this.calcCardContentHeight()
  }

  calcCardContentHeight(): void {
    let wH = window.innerHeight;
    let tbH = document.getElementById('app-toolbar').offsetHeight;
    let nbH = (document.querySelector("pnx-occtax-form mat-tab-header") as ElementRef).offsetHeight;

    this.cardContentHeight = wH -(tbH + nbH + 58);
  }

}
