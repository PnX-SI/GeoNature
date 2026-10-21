import { Component, Input, OnDestroy, OnInit, ViewChild } from '@angular/core';
import {
  AbstractControl,
  FormArray,
  FormBuilder,
  Validators,
  ValidationErrors,
  ValidatorFn,
} from '@angular/forms';
import { MatTable } from '@angular/material/table';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { OcctaxFormService } from '../../occtax-form.service';
import { combineLatest, Subject } from 'rxjs';
import { filter, takeUntil } from 'rxjs/operators';

// Mirrors pr_occtax.t_vegetation_stratum.
export interface VegetationStratum {
  id_vegetation_stratum: number | null;
  id_releve_occtax?: number;
  id_nomenclature_vegetation_stratum?: number | null;
  min_height?: number | null;
  max_height?: number | null;
  average_height?: number | null;
  percentage_cover_vegetation_stratum?: number | null;
}

export interface Nomenclature {
  id_nomenclature: number;
  label_default: string;
  mnemonique: string;
}

const heightOrderValidator: ValidatorFn = (group: AbstractControl): ValidationErrors | null => {
  const min = group.get('min_height')?.value;
  const average = group.get('average_height')?.value;
  const max = group.get('max_height')?.value;

  if (
    (min != null && average != null && min > average) ||
    (average != null && max != null && average > max) ||
    (min != null && max != null && min > max)
  ) {
    return { invalidHeightOrder: true };
  }

  return null;
};

function minStrictValidator(min: number): ValidatorFn {
  return (control: AbstractControl): ValidationErrors | null => {
    // On ignore la validation si le champ est vide (géré par Validators.required si nécessaire)
    if (control.value === null || control.value === undefined || control.value === '') {
      return null;
    }

    const value = Number(control.value);

    // Vérification strictement supérieure
    return value > min ? null : { minStrict: { requiredMin: min, actual: value } };
  };
}



/**
 * Edits vegetation-stratum cover and height values on a phyto survey.
 *
 * Rows follow the vegetation-stratum nomenclature order. When editing a survey,
 * saved stratum values are restored if the form array has not been populated;
 * existing form values take precedence to preserve in-progress edits.
 */
@Component({
  selector: 'pnx-phyto-strata-table',
  templateUrl: './phyto-strata-table.component.html',
  styleUrls: ['./phyto-strata-table.component.scss'],
})
export class PhytoStrataTableComponent implements OnInit, OnDestroy {
  displayedColumns: string[] = [
    'label_default',
    'percentage_cover_vegetation_stratum',
    'average_height',
    'min_height',
    'max_height',
  ];
  @Input() public parentFormControl!: FormArray;

  @ViewChild('strataTable', { static: true }) public table!: MatTable<any>;

  strataMnemo: Record<string, string> = {};
  strataLabels: Record<string, string> = {};

  private readonly destroy$ = new Subject<void>();

  constructor(
    private readonly formBuilder: FormBuilder,
    private readonly dataFormService: DataFormService,
    private readonly occtaxFormService: OcctaxFormService
  ) { }

  public ngOnInit(): void {
    this.loadStrataTable();
  }

  public ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  private loadStrataTable(): void {
    combineLatest([
      this.dataFormService.getNomenclature('STRATE_VEGETATION'),
      this.occtaxFormService.editionMode,
      this.occtaxFormService.occtaxData,
    ])
      .pipe(
        filter(([, editionMode, occtaxData]: [{ values: Nomenclature[] }, unknown, any]) => !editionMode || !!occtaxData?.releve?.properties),
        takeUntil(this.destroy$)
      )
      .subscribe({
        next: ([strataNomenclatures, , occtaxData]: [{ values: Nomenclature[] }, unknown, any]) => {
          this.strataLabels = {};
          this.strataMnemo = {};
          const existingStrata = (this.parentFormControl.value || []) as VegetationStratum[];
          const savedStrata: VegetationStratum[] =
            occtaxData?.releve?.properties?.t_vegetation_stratum || [];
          // Prefer form values to retain edits; use saved data when patchValue left the array empty.
          const strataToRestore = existingStrata.length > 0 ? existingStrata : savedStrata;
          const strataFormGroups = strataNomenclatures.values.map(
            (strateNomenclature: Nomenclature) => {
              this.strataLabels[strateNomenclature.id_nomenclature] =
                strateNomenclature.label_default;
              this.strataMnemo[strateNomenclature.id_nomenclature] =
                strateNomenclature.mnemonique;

              const currentStratum: VegetationStratum = strataToRestore.find(
                (stratum) =>
                  stratum.id_nomenclature_vegetation_stratum === strateNomenclature.id_nomenclature
              ) || {
                id_vegetation_stratum: null,
                id_nomenclature_vegetation_stratum: strateNomenclature.id_nomenclature,
                percentage_cover_vegetation_stratum: null,
                average_height: null,
                min_height: null,
                max_height: null,
              };

              return this.formBuilder.group(
                {
                  id_vegetation_stratum: [currentStratum.id_vegetation_stratum],
                  id_nomenclature_vegetation_stratum: [
                    currentStratum.id_nomenclature_vegetation_stratum,
                  ],
                  percentage_cover_vegetation_stratum: [
                    currentStratum.percentage_cover_vegetation_stratum,
                    [minStrictValidator(0), Validators.max(100)],
                  ],
                  average_height: [currentStratum.average_height],
                  min_height: [currentStratum.min_height],
                  max_height: [currentStratum.max_height],
                },
                {
                  validators: heightOrderValidator,
                }
              );
            }
          );

          this.parentFormControl.clear({ emitEvent: false });
          strataFormGroups.forEach((stratum: AbstractControl) =>
            this.parentFormControl.push(stratum, { emitEvent: false })
          );

          this.table?.renderRows();
        },
        error: (error: unknown) => {
          console.error('Error loading nomenclature STRATE_VEGETATION:', error);
        },
      });
  }
}
