import { ChangeDetectionStrategy, Component, OnDestroy, OnInit, ViewContainerRef } from '@angular/core';
import { LiveAnnouncer } from '@angular/cdk/a11y';
import { MatDialog } from '@angular/material/dialog';
import { Sort } from '@angular/material/sort';
import { TranslateService } from '@ngx-translate/core';
import { combineLatest, Subject } from 'rxjs';
import { filter, takeUntil } from 'rxjs/operators';
import { ConfirmationDialog } from '@geonature_common/others/modal-confirmation/confirmation.dialog';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { Nomenclature } from '@geonature_common/interfaces'
import { VegetationStratum, Counting, Occurrence } from '../interfaces';
import { OcctaxConfigService } from '../../../services/occtax-config.service';
import { OcctaxFormService } from '../../occtax-form.service';
import { PhytoOccurrenceService } from '../services/occurrence.service';
import { PhytoOccurrenceModalComponent } from '../phyto-occurrence-modal/phyto-occurrence-modal.component';
import { OcctaxTaxaListService } from '../../taxa-list/taxa-list.service';

interface StratumColumn {
  id: number;
  key: string;
  label: string;
  mnemonique: string;
}
interface OccurrenceInProgress {
  id: number;
  state: 'in_progress' | 'error';
  data: Occurrence;
}
interface PhytoProperties {
  t_occurrences_occtax?: Occurrence[];
  t_vegetation_stratum?: VegetationStratum[];
}
interface PhytoData {
  releve?: { properties?: PhytoProperties };
}
interface PhytoDataWithProperties extends PhytoData {
  releve: { properties: PhytoProperties };
}
interface NomenclatureResponse {
  values: Nomenclature[];
}

function compare(a: number | string, b: number | string, isAsc: boolean) {
  return (a < b ? -1 : 1) * (isAsc ? 1 : -1);
}

/**
 * Coordinates phyto occurrence display, sorting, editing and deletion.
 * Stratum columns are derived from releve data; abundance codes are resolved
 * from the counting nomenclature lookup.
 * 
 * TODO: [Angular Material v15 / Architecture] Consider migrate to Standalone Component
 * TODO: [Angular Material v15 / Table Architecture] Consider migrating to MatTableDataSource<PhytoOccurrence> with custom sortingDataAccessor to cleanly delegate matSort interactions.
 */
@Component({
  selector: 'pnx-phyto-taxa-table',
  templateUrl: './phyto-taxa-table.component.html',
  styleUrls: ['./phyto-taxa-table.component.scss', '../../taxa-list/taxa-list.component.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class PhytoTaxaTableComponent implements OnInit, OnDestroy {
  /** Current sort mode and direction shown by the table controls. */
  public sortActiveColumn: string = '';
  public sortDirection: 'asc' | 'desc' = 'desc';

  /** Columns that are always present, before dynamic stratum columns. */
  public readonly baseColumns: string[] = ['nom_valide'];
  public strataColumns: StratumColumn[] = [];
  public displayedColumns: string[] = [...this.baseColumns, 'comment', 'actions'];

  private readonly destroy$ = new Subject<void>();
  /** Local snapshot used to reapply sorting when UI sort settings change. */
  private occurrences: Occurrence[] = [];
  private occurrenceInEdit: Occurrence | null = null;
  private abundanceNomenclatures = new Map<number, Nomenclature>();

  constructor(
    private readonly form: OcctaxFormService,
    private readonly dataFormService: DataFormService,
    public readonly occtaxTaxaListService: OcctaxTaxaListService,
    public readonly occtaxFormOccurrenceService: PhytoOccurrenceService,
    private readonly dialog: MatDialog,
    private readonly viewContainerRef: ViewContainerRef,
    private readonly translate: TranslateService,
    public readonly occtaxConfig: OcctaxConfigService,
    private readonly liveAnnouncer: LiveAnnouncer,
  ) { }

  public ngOnInit(): void {
    combineLatest([
      this.form.occtaxData.pipe(
        filter((data: PhytoData): data is PhytoDataWithProperties => !!data?.releve?.properties)
      ),
      this.occtaxFormOccurrenceService.occurrence,
      this.dataFormService.getNomenclature('STRATE_VEGETATION'),
      this.dataFormService.getNomenclature('BRAUNBARK'),
    ])
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: ([data, occurrence, strataResponse, abundanceResponse]: [
          PhytoDataWithProperties,
          Occurrence | null,
          NomenclatureResponse,
          NomenclatureResponse,
        ]) => {
          this.updateTableData(data, occurrence, strataResponse, abundanceResponse);
        },
        error: (error: unknown) => {
          console.error('Error loading phyto taxon list:', error);
        },
      });
  }

  public ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  public editOccurrence(occurrence: Occurrence): void {
    this.occtaxFormOccurrenceService.occurrence.next(occurrence);
  }

  public openOccurrenceModal(occurrence: Occurrence): void {
    this.dialog.open(PhytoOccurrenceModalComponent, {
      data: { occurrence },
      viewContainerRef: this.viewContainerRef,
      hasBackdrop: true,
      disableClose: true,
    });
  }

  public deleteOccurrence(occurrence: Occurrence): void {
    const message = `${this.translate.instant('Actions.Delete')} ${this.taxonTitle(occurrence)} ?`;
    this.dialog
      .open(ConfirmationDialog, {
        width: '350px',
        position: { top: '5%' },
        data: { message },
      })
      .afterClosed()
      .pipe(takeUntil(this.destroy$))
      .subscribe((confirmed: boolean) => {
        if (confirmed) {
          this.occtaxFormOccurrenceService.deleteOccurrence(occurrence);
          this.liveAnnouncer.announce(`${this.taxonTitle(occurrence)} deleted`);
        }
      });
  }

  public removeHtmlFromString(value: string | null | undefined): string {
    return value ? value.replace(/<[^>]*>/g, '') : '';
  }

  public taxonTitle(occurrence: Occurrence | null | undefined): string {
    return this.removeHtmlFromString(occurrence?.nom_cite);
  }

  public inProgressErrorToForm(occurrenceInProgress: OccurrenceInProgress): void {
    if (occurrenceInProgress.state !== 'error') {
      return;
    }

    this.editOccurrence(occurrenceInProgress.data);
    this.occtaxTaxaListService.removeOccurrenceInProgress(occurrenceInProgress.id);
  }

  public getStratumAbundance(occurrence: Occurrence, stratumId: number): string {
    const abundanceCodes: string[] = [];
    for (const counting of occurrence.cor_counting_occtax || []) {
      if (
        counting.id_nomenclature_vegetation_stratum !== stratumId ||
        counting.id_nomenclature_phytosociological_abundance == null
      ) {
        continue;
      }

      const abundanceCode = this.abundanceNomenclatures.get(
        counting.id_nomenclature_phytosociological_abundance
      )?.cd_nomenclature;
      if (abundanceCode) {
        abundanceCodes.push(abundanceCode);
      }
    }

    return abundanceCodes.join(', ');
  }

  public getStratumAbundanceId(occurrence: Occurrence, stratumId: number): number {
    const abundanceIds: number[] = [];
    for (const counting of occurrence.cor_counting_occtax || []) {
      if (
        counting.id_nomenclature_vegetation_stratum !== stratumId ||
        counting.id_nomenclature_phytosociological_abundance == null
      ) {
        continue;
      }
      const abundanceId = counting.id_nomenclature_phytosociological_abundance;
      if (abundanceId) {
        abundanceIds.push(abundanceId);
      }
    }
    if (abundanceIds.length !== 1) {
      return -1;
    } else {
      return abundanceIds[0];
    }

  }

  public getOccurrenceComment(occurrence: Occurrence): string {
    return this.removeHtmlFromString(occurrence.comment);
  }

  private updateTableData(
    data: PhytoDataWithProperties,
    occurrence: Occurrence | null,
    strataResponse: NomenclatureResponse,
    abundanceResponse: NomenclatureResponse
  ): void {
    const properties = data.releve.properties;
    this.occurrences = properties.t_occurrences_occtax || [];
    this.occurrenceInEdit = occurrence;
    this.abundanceNomenclatures = new Map(
      (abundanceResponse.values || []).map((nomenclature) => [
        nomenclature.id_nomenclature,
        nomenclature,
      ])
    );

    this.setStrataColumns(properties.t_vegetation_stratum || [], strataResponse.values || []);
    this.refreshOccurrences();
  }

  private setStrataColumns(strata: VegetationStratum[], nomenclatures: Nomenclature[]): void {
    const labelById = new Map(
      nomenclatures.map((nomenclature) => [
        nomenclature.id_nomenclature,
        nomenclature.label_default,
      ])
    );
    const mnemoById = new Map(
      nomenclatures.map((nomenclature) => [
        nomenclature.id_nomenclature,
        nomenclature.mnemonique,
      ])
    );

    this.strataColumns = strata
      .filter(
        (stratum): stratum is VegetationStratum & { id_nomenclature_vegetation_stratum: number } =>
          stratum.id_nomenclature_vegetation_stratum != null &&
          (stratum.percentage_cover_vegetation_stratum != null ||
            stratum.average_height != null ||
            stratum.min_height != null ||
            stratum.max_height != null)
      )
      .map((stratum) => {
        const id = stratum.id_nomenclature_vegetation_stratum;
        return {
          id,
          key: `stratum_${id}`,
          label: labelById.get(id) || '',
          mnemonique: mnemoById.get(id) || '',
        };
      })
      .filter((column) => column.label !== '')
      .sort((a, b) => a.id - b.id);

    this.displayedColumns = [
      ...this.baseColumns,
      ...this.strataColumns.map((column) => column.key),
      'comment',
      'actions',
    ];
  }

  sortData(sort: Sort) {
    if (!sort.active || sort.direction === '') {
      this.sortDirection = 'asc'
      this.sortActiveColumn = '';
      this.refreshOccurrences();
      this.liveAnnouncer.announce('Sorting cleared');
      return;
    }
    this.sortDirection = sort.direction
    this.sortActiveColumn = sort.active;
    this.refreshOccurrences();
    this.liveAnnouncer.announce(`Sorted ${sort.direction === 'asc' ? 'ascending' : 'descending'}`);
  }

  private refreshOccurrences(): void {
    const filteredOccurrences = this.occurrences.filter(
      (occurrence) =>
        !this.occurrenceInEdit ||
        occurrence.id_occurrence_occtax !== this.occurrenceInEdit.id_occurrence_occtax
    );

    const sortedOccurrences = [...filteredOccurrences];

    sortedOccurrences.sort((a, b) => {
      const isAsc = this.sortDirection === 'asc';
      if (this.sortActiveColumn.includes('stratum')) {
        return compare(
          this.getStratumAbundanceId(a, Number(this.sortActiveColumn.substring(8))),
          this.getStratumAbundanceId(b, Number(this.sortActiveColumn.substring(8))),
          isAsc
        );
      } else if (this.sortActiveColumn === 'nom_valide') {
        return compare(this.removeHtmlFromString(a.taxref?.nom_valide).toLowerCase(), this.removeHtmlFromString(b.taxref?.nom_valide).toLowerCase(), isAsc);
      } else {
        return compare(a.id_occurrence_occtax || 0, b.id_occurrence_occtax || 0, false);
      }

    });

    this.occtaxTaxaListService.occurrences$.next(sortedOccurrences);
  }
}