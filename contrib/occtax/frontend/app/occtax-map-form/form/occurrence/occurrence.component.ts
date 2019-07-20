import {
  Component,
  OnInit,
  AfterViewInit,
  Input,
  ViewEncapsulation,
  ViewChildren,
  ViewChild,
  QueryList
} from "@angular/core";
import { FormControl, FormGroup } from "@angular/forms";
import { OcctaxFormService } from "../occtax-form.service";
import { CommonService } from "@geonature_common/service/common.service";
import { NomenclatureComponent } from "@geonature_common/form/nomenclature/nomenclature.component";
import { ModuleConfig } from "../../../module.config";

@Component({
  selector: "pnx-occurrence",
  templateUrl: "./occurrence.component.html",
  styleUrls: ["./occurrence.component.scss"],
  encapsulation: ViewEncapsulation.None
})
export class OccurrenceComponent implements OnInit, AfterViewInit {
  public occtaxConfig: any;
  @Input() occurrenceForm: FormGroup;
  @ViewChild("taxon") taxon;
  @ViewChildren(NomenclatureComponent)
  nomenclatures: QueryList<NomenclatureComponent>;
  @ViewChild("existProof") existProof: NomenclatureComponent;
  constructor(
    public fs: OcctaxFormService,
    private _commonService: CommonService
  ) {}

  ngOnInit() {
    this.occtaxConfig = ModuleConfig;
  }

  getLabels(labels) {
    this.fs.currentExistProofLabels = labels;
  }

  validateDigitalProof(c: FormControl) {
    let REGEX = new RegExp("^(http://|https://|ftp://){1}.+$");
    return REGEX.test(c.value)
      ? null
      : {
          validateDigitalProof: {
            valid: false
          }
        };
  }

  ngAfterViewInit() {
    document.getElementById("taxonInput").focus();
  }
}
