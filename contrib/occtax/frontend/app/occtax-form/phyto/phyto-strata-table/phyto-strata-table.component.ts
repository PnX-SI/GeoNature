import { ChangeDetectionStrategy, Component, Input, OnDestroy, OnInit, ViewChild } from '@angular/core';
import {
  AbstractControl,
  FormGroup,
  FormControl,
  FormArray,
  FormBuilder,
  Validators,
  ValidationErrors,
  ValidatorFn,
} from '@angular/forms';
import { MatTable } from '@angular/material/table';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { Nomenclature } from '@geonature_common/interfaces'
import { OcctaxFormService } from '../../occtax-form.service';
import { Subject } from 'rxjs';
import { filter, takeUntil } from 'rxjs/operators';

export interface VegetationStratumForm {
  id_vegetation_stratum: FormControl<number | null>;
  id_nomenclature_vegetation_stratum: FormControl<number | null>;
  min_height: FormControl<number | null>;
  max_height: FormControl<number | null>;
  average_height: FormControl<number | null>;
  percentage_cover_vegetation_stratum: FormControl<number | null>;
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
 * Rows follow the vegetation-stratum nomenclature order. 
 * Form structure is built once on init, and data is patched reactively.
 * 
 * TODO: [Angular Material v15 / Architecture] Consider refactoring to a Standalone Component
 */
@Component({
  selector: 'pnx-phyto-strata-table',
  templateUrl: './phyto-strata-table.component.html',
  styleUrls: ['./phyto-strata-table.component.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class PhytoStrataTableComponent implements OnInit, OnDestroy {
  displayedColumns: string[] = [
    'label_default',
    'percentage_cover_vegetation_stratum',
    'average_height',
    'min_height',
    'max_height',
  ];

  @Input() public parentFormControl!: FormArray<FormGroup<VegetationStratumForm>>;
  @ViewChild(MatTable) table!: MatTable<any>;

  strataMnemo: Record<string, string> = {};
  strataLabels: Record<string, string> = {};

  private readonly destroy$ = new Subject<void>();

  constructor(
    private readonly formBuilder: FormBuilder,
    private readonly dataFormService: DataFormService,
    private readonly occtaxFormService: OcctaxFormService
  ) { }

  get strataControls(): FormGroup[] {
    return this.parentFormControl.controls as FormGroup[];
  }

  public ngOnInit(): void {
    this.initStrataTable();
  }

  public ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  private initStrataTable(): void {
    this.dataFormService.getNomenclature('STRATE_VEGETATION')
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (strataNomenclatures: { values: Nomenclature[] }) => {
          const nomenclatures = strataNomenclatures.values;
          const preExistingValues = this.parentFormControl.value || [];

          this.parentFormControl.clear({ emitEvent: false });

          nomenclatures.forEach((strateNomenclature: Nomenclature) => {

            this.strataLabels[strateNomenclature.id_nomenclature] = strateNomenclature.label_default;
            this.strataMnemo[strateNomenclature.id_nomenclature] = strateNomenclature.mnemonique;

            const existingData = preExistingValues.find(
              (v: any) => v?.id_nomenclature_vegetation_stratum === strateNomenclature.id_nomenclature
            ) || {};

            const group = this.formBuilder.group(
              {
                id_vegetation_stratum: [existingData.id_vegetation_stratum || null],
                id_nomenclature_vegetation_stratum: [strateNomenclature.id_nomenclature],
                percentage_cover_vegetation_stratum: [
                  existingData.percentage_cover_vegetation_stratum || null,
                  [minStrictValidator(0), Validators.max(100)],
                ],
                average_height: [existingData.average_height || null],
                min_height: [existingData.min_height || null],
                max_height: [existingData.max_height || null],
              },
              {
                validators: heightOrderValidator
              }
            );

            this.parentFormControl.push(group, { emitEvent: false });
          });

          this.table?.renderRows();
          this.protectFormArrayOrder(nomenclatures);
          this.listenToDataChanges();
        },
        error: (error: unknown) => {
          console.error('Error loading nomenclature STRATE_VEGETATION:', error);
        },
      });
  }

  private protectFormArrayOrder(nomenclatures: Nomenclature[]): void {
    const originalPatchValue = this.parentFormControl.patchValue.bind(this.parentFormControl);

    this.parentFormControl.patchValue = (incomingValues: any[], options?: Object) => {
      if (!Array.isArray(incomingValues)) {
        return originalPatchValue(incomingValues, options);
      }

      const safelyMappedValues = nomenclatures.map(nomenc => {
        const dataForThisRow = incomingValues.find(
          (val) => val && val.id_nomenclature_vegetation_stratum === nomenc.id_nomenclature
        );

        return dataForThisRow || { id_nomenclature_vegetation_stratum: nomenc.id_nomenclature };
      });

      return originalPatchValue(safelyMappedValues, options);
    };
  }

  private listenToDataChanges(): void {
    this.occtaxFormService.occtaxData
      .pipe(
        filter((occtaxData: any) => !!occtaxData?.releve?.properties), // Ensure data exists
        takeUntil(this.destroy$)
      )
      .subscribe({
        next: (occtaxData: any) => {
          const savedStrata = occtaxData.releve.properties.t_vegetation_stratum || [];

          this.parentFormControl.patchValue(savedStrata, { emitEvent: false });

        },
        error: (error: unknown) => {
          console.error('Error loading occtaxData for strata table:', error);
        }
      });
  }
}