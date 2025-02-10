import { CommonModule } from '@angular/common';
import { Component, Input, OnInit, OnDestroy } from '@angular/core';
import { Router } from '@angular/router';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { Subject } from 'rxjs';
import { takeUntil } from 'rxjs/operators';
import {
  HomeValidationsService,
  Pagination,
  ValidationCollection,
} from '../home-validations.service';

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
  readonly PROP_VALIDATION_STATUS = 'validation_status';
  readonly PROP_VALIDATION_MESSAGE = 'validation_message';
  readonly PROP_OBSERVATION = 'observation';

  readonly DEFAULT_PAGINATION: Pagination = {
    total: 0,
    page: 1,
    per_page: 4,
  };
  readonly DEFAULT_SORTING: SortingItem = {
    sort: 'desc',
    orderby: this.PROP_CREATION_DATE,
  };

  validations = [];
  pagination: Pagination = this.DEFAULT_PAGINATION;
  sort: SortingItem = this.DEFAULT_SORTING;

  private destroy$ = new Subject<void>();

  _myValidationsOnly: boolean = false;
  @Input()
  set myReportsOnly(value: boolean) {
    this.pagination = this.DEFAULT_PAGINATION;
    this._myValidationsOnly = value;
    this._fetchValidations();
  }

  constructor(
    private _router: Router,
    // private _syntheseApi: SyntheseDataService
    private _homeValidations: HomeValidationsService
  ) {
    console.log('fetccccch');
  }

  ngOnInit() {
    console.log('fetching validations');
    this._fetchValidations();
  }

  ngOnDestroy() {
    this.destroy$.next();
    this.destroy$.complete();
  }

  onChangePage(event: any) {
    this.pagination.page = event.offset + 1;
    this._fetchValidations();
  }

  onColumnSort(event: any) {
    this.sort = {
      sort: event.newValue,
      orderby: event.column.prop,
    };
    this.pagination.page = 1;
    this._fetchValidations();
  }

  // navigateToValidations(id_synthese: number) {
  //   this._router.navigate(this._homeValidations.computeValidationsRedirectionUrl(id_synthese));
  // }

  renderDate(date: string): string {
    return new Date(date).toLocaleDateString();
  }

  private _fetchValidations() {
    const params = this._buildQueryParams();
    this._homeValidations
      .fetchValidations(params)
      .pipe(takeUntil(this.destroy$))
      .subscribe((validations: ValidationCollection) => {
        this._setValidations(validations);
      });
  }

  private _buildQueryParams(): URLSearchParams {
    const params = new URLSearchParams();
    // params.set('type', 'discussion');
    // params.set('sort', this.sort.sort);
    // params.set('orderby', this.sort.orderby);
    // params.set('page', this.pagination.currentPage.toString());
    // params.set('per_page', this.pagination.perPage.toString());
    // params.set('my_validations', this._myValidationsOnly.toString());
    return params;
  }

  // //////////////////////////////////////////////////////
  // Validation process
  // //////////////////////////////////////////////////////

  private _setValidations(validations: ValidationCollection) {
    console.log(validations);
    this.validations = this._transformValidations(validations.items);
    this.pagination = {
      total: validations.total,
      per_page: validations.per_page,
      page: validations.page,
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
