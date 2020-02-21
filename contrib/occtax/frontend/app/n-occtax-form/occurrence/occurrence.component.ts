import { Component, OnInit } from "@angular/core";
import {animate, state, style, transition, trigger} from '@angular/animations';
import { FormControl, FormGroup } from "@angular/forms";
import { OcctaxFormService } from "../occtax-form.service";
import { CommonService } from "@geonature_common/service/common.service";
import { NomenclatureComponent } from "@geonature_common/form/nomenclature/nomenclature.component";
import { ModuleConfig } from "../../module.config";
import { OcctaxFormOccurrenceService } from "./occurrence.service";

@Component({
  selector: "pnx-occtax-form-occurrence",
  templateUrl: "./occurrence.component.html",
  styleUrls: ["./occurrence.component.scss"],
  animations: [
    trigger('detailExpand', [
      state('collapsed', style({height: '0px', minHeight: '0', margin: '-1px', overflow: 'hidden', padding: '0', display:'none'})),
      state('expanded', style({height: '*'})),
      transition('expanded <=> collapsed', animate('225ms cubic-bezier(0.4, 0.0, 0.2, 1)')),
    ]),
  ],
})
export class OcctaxFormOccurrenceComponent implements OnInit {
  
  // @Input() occurrenceForm: FormGroup;
  // @ViewChild("taxon") taxon;
  // @ViewChildren(NomenclatureComponent)
  // nomenclatures: QueryList<NomenclatureComponent>;
  // @ViewChild("existProof") existProof: NomenclatureComponent;
  public occtaxConfig = ModuleConfig;
  public occurrenceForm: FormGroup;
  public taxref: FormGroup;
  private advanced: string = 'collapsed';

  constructor(
    public fs: OcctaxFormService,
    private _commonService: CommonService,
    private occtaxFormOccurrenceService: OcctaxFormOccurrenceService
  ) {}

  ngOnInit() {
    this.occurrenceForm = this.occtaxFormOccurrenceService.form;
  }

  getLabels(labels) {
    //this.fs.currentExistProofLabels = labels;
  }

  onSelectTaxon(event: any): void {
    this.occtaxFormOccurrenceService.taxref.next(event.item);
  }

  validateDigitalProof(c: FormControl) {
    // let REGEX = new RegExp("^(http://|https://|ftp://){1}.+$");
    // return REGEX.test(c.value)
    //   ? null
    //   : {
    //       validateDigitalProof: {
    //         valid: false
    //       }
    //     };
  }

  collapse(){
    this.advanced = (this.advanced === 'collapsed' ? 'expanded' : 'collapsed');
  }
}
