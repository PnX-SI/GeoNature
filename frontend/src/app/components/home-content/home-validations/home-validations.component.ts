import { CommonModule } from '@angular/common';
import { Component, Input, OnInit, OnDestroy } from '@angular/core';
import { Router } from '@angular/router';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { Subject } from 'rxjs';
import { takeUntil } from 'rxjs/operators';
import {
  HomeValidationsService,
  Pagination,
  SortingItem,
  ValidationCollection,
  ValidationItem,
} from './home-validations.service';
import { ConfigService } from '@geonature/services/config.service';

interface ValidationItemEnhanced {
  id_synthese: number;
  'last_validation.validation_date': string;
  'nomenclature_valid_status.label_default': string;
  'last_validation.validation_comment': string;
  validator: string;
  observation: string;
}

@Component({
  standalone: true,
  selector: 'pnx-home-validations',
  templateUrl: './home-validations.component.html',
  styleUrls: ['./home-validations.component.scss'],
  imports: [GN2CommonModule, CommonModule],
  providers: [HomeValidationsService],
})
export class HomeValidationsComponent implements OnInit, OnDestroy {
  readonly PROP_VALIDATOR = 'validator';
  readonly PROP_VALIDATION_DATE = 'last_validation.validation_date';
  readonly PROP_VALIDATION_STATUS = 'nomenclature_valid_status.mnemonique';
  readonly PROP_VALIDATION_CODE = 'nomenclature_valid_status.cd_nomenclature';
  readonly PROP_VALIDATION_MESSAGE = 'last_validation.validation_comment';
  readonly PROP_OBSERVATION = 'observation';
  readonly DEFAULT_SORTING: SortingItem = {
    sort: 'desc',
    order_by: this.PROP_VALIDATION_DATE,
  };
  validations: ValidationItemEnhanced[] = [];
  // TODO: update this
  pagination: Pagination = HomeValidationsService.DEFAULT_PAGINATION;
  sort: SortingItem = this.DEFAULT_SORTING;

  private destroy$ = new Subject<void>();
  constructor(
    private _config: ConfigService,
    private _router: Router,
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
      order_by: event.column.prop,
    };
    this.pagination.page = 1;
    this._fetchValidations();
  }

  navigateToValidations(row: ValidationItem) {
    this._router.navigate(this._homeValidations.computeValidationsRedirectionUrl(row.id_synthese));
  }
  renderDate(date: string): string {
    return new Date(date).toLocaleString();
  }

  private _fetchValidations() {
    this._homeValidations
      .fetchValidations(this.pagination, this.sort)
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

  private _transformValidations(validations: ValidationItem[]): ValidationItemEnhanced[] {
    return validations.map((validation: ValidationItem) => ({
      id_synthese: validation.id_synthese,
      'last_validation.validation_date': validation.last_validation?.validation_date,
      'last_validation.validation_auto': validation.last_validation?.validation_auto,
      'nomenclature_valid_status.cd_nomenclature':
        validation.nomenclature_valid_status.cd_nomenclature,
      'nomenclature_valid_status.mnemonique': validation.nomenclature_valid_status.mnemonique,
      'nomenclature_valid_status.label_default': validation.nomenclature_valid_status.label_default,
      'last_validation.validation_comment': validation.last_validation?.validation_comment,
      validator: validation.validator ?? 'Auto',
      observation: this._formatObservation(validation),
    }));
  }

  private _formatObservation(validation: any): string {
    return `
      <strong>Nom Cité :</strong> ${validation.nom_cite || 'N/A'}<br>
      <strong>Observateurs :</strong> ${validation.observers || 'N/A'}<br>
      <strong>Date Observation :</strong> ${
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

  getValidationStatusColor(cd_nomenclature: number) {
    return this._config.VALIDATION.STATUS_INFO[cd_nomenclature]?.color;

  }
}
