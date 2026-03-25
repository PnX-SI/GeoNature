import { CommonModule } from '@angular/common';
import {
  Component,
  EventEmitter,
  Input,
  OnChanges,
  OnDestroy,
  Output,
  SimpleChanges,
} from '@angular/core';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { ConfigService } from '@geonature/services/config.service';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { Subject } from 'rxjs';
import { takeUntil } from 'rxjs/operators';

interface HomeContentListObservationItem {
  id_synthese: number;
  cd_nom?: number | null;
  nom_vern_or_lb_nom: string;
  date_min: string | null;
  observers: string | null;
  [key: string]: unknown;
}

interface HomeContentListObservationColumn {
  name: string;
  prop: string;
}

@Component({
  standalone: true,
  selector: 'pnx-home-content-list-obs-list',
  templateUrl: './home-content-list-obs-list.component.html',
  styleUrls: ['./home-content-list-obs-list.component.scss'],
  imports: [GN2CommonModule, CommonModule],
})
export class HomeContentListObsListComponent implements OnChanges, OnDestroy {
  readonly pageSize = 9;

  tableRows: HomeContentListObservationItem[] = [];
  private readonly _destroy$ = new Subject<void>();
  private readonly _taxonThumbnailUrls = new Map<number, string | null>();
  private readonly _loadingTaxonThumbnailIds = new Set<number>();
  @Input() observations: HomeContentListObservationItem[] = [];
  @Input() isLoading = false;
  @Input() currentPage = 0;
  @Input() selectedObservationId: number | null = null;
  @Output() pageChange = new EventEmitter<number>();
  @Output() observationSelect = new EventEmitter<number>();

  constructor(
    private readonly config: ConfigService,
    private readonly _dataFormService: DataFormService
  ) {}

  ngOnChanges(changes: SimpleChanges) {
    if (changes.observations || changes.selectedObservationId) {
      this.tableRows = [...this.observations];
      this._prefetchTaxonThumbnails();
    }
  }

  ngOnDestroy() {
    this._destroy$.next();
    this._destroy$.complete();
  }

  get columns(): HomeContentListObservationColumn[] {
    const configuredColumns = this.config.FRONTEND?.LIST_LAST_OBS_CONFIG?.COLUMNS;
    return Array.isArray(configuredColumns) ? configuredColumns : [];
  }

  onPage(event: any) {
    this.pageChange.emit(event.offset);
  }

  onActivate(event: any) {
    if (event.type !== 'click' || !event.row?.id_synthese) {
      return;
    }

    this.observationSelect.emit(event.row.id_synthese);
  }

  getRowClass = (row: HomeContentListObservationItem) => {
    return {
      'is-selected': row.id_synthese === this.selectedObservationId,
    };
  };

  hasTaxonThumbnail(row: HomeContentListObservationItem): boolean {
    return typeof row.cd_nom === 'number' && !!this._taxonThumbnailUrls.get(row.cd_nom);
  }

  getTaxonThumbnailUrl(row: HomeContentListObservationItem): string {
    return typeof row.cd_nom === 'number' ? this._taxonThumbnailUrls.get(row.cd_nom) ?? '' : '';
  }

  private _prefetchTaxonThumbnails() {
    const taxonIds = new Set(
      this.tableRows
        .map((row) => row.cd_nom)
        .filter((cdNom): cdNom is number => typeof cdNom === 'number')
    );

    taxonIds.forEach((cdNom) => {
      if (this._taxonThumbnailUrls.has(cdNom) || this._loadingTaxonThumbnailIds.has(cdNom)) {
        return;
      }

      this._loadingTaxonThumbnailIds.add(cdNom);
      this._dataFormService
        .getTaxonInfo(cdNom, ['medias', 'cd_nom'])
        .pipe(takeUntil(this._destroy$))
        .subscribe({
          next: (taxonAttrAndMedias) => {
            const media = taxonAttrAndMedias['medias']?.find(
              (m) => m.id_type == this.config.TAXHUB.ID_TYPE_MAIN_PHOTO
            );
            const mediaUrl = media
              ? `${this._dataFormService.getTaxhubAPI()}/tmedias/thumbnail/${media.id_media}?h=96&w=96`
              : null;
            this._taxonThumbnailUrls.set(cdNom, mediaUrl);
            this._loadingTaxonThumbnailIds.delete(cdNom);
          },
          error: () => {
            this._taxonThumbnailUrls.set(cdNom, null);
            this._loadingTaxonThumbnailIds.delete(cdNom);
          },
        });
    });
  }

  getCellValue(row: HomeContentListObservationItem, prop: string): string | number {
    if (prop === 'date_min') {
      return this.renderDate(row.date_min);
    }

    const value = row[prop];
    return typeof value === 'string' || typeof value === 'number' ? value : '';
  }

  renderDate(date: string | null): string {
    return date ? new Date(date).toLocaleDateString() : '';
  }
}
