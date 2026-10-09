import { Component, Input, OnDestroy, OnInit, ViewChild } from "@angular/core";
import { FormArray, FormBuilder, Validators } from "@angular/forms";
import { MatTable } from "@angular/material/table";
import { DataFormService } from "@geonature_common/form/data-form.service";
import { Subject } from "rxjs";
import { takeUntil } from "rxjs/operators";

interface IStrate {
  id_vegetation_stratum: number | null;
  id_nomenclature_vegetation_stratum?: number;
  percentage_cover_vegetation_stratum: number | null;
  average_height: number | null;
  min_height: number | null;
  max_height: number | null;
}

/**
 * This component is a form to edit the 'strates' when in the phyto module. It is used in the first 'releve' form.
 * TODO: Split the loadStrateTable method into smaller methods to improve readability and maintainability. 
 *  Make it load the nomencalture only once
 * FIX: Loosing focus on input when changing the value of a cell in the table
 */
@Component({
  selector: "pnx-occtax-form-phyto-strate",
  templateUrl: "./phyto-strate.component.html",
  styleUrls: ["./phyto-strate.component.scss"],
})
export class PhytoStrateComponent implements OnInit, OnDestroy {
  @ViewChild("strateTable", { static: true }) public table!: MatTable<any>;
  @Input() public parentFormControl!: FormArray;

  public stratesLabels: Record<string, string> = {};
  public readonly displayedColumns: string[] = [
    "label_default",
    "percentage_cover_vegetation_stratum",
    "average_height",
    "min_height",
    "max_height",
  ];

  private readonly destroy$ = new Subject<void>();

  constructor(
    private readonly fb: FormBuilder,
    private readonly dataFormS: DataFormService,
  ) {}

  public ngOnInit(): void {
    if (!this.parentFormControl) {
      return;
    }

    this.loadStrateTable();
    this.parentFormControl.valueChanges
      .pipe(takeUntil(this.destroy$))
      .subscribe(() => this.loadStrateTable());
  }

  public ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  private loadStrateTable(): void {
    if (!this.parentFormControl) {
      return;
    }

    this.dataFormS
      .getNomenclature("STRATE_VEGETATION")
      .pipe(takeUntil(this.destroy$))
      .subscribe((strateNomenclatures: any) => {
        const backendStrates = (this.parentFormControl.value ||
          []) as IStrate[];
        this.stratesLabels = {};

        const strateFormGroups = strateNomenclatures.values.map(
          (strate: any) => {
            this.stratesLabels[strate.id_nomenclature] = strate.label_default;

            const currentStrate = backendStrates.find(
              (s) =>
                s.id_nomenclature_vegetation_stratum === strate.id_nomenclature,
            ) || {
              id_vegetation_stratum: null,
              id_nomenclature_vegetation_stratum: strate.id_nomenclature,
              percentage_cover_vegetation_stratum: null,
              average_height: null,
              min_height: null,
              max_height: null,
            };

            return this.fb.group({
              id_vegetation_stratum: [currentStrate.id_vegetation_stratum],
              id_nomenclature_vegetation_stratum: [
                currentStrate.id_nomenclature_vegetation_stratum,
              ],
              percentage_cover_vegetation_stratum: [
                currentStrate.percentage_cover_vegetation_stratum,
                [Validators.min(0), Validators.max(100)],
              ],
              average_height: [
                currentStrate.average_height,
                [Validators.min(0)],
              ],
              min_height: [currentStrate.min_height, [Validators.min(0)]],
              max_height: [currentStrate.max_height, [Validators.min(0)]],
            });
          },
        );

        this.parentFormControl.clear({ emitEvent: false });
        strateFormGroups.forEach((strate) =>
          this.parentFormControl.push(strate, { emitEvent: false }),
        );

        this.table?.renderRows();
      });
  }
}
