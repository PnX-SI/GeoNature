import { CommonModule } from '@angular/common';
import { Component, Input, OnInit, OnDestroy } from '@angular/core';
import { Router } from '@angular/router';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { Subject } from 'rxjs';
import { takeUntil } from 'rxjs/operators';
import { HomeValidationsService } from '../home-validations.service';

interface PaginationItem {
  totalItems: number;
  currentPage: number;
  perPage: number;
}

interface SortingItem {
  sort: 'asc' | 'desc';
  orderby: string;
}

@Component({
  standalone: true,
  selector: 'pnx-home-validations-table',
  templateUrl: './home-validations-table.component.html',
  styleUrls: ['./home-validations-table.component.scss'],
  imports: [GN2CommonModule, CommonModule],
  providers: [HomeValidationsService],
})
export class HomeValidationsTableComponent implements OnInit, OnDestroy {
  readonly PROP_CREATION_DATE = 'creation_date';
  readonly PROP_USER = 'user.nom_complet';
  readonly PROP_CONTENT = 'content';
  readonly PROP_OBSERVATION = 'observation';

  readonly DEFAULT_PAGINATION: PaginationItem = {
    totalItems: 0,
    currentPage: 1,
    perPage: 4,
  };
  readonly DEFAULT_SORTING: SortingItem = {
    sort: 'desc',
    orderby: this.PROP_CREATION_DATE,
  };

  validations = [];
  pagination: PaginationItem = this.DEFAULT_PAGINATION;
  sort: SortingItem = this.DEFAULT_SORTING;

  private destroy$ = new Subject<void>();

  _myReportsOnly: boolean;
  @Input()
  set myReportsOnly(value: boolean) {
    this.pagination = this.DEFAULT_PAGINATION;
    this._myReportsOnly = value;
    this._fetchValidations();
  }

  constructor(
    private _router: Router,
    private _syntheseApi: SyntheseDataService,
    private _homeValidations: HomeValidationsService
  ) {}

  ngOnInit() {
    this._fetchValidations();
  }

  ngOnDestroy() {
    this.destroy$.next();
    this.destroy$.complete();
  }

  onChangePage(event: any) {
    this.pagination.currentPage = event.offset + 1;
    this._fetchValidations();
  }

  onColumnSort(event: any) {
    this.sort = {
      sort: event.newValue,
      orderby: event.column.prop,
    };
    this.pagination.currentPage = 1;
    this._fetchValidations();
  }

  navigateToDiscussion(id_synthese: number) {
    this._router.navigate(this._homeValidations.computeValidationsRedirectionUrl(id_synthese));
  }

  renderDate(date: string): string {
    return new Date(date).toLocaleDateString();
  }

  private _fetchValidations() {
    const params = this._buildQueryParams();
    this._syntheseApi
      .getReports(params.toString())
      .pipe(takeUntil(this.destroy$))
      .subscribe((response) => {
        this._setValidations(response);
      });
  }

  private _buildQueryParams(): URLSearchParams {
    const params = new URLSearchParams();
    params.set('type', 'discussion');
    params.set('sort', this.sort.sort);
    params.set('orderby', this.sort.orderby);
    params.set('page', this.pagination.currentPage.toString());
    params.set('per_page', this.pagination.perPage.toString());
    params.set('my_reports', this._myReportsOnly.toString());
    return params;
  }

  // //////////////////////////////////////////////////////
  // Discussion process
  // //////////////////////////////////////////////////////
  private _setValidations(data: any) {
    this.validations = this._transformValidations(data.items);
    this.pagination = {
      totalItems: data.total,
      currentPage: data.page,
      perPage: data.per_page,
    };
  }

  private _transformValidations(items: any[]): any[] {
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
