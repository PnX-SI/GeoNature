import { CommonModule } from '@angular/common';
import { Component, Input, OnInit, OnDestroy } from '@angular/core';
import { Router } from '@angular/router';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { Subject } from 'rxjs';
import { takeUntil } from 'rxjs/operators';
import { HomeDiscussionsService } from '../home-discussions.service';
import { SyntheseDataPaginationItem } from '@geonature_common/form/synthese-form/synthese-data-pagination-item';
import {
  SORT_ORDER,
  SyntheseDataSortItem,
} from '@geonature_common/form/synthese-form/synthese-data-sort-item';

@Component({
  standalone: true,
  selector: 'pnx-home-discussions-table',
  templateUrl: './home-discussions-table.component.html',
  styleUrls: ['./home-discussions-table.component.scss'],
  imports: [GN2CommonModule, CommonModule],
  providers: [HomeDiscussionsService],
})
export class HomeDiscussionsTableComponent implements OnInit, OnDestroy {
  readonly PROP_CREATION_DATE = 'creation_date';
  readonly PROP_USER = 'user.nom_complet';
  readonly PROP_CONTENT = 'content';
  readonly PROP_OBSERVATION = 'observation';

  readonly DEFAULT_PAGINATION: SyntheseDataPaginationItem = {
    totalItems: 0,
    currentPage: 1,
    perPage: 4,
  };
  readonly DEFAULT_SORTING: SyntheseDataSortItem = {
    sortOrder: SORT_ORDER.DESC,
    sortBy: this.PROP_CREATION_DATE,
  };

  static readonly DEFAULT_MY_REPORTS_ONLY: boolean = false;

  discussions = [];
  pagination: SyntheseDataPaginationItem = this.DEFAULT_PAGINATION;
  sort: SyntheseDataSortItem = this.DEFAULT_SORTING;

  private destroy$ = new Subject<void>();

  _myReportsOnly: boolean = HomeDiscussionsTableComponent.DEFAULT_MY_REPORTS_ONLY;
  @Input()
  set myReportsOnly(value: boolean) {
    if (this._myReportsOnly == value) {
      return;
    }
    this.pagination = this.DEFAULT_PAGINATION;
    this._myReportsOnly = value;
    this._fetchDiscussions();
  }

  constructor(
    private _router: Router,
    private _syntheseApi: SyntheseDataService,
    private _homeDiscussions: HomeDiscussionsService
  ) {}

  ngOnInit() {
    this._fetchDiscussions();
  }

  ngOnDestroy() {
    this.destroy$.next();
    this.destroy$.complete();
  }

  onChangePage(event: any) {
    this.pagination.currentPage = event.offset + 1;
    this._fetchDiscussions();
  }

  onColumnSort(event: any) {
    this.sort = {
      sortBy: event.newValue,
      sortOrder: event.column.prop,
    };
    this.pagination.currentPage = 1;
    this._fetchDiscussions();
  }

  navigateToDiscussion(id_synthese: number) {
    this._router.navigate(this._homeDiscussions.computeDiscussionsRedirectionUrl(id_synthese));
  }

  renderDate(date: string): string {
    return new Date(date).toLocaleDateString();
  }

  private _fetchDiscussions() {
    const params = this._buildQueryParams();
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
    params.set('sort', this.sort.sortOrder);
    params.set('orderby', this.sort.sortBy);
    params.set('page', this.pagination.currentPage.toString());
    params.set('per_page', this.pagination.perPage.toString());
    params.set('my_reports', this._myReportsOnly.toString());
    return params;
  }

  // //////////////////////////////////////////////////////
  // Discussion process
  // //////////////////////////////////////////////////////
  private _setDiscussions(data: any) {
    this.discussions = this._transformDiscussions(data.items);
    this.pagination = {
      totalItems: data.total,
      currentPage: data.page,
      perPage: data.per_page,
    };
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
