import {
  Component,
  OnInit,
  Input,
  OnDestroy,
  Output,
  EventEmitter,
} from "@angular/core";
import { UntypedFormGroup, UntypedFormArray } from "@angular/forms";
import { combineLatest, Subject, Subscription } from "rxjs";
import { filter, takeUntil } from "rxjs/operators";

import { OcctaxFormService } from "../../occtax-form.service";
import { OcctaxFormOccurrenceService } from "../../occurrence/occurrence.service";
import { PhytoCountingService } from "./counting.service";
import { ConfigService } from "@geonature/services/config.service";
import { ModuleService } from "@geonature/services/module.service";
import { DataFormService } from "@geonature_common/form/data-form.service";
import { OcctaxConfigService } from "../../../services/occtax-config.service";

import { ValidationErrorsId } from "@geonature/services/validators";
import { ViewChild } from "@angular/core";
import { MediasComponent } from "@geonature_common/form/media/medias.component";

@Component({
  selector: "pnx-occtax-form-phyto-counting",
  templateUrl: "./phyto-counting.component.html",
  styleUrls: ["./phyto-counting.component.scss"],
  providers: [PhytoCountingService],
})
export class PhytoCountingComponent implements OnInit, OnDestroy {

  public data: any;
  @ViewChild(MediasComponent) mediasComp: MediasComponent;
  @Input("value")
  set counting(value: any) {
    this.occtaxFormCountingService.counting.next(value);
  }
  public sub: Subscription;
  @Output() lifeStageChange = new EventEmitter();

  form: UntypedFormGroup;
  get additionalFieldsForm(): any[] {
    return this.occtaxFormCountingService.additionalFieldsForm;
  }

  public nbIndiv: number = 0;
  public cdNomenclatureObjDen: string = "";

  public strataNomenclatureCodes: string[] | null = null;

  private readonly destroy$ = new Subject<void>();

  constructor(
    public occtaxFormService: OcctaxFormService,
    public occtaxFormOccurrenceService: OcctaxFormOccurrenceService,
    private occtaxFormCountingService: PhytoCountingService,
    public config: ConfigService,
    public moduleService: ModuleService,
    public occtaxConfig: OcctaxConfigService,
    private readonly dataFormService: DataFormService,
  ) { }

  // Expose enum to html
  ValidationErrorsId = ValidationErrorsId;

  ngOnInit() {
    this.form = this.occtaxFormCountingService.form;
    this.sub = this.form
      .get("id_nomenclature_life_stage")
      .valueChanges.pipe(
        filter((idNomenclatureLifeStage) => idNomenclatureLifeStage !== null),
      )
      .subscribe((idNomenclatureLifeStage) => {
        this.occtaxFormOccurrenceService.lifeStage.next(
          idNomenclatureLifeStage,
        );
      });

    combineLatest([
      this.occtaxFormService.occtaxData.pipe(
        filter((data: any) => !!data?.releve?.properties),
      ),
      this.dataFormService.getNomenclature("STRATE_VEGETATION"),
    ])
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: ([data, nomenclature]: [any, any]) => {
          const properties = data.releve.properties;
          this.setStrataColumns(
            properties.t_vegetation_stratum || [],
            nomenclature.values || [],
          );
        },
        error: (error) => {
          console.error("Error loading phyto taxon list:", error);
        },
      });
  }
  validateMediasDeletions() {
    this.mediasComp?.validateDeletions();
  }

  ngOnDestroy() {
    //delete elem from form.get('cor_counting_occtax')
    const idx = (
      this.occtaxFormOccurrenceService.form.get(
        "cor_counting_occtax",
      ) as UntypedFormArray
    ).controls.findIndex((elem) => elem === this.form);
    if (idx !== -1) {
      (
        this.occtaxFormOccurrenceService.form.get(
          "cor_counting_occtax",
        ) as UntypedFormArray
      ).removeAt(idx);
    }
  }

  get taxref() {
    const taxref = this.occtaxFormOccurrenceService.taxref.getValue();
    return taxref;
  }

  defaultsMedia() {
    const occtaxData = this.occtaxFormService.occtaxData.getValue();
    const taxref = this.occtaxFormOccurrenceService.taxref.getValue();

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

  private setStrataColumns(strata: any[], nomenclatures: any[]): void {

    const stratumIds = new Set(strata
      .filter(
        (stratum) =>
          stratum.percentage_cover_vegetation_stratum != null ||
          stratum.average_height != null ||
          stratum.min_height != null ||
          stratum.max_height != null,
      )
      .map((stratum) => {
        const nomenclature = nomenclatures.find(
          (item: any) =>
            item.id_nomenclature ===
            stratum.id_nomenclature_vegetation_stratum,
        );
        return {
          id: stratum.id_nomenclature_vegetation_stratum,
          key: `stratum_${stratum.id_nomenclature_vegetation_stratum}`,
          label: nomenclature?.label_default || "",
        };
      })
      .filter((column) => column.label !== "").map((column) => column.id));
    this.strataNomenclatureCodes = nomenclatures
      .filter((item: any) => stratumIds.has(item.id_nomenclature))
      .map((item: any) => item.cd_nomenclature);
  }
}
