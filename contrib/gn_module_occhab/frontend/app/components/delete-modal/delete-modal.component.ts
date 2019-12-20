import { Component, OnInit, Input, Output, EventEmitter } from "@angular/core";
import { CommonService } from "@geonature_common/service/common.service";
import { OccHabDataService } from "../../services/data.service";
import { Router } from "@angular/router";

@Component({
  selector: "pnx-occhab-delete",
  templateUrl: "./delete-modal.component.html"
})
export class ModalDeleteStation implements OnInit {
  @Input() idStation: number;
  @Input() nbHabitats: number;
  @Input() c: any;
  @Output() onDelete = new EventEmitter();
  constructor(
    private _commonService: CommonService,
    private _occHabDataService: OccHabDataService,
    private _router: Router
  ) {}

  ngOnInit() {}

  deleteStation() {
    this.onDelete.emit();
    this._occHabDataService.deleteOneStation(this.idStation).subscribe(
      d => {
        this._commonService.regularToaster(
          "success",
          "Station supprimée avec succès"
        );

        this._router.navigate(["occhab"]);
      },
      () => {
        this._commonService.regularToaster(
          "error",
          "Erreur lors de la suppression de la station"
        );
      },
      () => {
        this.c();
      }
    );
  }
}
