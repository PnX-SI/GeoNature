import { Component, OnInit, HostListener, Inject, AfterViewInit } from "@angular/core";
import { DOCUMENT } from '@angular/common';
import { ActivatedRoute, Router } from "@angular/router";
import { BehaviorSubject } from 'rxjs';
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
  releveUrl: string = null;
  currentTab: 'releve'|'taxons';
  cardHeight: number;
  cardContentHeight: any;

  constructor(
    @Inject(DOCUMENT) document,
    private _route: ActivatedRoute,
    private _router: Router,
    public occtaxFormService: OcctaxFormService,
    private _dfs: DataFormService,
    private _authService: AuthService
  ) { }
  
  ngOnInit() {
    //si modification, récuperation de l'ID du relevé
    let id = this._route.snapshot.paramMap.get('id');
    if ( id && Number.isInteger(Number(id)) ) {
      this.occtaxFormService.id_releve_occtax.next(Number(id));
    } else {
      id = null;
      this.occtaxFormService.id_releve_occtax.next(null);
    }

    //gestion de la route pour les occurrences
    let urlSegments = this._router.routerState.snapshot.url.split('/');
    if ( urlSegments[urlSegments.length-1] === 'taxons') {
      this.currentTab = <'releve'|'taxons'> urlSegments.pop();
    } else {
      this.currentTab = 'releve';
    }
    this.releveUrl = urlSegments.join('/');

    //Vérification de la route taxons avec un ID de releve, sinon redirection
    if (this.currentTab === 'taxons' && id === null) {
      this._router.navigate([this.releveUrl])
    }
  }

  ngAfterViewInit() {
    setTimeout(()=>this.calcCardContentHeight(),500);
  }

  @HostListener('window:resize', ['$event'])
  onResize(event) {
    this.calcCardContentHeight()
  }

  calcCardContentHeight() {
    let wH = window.innerHeight;
    let tbH = document.getElementById('app-toolbar') ? document.getElementById('app-toolbar').offsetHeight : 0;
    let nbH = (<HTMLScriptElement><any>document.querySelector("pnx-occtax-form .tab")) ? (<HTMLScriptElement><any>document.querySelector("pnx-occtax-form .tab")).offsetHeight : 0;

    let height = wH -(tbH + nbH + 40);
    this.cardContentHeight = height >= 350 ? height : 350;
  }
}