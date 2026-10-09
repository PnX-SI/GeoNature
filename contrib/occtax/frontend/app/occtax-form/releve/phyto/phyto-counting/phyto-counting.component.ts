import { Component, OnInit, OnDestroy } from "@angular/core";
import { Subject } from "rxjs";

@Component({
  selector: "pnx-occtax-form-phyto-counting",
  templateUrl: "./phyto-counting.component.html",
  styleUrls: ["./phyto-counting.component.scss"],
})
export class PhytoCountingComponent implements OnInit, OnDestroy {

  private destroy$ = new Subject<void>();

  public ngOnInit(): void {
  }

  public ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }
}
