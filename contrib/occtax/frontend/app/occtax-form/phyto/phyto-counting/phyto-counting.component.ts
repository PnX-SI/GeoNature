import {
  Component,
  OnInit,
  Input,
  OnDestroy,
  OnChanges,
  SimpleChanges,
} from "@angular/core";
import { UntypedFormGroup, UntypedFormArray } from "@angular/forms";

import { ConfigService } from "@geonature/services/config.service";
import { MediasComponent } from "@geonature_common/form/media/medias.component";
import { ModuleService } from "@geonature/services/module.service";
import { ValidationErrorsId } from "@geonature/services/validators";
import { ViewChild } from "@angular/core";

import { OcctaxConfigService } from "../../../services/occtax-config.service";
import { OcctaxFormService } from "../../occtax-form.service";

import { PhytoCountingService } from "./counting.service";
import { PhytoOccurrenceService } from "../phyto-occurrence/occurrence.service";

/**
 * TODO: 
 *  *disable the counting forms if there is no taxon selected
 *  *change input style from dropdown to cursor?
 */
@Component({
  selector: "pnx-occtax-form-phyto-counting",
  templateUrl: "./phyto-counting.component.html",
  providers: [PhytoCountingService],
})
export class PhytoCountingComponent implements OnInit, OnChanges, OnDestroy {

  @ViewChild(MediasComponent) mediasComp: MediasComponent;
  @Input("value")
  set counting(value: any) {
    this.occtaxFormCountingService.counting.next(value);
  }
  @Input() stratumId: number | null;

  public form: UntypedFormGroup;

  constructor(
    public occtaxFormService: OcctaxFormService,
    public phytoOccurrenceService: PhytoOccurrenceService,
    private occtaxFormCountingService: PhytoCountingService,
    public config: ConfigService,
    public moduleService: ModuleService,
    public occtaxConfig: OcctaxConfigService
  ) {
    this.stratumId = null;
  }

  // Expose enum to html
  ValidationErrorsId = ValidationErrorsId;

  ngOnInit() {
    this.form = this.occtaxFormCountingService.form;
    this.setStratum();
  }

  ngOnChanges(changes: SimpleChanges): void {
    if (changes.stratumId && this.form) {
      this.setStratum();
    }
  }

  private setStratum(): void {
    if (this.stratumId != null) {
      this.form
        .get("id_nomenclature_vegetation_stratum")
        .setValue(this.stratumId, { emitEvent: false });
    }
  }
  validateMediasDeletions() {
    this.mediasComp?.validateDeletions();
  }

  ngOnDestroy() {
    //delete elem from form.get('cor_counting_occtax')
    const idx = (
      this.phytoOccurrenceService.form.get(
        "cor_counting_occtax",
      ) as UntypedFormArray
    ).controls.findIndex((elem) => elem === this.form);
    if (idx !== -1) {
      (
        this.phytoOccurrenceService.form.get(
          "cor_counting_occtax",
        ) as UntypedFormArray
      ).removeAt(idx);
    }
  }

}
