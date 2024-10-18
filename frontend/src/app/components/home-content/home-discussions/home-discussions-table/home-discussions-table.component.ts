import { CommonModule } from '@angular/common';
import {
  Component,
  Input,
  Output,
  EventEmitter,
  ViewChild,
  OnInit,
  OnDestroy,
} from '@angular/core';
import { Router } from '@angular/router';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { Subject } from 'rxjs';
import { takeUntil } from 'rxjs/operators';

@Component({
  standalone: true,
  selector: 'pnx-home-discussions-table',
  templateUrl: './home-discussions-table.component.html',
  styleUrls: ['./home-discussions-table.component.scss'],
  imports: [GN2CommonModule, CommonModule],
})
export class HomeDiscussionsTableComponent implements OnInit, OnDestroy {
  readonly PROP_CREATION_DATE = 'creation_date';
  readonly PROP_USER = 'user.nom_complet';
  readonly PROP_CONTENT = 'content';
  readonly PROP_OBSERVATION = 'observation';

  discussions = [];
  currentPage = 1;
  perPage = 2;
  totalPages = 1;
  totalRows = 0;
  totalFilteredRows = 0;
  limit: number = 10;
  count: number = 0;
  offset: number = 0;
  sort = 'desc';
  orderby = this.PROP_CREATION_DATE;

  private destroy$ = new Subject<void>();

  _myReportsOnly: boolean;
  @Input()
  set myReportsOnly(value: boolean) {
    this._myReportsOnly = value;
    this._fetchDiscussions();
  }

  constructor(
    private _router: Router,
    private _syntheseApi: SyntheseDataService
  ) {}

  ngOnInit() {
    this._fetchDiscussions();
  }

  ngOnDestroy() {
    this.destroy$.next();
    this.destroy$.complete();
  }

  handlePageChange(event: any) {
    this.currentPage = event.page;
    this._fetchDiscussions();
  }

  onColumnSort(event: any) {
    this.sort = event.sorts[0].dir;
    this.orderby = event.sorts[0].prop;
    this._fetchDiscussions();
  }

  navigateToDiscussion(id_synthese: number) {
    this._router.navigate(['/synthese', 'occurrence', id_synthese, 'discussion']);
  }

  renderDate(date: string): string {
    return new Date(date).toLocaleDateString();
  }

  private _fetchDiscussions() {
    console.log('-- fetch discussions');
    const params = this._buildQueryParams();
    console.log(params);
    this._syntheseApi
      .getReports(params.toString())
      .pipe(takeUntil(this.destroy$))
      .subscribe((response) => {
        this._setDiscussions(response);
      });
  }

  private _buildQueryParams(): URLSearchParams {
    const params = new URLSearchParams();
    params.set('type', 'discussion');
    params.set('sort', this.sort);
    params.set('orderby', this.orderby);
    params.set('page', this.currentPage.toString());
    params.set('per_page', this.perPage.toString());
    params.set('my_reports', this._myReportsOnly.toString());
    return params;
  }

  // //////////////////////////////////////////////////////
  // Discussion process
  // //////////////////////////////////////////////////////
  private _setDiscussions(data: any) {
    this.discussions = this._transformDiscussions(data.items);
    this.totalRows = data.total;
    this.totalPages = data.pages;
    this.totalFilteredRows = data.total_filtered;
  }

  private _transformDiscussions(items: any[]): any[] {
    return items.map((item) => ({
      ...item,
      observation: this._formatObservation(item.synthese),
    }));
  }

  private _formatObservation(synthese: any): string {
    return `
      <strong>Nom Cité:</strong> ${synthese.nom_cite || 'N/A'}<br>
      <strong>Observateurs:</strong> ${synthese.observers || 'N/A'}<br>
      <strong>Date Observation:</strong> ${
        this._formatDateRange(synthese.date_min, synthese.date_max) || 'N/A'
      }
    `;
  }

  private _formatDateRange(dateMin: string, dateMax: string): string {
    if (!dateMin) return 'N/A';

    const formattedDateMin = this.renderDate(dateMin);
    const formattedDateMax = this.renderDate(dateMax);

    if (!dateMax || formattedDateMin === formattedDateMax) {
      return formattedDateMin || 'N/A';
    }
    return `${formattedDateMin} - ${formattedDateMax}`;
  }
}
