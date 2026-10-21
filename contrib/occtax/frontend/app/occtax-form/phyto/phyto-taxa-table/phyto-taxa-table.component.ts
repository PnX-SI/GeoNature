import { Component, OnDestroy, OnInit, ViewContainerRef } from '@angular/core';
import { MatDialog } from '@angular/material/dialog';
import { TranslateService } from '@ngx-translate/core';
import { combineLatest, Subject } from 'rxjs';
import { filter, takeUntil } from 'rxjs/operators';
import { ConfirmationDialog } from '@geonature_common/others/modal-confirmation/confirmation.dialog';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { OcctaxConfigService } from '../../../services/occtax-config.service';
import { OcctaxFormService } from '../../occtax-form.service';
import { PhytoOccurrenceService } from '../phyto-occurrence/occurrence.service';
import { PhytoOccurrenceModalComponent } from '../phyto-occurrence-modal/phyto-occurrence-modal.component';
import { OcctaxTaxaListService } from '../../taxa-list/taxa-list.service';

interface VegetationStratum {
  id_nomenclature_vegetation_stratum?: number | null;
  percentage_cover_vegetation_stratum?: number | null;
  average_height?: number | null;
  min_height?: number | null;
  max_height?: number | null;
}

interface Counting {
  id_nomenclature_vegetation_stratum?: number | null;
  id_nomenclature_phytosociological_abundance?: number | null;
}

interface PhytoOccurrence {
  id_occurrence_occtax?: number | null;
  nom_cite?: string | null;
  nom_valide?: string | null;
  comment?: string | null;
  taxref?: { nom_valide?: string | null } | null;
  cor_counting_occtax?: Counting[] | null;
}

interface Nomenclature {
  id_nomenclature: number;
  label_default: string;
  cd_nomenclature?: string;
  mnemonique: string;
}

interface StratumColumn {
  id: number;
  key: string;
  label: string;
  mnemonique: string;
}

interface OccurrenceInProgress {
  id: number;
  state: 'in_progress' | 'error';
  data: PhytoOccurrence;
}

interface PhytoProperties {
  t_occurrences_occtax?: PhytoOccurrence[];
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

/**
 * Coordinates phyto occurrence display, sorting, editing and deletion.
 * Stratum columns are derived from releve data; abundance codes are resolved
 * from the counting nomenclature lookup.
 */
@Component({
  selector: 'pnx-phyto-taxa-table',
  templateUrl: './phyto-taxa-table.component.html',
  styleUrls: ['./phyto-taxa-table.component.scss', '../../taxa-list/taxa-list.component.scss'],
})
export class PhytoTaxaTableComponent implements OnInit, OnDestroy {
  /** Current sort mode and direction shown by the table controls. */
  public typeSortingTaxalist: 'lexicographic' | 'record' = 'record';
  public sortOrder: 'asc' | 'desc' = 'desc';

  /** Columns that are always present, before dynamic stratum columns. */
  public readonly baseColumns: string[] = ['nom_valide'];
  public strataColumns: StratumColumn[] = [];
  public displayedColumns: string[] = [...this.baseColumns, 'comment', 'actions'];

  private readonly destroy$ = new Subject<void>();
  /** Local snapshot used to reapply sorting when UI sort settings change. */
  private occurrences: PhytoOccurrence[] = [];
  private occurrenceInEdit: PhytoOccurrence | null = null;
  private abundanceNomenclatures = new Map<number, Nomenclature>();

  constructor(
    private readonly form: OcctaxFormService,
    private readonly dataFormService: DataFormService,
    public readonly occtaxTaxaListService: OcctaxTaxaListService,
    public readonly occtaxFormOccurrenceService: PhytoOccurrenceService,
    private readonly dialog: MatDialog,
    private readonly viewContainerRef: ViewContainerRef,
    private readonly translate: TranslateService,
    public readonly occtaxConfig: OcctaxConfigService
  ) {}

  /** Subscribe to releve, occurrence-edit and nomenclature data for this table. */
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
          PhytoOccurrence | null,
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

  /** Release subscriptions owned by this component. */
  public ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  public editOccurrence(occurrence: PhytoOccurrence): void {
    this.occtaxFormOccurrenceService.occurrence.next(occurrence);
  }

  public openOccurrenceModal(occurrence: PhytoOccurrence): void {
    this.dialog.open(PhytoOccurrenceModalComponent, {
      data: { occurrence },
      viewContainerRef: this.viewContainerRef,
      hasBackdrop: true,
      disableClose: true,
    });
  }

  public deleteOccurrence(occurrence: PhytoOccurrence): void {
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
        }
      });
  }

  public removeHtmlFromString(value: string | null | undefined): string {
    return value ? value.replace(/<[^>]*>/g, '') : '';
  }

  public taxonTitle(occurrence: PhytoOccurrence | null | undefined): string {
    return this.removeHtmlFromString(occurrence?.nom_cite);
  }

  public inProgressErrorToForm(occurrenceInProgress: OccurrenceInProgress): void {
    if (occurrenceInProgress.state !== 'error') {
      return;
    }

    this.editOccurrence(occurrenceInProgress.data);
    this.occtaxTaxaListService.removeOccurrenceInProgress(occurrenceInProgress.id);
  }

  public setSortType(type: 'lexicographic' | 'record'): void {
    if (this.typeSortingTaxalist === type) {
      return;
    }

    this.typeSortingTaxalist = type;
    this.sortOrder = type === 'record' ? 'desc' : 'asc';
    this.refreshOccurrences();
  }

  public toggleSortOrder(): void {
    this.sortOrder = this.sortOrder === 'asc' ? 'desc' : 'asc';
    this.refreshOccurrences();
  }

  public getStratumAbundance(occurrence: PhytoOccurrence, stratumId: number): string {
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

  public getOccurrenceComment(occurrence: PhytoOccurrence): string {
    return this.removeHtmlFromString(occurrence.comment);
  }

  /** Refresh local lookup data and visible rows after source data changes. */
  private updateTableData(
    data: PhytoDataWithProperties,
    occurrence: PhytoOccurrence | null,
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

  /** Build labeled columns only for strata with recorded vegetation values. */
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
      .filter((column) => column.label !== '');

    this.displayedColumns = [
      ...this.baseColumns,
      ...this.strataColumns.map((column) => column.key),
      'comment',
      'actions',
    ];
  }

  /** Exclude the occurrence being edited and publish a freshly sorted array. */
  private refreshOccurrences(): void {
    const filteredOccurrences = this.occurrences.filter(
      (occurrence) =>
        !this.occurrenceInEdit ||
        occurrence.id_occurrence_occtax !== this.occurrenceInEdit.id_occurrence_occtax
    );

    const sortedOccurrences = [...filteredOccurrences];
    if (this.typeSortingTaxalist === 'lexicographic') {
      sortedOccurrences.sort((first, second) =>
        this.removeHtmlFromString(first.nom_valide)
          .toLowerCase()
          .localeCompare(this.removeHtmlFromString(second.nom_valide).toLowerCase())
      );
    }

    if (this.sortOrder === 'desc') {
      sortedOccurrences.reverse();
    }

    this.occtaxTaxaListService.occurrences$.next(sortedOccurrences);
  }
}
