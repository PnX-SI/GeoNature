import { Component, OnDestroy, OnInit } from "@angular/core";
import { MatDialog } from "@angular/material/dialog";
import { TranslateService } from "@ngx-translate/core";
import { combineLatest, Subject } from "rxjs";
import { filter, takeUntil } from "rxjs/operators";
import { ConfirmationDialog } from "@geonature_common/others/modal-confirmation/confirmation.dialog";
import { DataFormService } from "@geonature_common/form/data-form.service";
import { OcctaxConfigService } from "../../../services/occtax-config.service";
import { OcctaxFormService } from "../../occtax-form.service";
import { PhytoOccurrenceService } from "../phyto-occurrence/occurrence.service"; // is it useful? can I use normal occurence service?
import { OcctaxTaxaListService } from "../../taxa-list/taxa-list.service";

interface StratumColumn {
  id: number;
  key: string;
  label: string;
}

/**
 * TODO: in the cells it should show abundance from nomenclature not count
*/

@Component({
  selector: "pnx-occtax-form-phyto-taxa-list",
  templateUrl: "./phyto-taxon.component.html",
  styleUrls: ["./phyto-taxon.component.scss"],
})
export class PhytoTaxonComponent implements OnInit, OnDestroy {
  public typeSortingTaxalist: "lexicographic" | "record" = "record";
  public sortOrder: "asc" | "desc" = "desc";
  public readonly baseColumns: string[] = ["nom_valide"];
  public strataColumns: StratumColumn[] = [];
  public displayedColumns: string[] = [...this.baseColumns, "actions"];

  private readonly destroy$ = new Subject<void>();
  private occurrences: any[] = [];
  private occurrenceInEdit: any = null;

  constructor(
    private readonly form: OcctaxFormService,
    private readonly dataFormService: DataFormService,
    public readonly occtaxTaxaListService: OcctaxTaxaListService,
    public readonly occtaxFormOccurrenceService: PhytoOccurrenceService,
    private readonly dialog: MatDialog,
    private readonly translate: TranslateService,
    public readonly occtaxConfig: OcctaxConfigService,
  ) {}

  public ngOnInit(): void {
    combineLatest([
      this.form.occtaxData.pipe(
        filter((data: any) => !!data?.releve?.properties),
      ),
      this.occtaxFormOccurrenceService.occurrence,
      this.dataFormService.getNomenclature("STRATE_VEGETATION"),
    ])
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: ([data, occurrence, nomenclature]: [any, any, any]) => {
          const properties = data.releve.properties;
          this.occurrences = properties.t_occurrences_occtax || [];
          this.occurrenceInEdit = occurrence;
          this.setStrataColumns(
            properties.t_vegetation_stratum || [],
            nomenclature.values || [],
          );
          this.refreshOccurrences();
        },
        error: (error) => {
          console.error("Error loading phyto taxon list:", error);
        },
      });
  }

  public ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  public editOccurrence(occurrence: any): void {
    this.occtaxFormOccurrenceService.occurrence.next(occurrence);
  }

  // TODO: is the dialog box how it is done otherwise?
  public deleteOccurrence(occurrence: any): void {
    const message = `${this.translate.instant("Actions.Delete")} ${this.taxonTitle(occurrence)} ?`;
    const dialogRef = this.dialog.open(ConfirmationDialog, {
      width: "350px",
      position: { top: "5%" },
      data: { message },
    });

    dialogRef.afterClosed().subscribe((result) => {
      if (result) {
        this.occtaxFormOccurrenceService.deleteOccurrence(occurrence);
      }
    });
  }

  // Not used?
  public get occIDInEdit(): number | null {
    return this.occurrenceInEdit?.id_occurrence_occtax || null;
  }

  public removeHtmlFromString(value: string | null | undefined): string {
    return value ? value.replace(/<[^>]*>/g, "") : "";
  }

  public taxonTitle(occurrence: any): string {
    return this.removeHtmlFromString(occurrence?.nom_cite);
  }

  public inProgressErrorToForm(occurrenceInProgress: any): void {
    if (occurrenceInProgress.state !== "error") {
      return;
    }

    this.editOccurrence(occurrenceInProgress.data);
    this.occtaxTaxaListService.removeOccurrenceInProgress(occurrenceInProgress.id);
  }

  public setSortType(type: "lexicographic" | "record"): void {
    if (this.typeSortingTaxalist === type) {
      return;
    }

    this.typeSortingTaxalist = type;
    this.sortOrder = type === "record" ? "desc" : "asc";
    this.refreshOccurrences();
  }

  public toggleSortOrder(): void {
    this.sortOrder = this.sortOrder === "asc" ? "desc" : "asc";
    this.refreshOccurrences();
  }

  // TODO: it is not working
  public getStratumCounts(occurrence: any, stratumId: number): string {
    const countings = (occurrence.cor_counting_occtax || []).filter(
      (counting: any) =>
        counting.id_nomenclature_vegetation_stratum === stratumId,
    );

    return countings
      .map((counting: any) => {
        const min = counting.count_min;
        const max = counting.count_max;
        if (min == null) {
          return max == null ? "" : String(max);
        }
        return max == null || min === max ? String(min) : `${min}–${max}`;
      })
      .filter((count: string) => count !== "")
      .join(", ");
  }

  // TODO: Move this to the occurence service
  private setStrataColumns(strata: any[], nomenclatures: any[]): void {
    this.strataColumns = strata
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
      .filter((column) => column.label !== "");

    this.displayedColumns = [
      ...this.baseColumns,
      ...this.strataColumns.map((column) => column.key),
      "actions",
    ];
  }

  private refreshOccurrences(): void {
    let occurrences = this.occurrences.filter((occurrence) =>
      this.occurrenceInEdit
        ? occurrence.id_occurrence_occtax !==
          this.occurrenceInEdit.id_occurrence_occtax
        : true,
    );

    if (this.typeSortingTaxalist === "lexicographic") {
      occurrences = occurrences.sort((first, second) => {
        const firstName = (
          this.removeHtmlFromString(first.nom_valide)
        ).toLowerCase();
        const secondName = (
          this.removeHtmlFromString(second.nom_valide)
        ).toLowerCase();
        return firstName.localeCompare(secondName);
      });
    }

    if (this.sortOrder === "desc") {
      occurrences.reverse();
    }

    this.occtaxTaxaListService.occurrences$.next(occurrences);
  }
}
