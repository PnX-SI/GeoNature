import {
  ChangeDetectionStrategy,
  Component,
  OnDestroy,
  OnInit,
  ViewContainerRef,
} from '@angular/core';
import { LiveAnnouncer } from '@angular/cdk/a11y';
import { BreakpointObserver, Breakpoints } from '@angular/cdk/layout';
import { MatDialog } from '@angular/material/dialog';
import { Sort } from '@angular/material/sort';
import { TranslateService } from '@ngx-translate/core';
import { combineLatest, Subject } from 'rxjs';
import { filter, map, takeUntil } from 'rxjs/operators';
import { ConfirmationDialog } from '@geonature_common/others/modal-confirmation/confirmation.dialog';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { Nomenclature } from '@geonature_common/interfaces';
import {
  NomenclatureResponse,
  Occurrence,
  PhytoData,
  PhytoDataWithProperties,
} from '../utils/interfaces';
import { OcctaxConfigService } from '../../../services/occtax-config.service';
import { OcctaxFormService } from '../../occtax-form.service';
import { PhytoOccurrenceService } from '../services/occurrence.service';
import { PhytoOccurrenceModalComponent } from '../phyto-occurrence-modal/phyto-occurrence-modal.component';
import { OcctaxTaxaListService } from '../../taxa-list/taxa-list.service';
import { getEligibleVegetationStratumRows } from '../utils/vegetation-strata.utils';
import { compareValues, getStratumAbundance } from '../utils/taxa-table.utils';

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
  public displayedColumnKeys: string[] = [...this.baseColumns, 'strata', 'comment', 'actions'];
  public isHandset$ = this.breakpointObserver
    .observe(Breakpoints.Handset)
    .pipe(map((state) => state.matches));

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
    private readonly breakpointObserver: BreakpointObserver
  ) {}

  public ngOnInit(): void {
    combineLatest([
      this.form.occtaxData.pipe(
        filter((data: PhytoData): data is PhytoDataWithProperties => !!data?.releve?.properties)
      ),
      this.occtaxFormOccurrenceService.occurrence,
      this.dataFormService.getNomenclature('STRATE_VEGETATION'),
      this.dataFormService.getNomenclature('PHYTO_ABUNDANCE'),
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
          this.liveAnnouncer.announce(
            this.translate.instant('Occtax.TaxaList.TaxonDeletedAnnouncement', {
              taxon: this.taxonTitle(occurrence),
            })
          );
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
    return getStratumAbundance(occurrence, stratumId, this.abundanceNomenclatures).label;
  }

  public getStratumAbundanceId(occurrence: Occurrence, stratumId: number): number {
    return getStratumAbundance(occurrence, stratumId, this.abundanceNomenclatures).id;
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

    this.strataColumns = getEligibleVegetationStratumRows(
      properties.t_vegetation_stratum || [],
      strataResponse.values || []
    ).map(({ id, label, mnemonique }) => ({
      id,
      key: `stratum_${id}`,
      label,
      mnemonique,
    }));
    this.displayedColumns = [
      ...this.baseColumns,
      ...this.strataColumns.map((column) => column.key),
      'comment',
      'actions',
    ];
    this.refreshOccurrences();
  }

  sortData(sort: Sort) {
    if (!sort.active || sort.direction === '') {
      this.sortDirection = 'asc';
      this.sortActiveColumn = '';
      this.refreshOccurrences();
      this.liveAnnouncer.announce(this.translate.instant('Occtax.TaxaList.SortingCleared'));
      return;
    }
    this.sortDirection = sort.direction;
    this.sortActiveColumn = sort.active;
    this.refreshOccurrences();
    this.liveAnnouncer.announce(
      this.translate.instant('Occtax.TaxaList.SortAnnouncement', {
        direction: this.translate.instant(
          sort.direction === 'asc' ? 'Occtax.TaxaList.SortAsc' : 'Occtax.TaxaList.SortDesc'
        ),
      })
    );
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
        return compareValues(
          this.getStratumAbundanceId(a, Number(this.sortActiveColumn.substring(8))),
          this.getStratumAbundanceId(b, Number(this.sortActiveColumn.substring(8))),
          isAsc
        );
      } else if (this.sortActiveColumn === 'nom_valide') {
        return compareValues(
          this.removeHtmlFromString(a.taxref?.nom_valide).toLowerCase(),
          this.removeHtmlFromString(b.taxref?.nom_valide).toLowerCase(),
          isAsc
        );
      } else {
        return compareValues(a.id_occurrence_occtax || 0, b.id_occurrence_occtax || 0, false);
      }
    });

    this.occtaxTaxaListService.occurrences$.next(sortedOccurrences);
  }

  get strataColumnKeys(): string[] {
    return this.strataColumns.map((column) => column.key);
  }
}
