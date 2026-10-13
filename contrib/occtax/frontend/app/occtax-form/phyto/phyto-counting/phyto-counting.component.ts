import {
  Component,
  OnInit,
  Input,
  OnDestroy,
  Output,
  EventEmitter,
  OnChanges,
  SimpleChanges,
} from "@angular/core";
import { UntypedFormGroup, UntypedFormArray } from "@angular/forms";
import { Subscription } from "rxjs";
import { filter } from "rxjs/operators";

import { OcctaxFormService } from "../../occtax-form.service";
import { PhytoOccurrenceService } from "../phyto-occurrence/occurrence.service";
import { PhytoCountingService } from "./counting.service";
import { ConfigService } from "@geonature/services/config.service";
import { ModuleService } from "@geonature/services/module.service";
import { OcctaxConfigService } from "../../../services/occtax-config.service";

import { ValidationErrorsId } from "@geonature/services/validators";
import { ViewChild } from "@angular/core";
import { MediasComponent } from "@geonature_common/form/media/medias.component";

/**
 * TODO: disable the counting forms if there is no taxon selected
 */
@Component({
  selector: "pnx-occtax-form-phyto-counting",
  templateUrl: "./phyto-counting.component.html",
  styleUrls: ["./phyto-counting.component.scss"],
  providers: [PhytoCountingService],
})
export class PhytoCountingComponent implements OnInit, OnChanges, OnDestroy {

  public data: any;
  @ViewChild(MediasComponent) mediasComp: MediasComponent;
  @Input("value")
  set counting(value: any) {
    this.occtaxFormCountingService.counting.next(value);
  }
  @Input() stratumId: number;
  public sub: Subscription;
  @Output() lifeStageChange = new EventEmitter();

  form: UntypedFormGroup;
  get additionalFieldsForm(): any[] {
    return this.occtaxFormCountingService.additionalFieldsForm;
  }

  public nbIndiv: number = 0;
  public cdNomenclatureObjDen: string = "";

  constructor(
    public occtaxFormService: OcctaxFormService,
    public phytoOccurrenceService: PhytoOccurrenceService,
    private occtaxFormCountingService: PhytoCountingService,
    public config: ConfigService,
    public moduleService: ModuleService,
    public occtaxConfig: OcctaxConfigService
  ) { }

  // Expose enum to html
  ValidationErrorsId = ValidationErrorsId;

  ngOnInit() {
    this.form = this.occtaxFormCountingService.form;
    this.setStratum();
    this.sub = this.form
      .get("id_nomenclature_life_stage")
      .valueChanges.pipe(
        filter((idNomenclatureLifeStage) => idNomenclatureLifeStage !== null),
      )
      .subscribe((idNomenclatureLifeStage) => {
        this.phytoOccurrenceService.lifeStage.next(
          idNomenclatureLifeStage,
        );
      });
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
    this.sub?.unsubscribe();
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

  get taxref() {
    const taxref = this.phytoOccurrenceService.taxref.getValue();
    return taxref;
  }

  defaultsMedia() {
    const occtaxData = this.occtaxFormService.occtaxData.getValue();
    const taxref = this.phytoOccurrenceService.taxref.getValue();

    if (!(occtaxData && taxref)) {
      return {
        displayDetails: false,
      };
    }

    const observers =
      (occtaxData && occtaxData.releve.properties.observers) || [];
    const author = observers.map((o) => o.nom_complet).join(", ");

    const date_min =
      (occtaxData && occtaxData.releve.properties.date_min) || null;

    const cd_nom = String(taxref && taxref.cd_nom) || "";
    const lb_nom = (taxref && `${taxref.lb_nom}`) || "";
    const date_txt = date_min
      ? `${date_min.year}_${date_min.month}_${date_min.day}`
      : "";
    const date_txt2 = date_min
      ? `${date_min.day}/${date_min.month}/${date_min.year}`
      : "";

    return {
      displayDetails: false,
      author: author,
      title_fr: `${date_txt}_${lb_nom.replace(" ", "_")}_${cd_nom}`,
      description_fr: `${lb_nom} observé le ${date_txt2}`,
    };
  }

  setNbIndiv(nbIndiv: number) {
    this.nbIndiv = nbIndiv;
  }

  setCdNomenclatureObjDen(cdNomenclature: string) {
    this.cdNomenclatureObjDen = cdNomenclature;
  }
}
