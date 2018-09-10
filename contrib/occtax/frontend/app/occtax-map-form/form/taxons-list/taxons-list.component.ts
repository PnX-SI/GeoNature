import { Component, OnInit, Input, Output, EventEmitter } from "@angular/core";
import { OcctaxFormService } from "../../../occtax-map-form/form/occtax-form.service";
import { CommonService } from "@geonature_common/service/common.service";
import { Taxon } from "@geonature_common_form/taxonomy/taxonomy.component";

@Component({
  selector: "pnx-taxons-list",
  templateUrl: "./taxons-list.component.html",
  styleUrls: ["./taxons-list.component.scss"]
})
export class TaxonsListComponent implements OnInit {
  @Input() list: Array<Taxon>;
  @Output() taxonRemoved = new EventEmitter<number>();
  @Output() taxonEdited = new EventEmitter<number>();

  constructor(
    private _cfs: OcctaxFormService,
    private _commonService: CommonService
  ) {}

  ngOnInit() {}
  deleteTaxon(index): void {
    this.taxonRemoved.emit(index);
  }
  editTaxons(index): void {
    if (!this._cfs.isEdintingOccurrence) {
      this.taxonEdited.emit(index);
    } else {
      this._commonService.translateToaster("warning", "Taxon.CurrentlyEditing");
    }
  }
}
