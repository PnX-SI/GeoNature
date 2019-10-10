import { Component, AfterViewInit, OnDestroy, OnInit } from "@angular/core";
import { OcchabStoreService } from "../services/store.service";
import { ActivatedRoute } from "@angular/router";
import { Subscription } from "rxjs/Subscription";

@Component({
  selector: "pnx-occhab-map-list",
  templateUrl: "occhab-map-list.component.html"
})
export class OccHabMapListComponent
  implements AfterViewInit, OnDestroy, OnInit {
  private _sub: Subscription;
  constructor(
    public storeService: OcchabStoreService,
    private _route: ActivatedRoute
  ) {}

  ngOnInit() {
    console.log("LAAAA");
  }

  ngAfterViewInit() {
    console.log("after view init");

    this.storeService.state$.subscribe(state => {
      console.log("subscription to state");
      console.log(state);
    });
    // get the id from the route
    this._sub = this._route.params.subscribe(params => {
      console.log("LOAAAAD");

      console.log(params);
    });
  }

  ngOnDestroy() {
    this._sub.unsubscribe();
  }
}
