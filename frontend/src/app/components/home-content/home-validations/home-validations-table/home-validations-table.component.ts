import { CommonModule } from '@angular/common';
import { Component, Input, OnInit, OnDestroy } from '@angular/core';
import { Router } from '@angular/router';
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

interface ValidationItemRaw {
  id_synthese: number;
  date_max: string;
  date_min: string;
  observers: string;
  nomenclature_valid_status: { label_default: string; [key: string]: string };
  validations: {
    id_validation: number;
    validation_comment: string;
    validation_date: string;
  }[];
}
interface ValidationItem {
  id_synthese: number;
  observation: string;
  id_validation: number;
  validation_label: string;
  validation_comment: string;
  validation_date: string;
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
  readonly PROP_CREATION_DATE = 'validation_date';
  readonly PROP_USER = 'id_synthese';
  readonly PROP_VALIDATION_STATUS = 'validation_label';
  readonly PROP_VALIDATION_MESSAGE = 'validation_comment';
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

  validations: ValidationItem[] = [];
  // TODO: update this
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
  ) {}

  ngOnInit() {
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

  navigateToValidations(validation: ValidationItem) {
    this._router.navigate(
      this._homeValidations.computeValidationsRedirectionUrl(validation.id_synthese)
    );
  }

  renderDate(date: string): string {
    return new Date(date).toLocaleDateString();
  }

  private _fetchValidations() {
    const params = {
      fields:
        'id_synthese,nom_cite,observers,date_min,date_max,validations,last_validation,nomenclature_valid_status',
      format: 'json',
    };
    this._homeValidations
      .fetchValidations(params)
      .pipe(takeUntil(this.destroy$))
      .subscribe((validations: ValidationCollection) => {
        this._setValidations(validations);
      });
  }
  // //////////////////////////////////////////////////////
  // Validation process
  // //////////////////////////////////////////////////////

  private _setValidations(validations: ValidationCollection) {
    this.validations = this._transformValidations(validations.items);
    this.pagination = {
      total: validations.total,
      per_page: validations.per_page,
      page: validations.page,
    };
  }

  private _transformValidations(validations: ValidationItemRaw[]): ValidationItem[] {
    return validations.map((validation: ValidationItemRaw) => ({
      id_synthese: validation.id_synthese,
      validation_label: validation.nomenclature_valid_status.label_default ?? '',
      validation_comment: validation.validations[0].validation_comment ?? '',
      id_validation: validation.validations[0].id_validation,
      validation_date: validation.validations[0].validation_date,
      observation: this._formatObservation(validation),
    }));
  }

  private _formatObservation(validation: any): string {
    return `
      <strong>Nom Cité:</strong> ${validation.nom_cite || 'N/A'}<br>
      <strong>Observateurs:</strong> ${validation.observers || 'N/A'}<br>
      <strong>Date Observation:</strong> ${
        this._formatDateRange(validation.date_min, validation.date_max) || 'N/A'
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
