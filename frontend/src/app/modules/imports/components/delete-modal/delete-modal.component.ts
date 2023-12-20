import { Component, OnInit, Input, Output, EventEmitter } from "@angular/core";
import { CommonService } from "@geonature_common/service/common.service";
import { DataService } from "../../services/data.service";
import { Router } from "@angular/router";
import { Import } from "../../models/import.model";

@Component({
  selector: "import-delete",
  templateUrl: "./delete-modal.component.html"
})
export class ModalDeleteImport implements OnInit {
  @Input() row: Import;
  @Input() c: any;
  @Output() onDelete = new EventEmitter();
  constructor(
    private _commonService: CommonService,
    private _ds: DataService,
    private _router: Router
  ) { }

  ngOnInit() { }

  deleteImport() {
    this._ds.deleteImport(this.row.id_import).subscribe(
      () => {
        this._commonService.regularToaster("success", "Import supprimé.");
        this.onDelete.emit();
        this.c();
      }
    );
  }
}
