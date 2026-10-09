import { Component, OnInit, OnDestroy, Input } from "@angular/core";
import {
  FormArray,
  FormBuilder,
  Validators,
  UntypedFormGroup,
} from "@angular/forms";
import { combineLatest, Subject } from "rxjs";
import { takeUntil, filter } from "rxjs/operators";
import { OcctaxFormService } from "../../../occtax-form.service";
import { DataFormService } from "@geonature_common/form/data-form.service";

/*** Component used in "Relevé phytosocio" tab
 * 08/10/2026: currently just a table header
 */

@Component({
  selector: "pnx-occtax-form-phyto-taxon",
  templateUrl: "./phyto-taxon.component.html",
  styleUrls: ["./phyto-taxon.component.scss"],
})
export class PhytoTaxonComponent implements OnInit, OnDestroy {
  public occurrenceForm: UntypedFormGroup;
  public strateNomenclatures: any;
  public editedRow: number = -1;
  public releve: any;
  public rows: FormArray;

  private destroy$ = new Subject<void>();

  public baseColumns: string[] = ["nom_valide", "nom_cite"];
  public strateColumns: string[] = [];
  public displayedColumns: string[] = [];

  // constructor: Angular 16 plutôt?
  constructor(
    public form: OcctaxFormService,
    private fb: FormBuilder,
    private dataFormS: DataFormService,
  ) {}

  public ngOnInit(): void {
    this.rows = this.fb.array([]);

    combineLatest([
      this.form.occtaxData.pipe(filter((value: any) => !!value)),
      this.dataFormS.getNomenclature("STRATE_VEGETATION"),
    ])
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: ([value, strateNomenclatures]) => {
          this.releve = value.releve.properties;
          this.strateNomenclatures = strateNomenclatures.values;
          const strates = this.releve.t_vegetation_stratum;

          for (let s of strates) {
            if (
              s.average_height !== null ||
              s.max_height !== null ||
              s.min_height !== null ||
              s.percentage_cover_vegetation_stratum !== null
            ) {
              let strateNomenclature = this.strateNomenclatures.find(
                (n: any) =>
                  n.id_nomenclature === s.id_nomenclature_vegetation_stratum,
              );

              this.strateColumns.push(strateNomenclature.label_default);
            }
          }
          this.displayedColumns = [
            ...this.baseColumns,
            ...this.strateColumns,
            "actions",
          ];
        },
        error: (err) => console.error("Erreur:", err),
      });
  }

  public ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }
}
