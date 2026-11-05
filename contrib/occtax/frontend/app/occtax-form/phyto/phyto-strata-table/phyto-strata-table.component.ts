import { ChangeDetectionStrategy, Component, Input, OnDestroy, OnInit, ViewChild } from '@angular/core';
import {
  AbstractControl,
  FormArray,
  FormBuilder,
  Validators,
  ValidationErrors,
  ValidatorFn,
} from '@angular/forms';
import { MatTable } from '@angular/material/table';
import { BreakpointObserver, Breakpoints } from '@angular/cdk/layout';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { Nomenclature } from '@geonature_common/interfaces'
import { OcctaxFormService } from '../../occtax-form.service';
import { Subject } from 'rxjs';
import { filter, map, takeUntil } from 'rxjs/operators';
import { PhytoData, PhytoDataWithProperties, VegetationStratum, VegetationStratumForm } from '../utils/interfaces';

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

  @Input() public parentFormControl!: FormArray<VegetationStratumForm>;
  @ViewChild(MatTable) table!: MatTable<VegetationStratumForm>;

  strataMnemo: Record<string, string> = {};
  strataLabels: Record<string, string> = {};
  isHandset$ = this.breakpointObserver.observe(Breakpoints.Handset).pipe(
    map(state => state.matches)
  );

  private readonly destroy$ = new Subject<void>();

  constructor(
    private readonly formBuilder: FormBuilder,
    private readonly dataFormService: DataFormService,
    private readonly occtaxFormService: OcctaxFormService,
    private readonly breakpointObserver: BreakpointObserver
  ) { }

  get strataControls(): VegetationStratumForm[] {
    return this.parentFormControl.controls;
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
          const preExistingValues: VegetationStratum[] = this.parentFormControl.getRawValue();

          this.parentFormControl.clear({ emitEvent: false });

          nomenclatures.forEach((strateNomenclature: Nomenclature) => {

            this.strataLabels[strateNomenclature.id_nomenclature] = strateNomenclature.label_default;
            this.strataMnemo[strateNomenclature.id_nomenclature] = strateNomenclature.mnemonique;

            const existingData: Partial<VegetationStratum> =
              preExistingValues.find(
                (value) =>
                  value.id_nomenclature_vegetation_stratum === strateNomenclature.id_nomenclature
              ) || {};

            const group = this.formBuilder.group(
              {
                id_vegetation_stratum: [existingData.id_vegetation_stratum ?? null],
                id_nomenclature_vegetation_stratum: [strateNomenclature.id_nomenclature],
                percentage_cover_vegetation_stratum: [
                  existingData.percentage_cover_vegetation_stratum ?? null,
                  [minStrictValidator(0), Validators.max(100)],
                ],
                average_height: [existingData.average_height ?? null],
                min_height: [existingData.min_height ?? null],
                max_height: [existingData.max_height ?? null],
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

    this.parentFormControl.patchValue = (incomingValues, options) => {
      if (!Array.isArray(incomingValues)) {
        return originalPatchValue(incomingValues, options);
      }

      const safelyMappedValues = nomenclatures.map(nomenc => {
        const dataForThisRow = incomingValues.find(
          (value) =>
            value?.id_nomenclature_vegetation_stratum === nomenc.id_nomenclature
        );

        return dataForThisRow || { id_nomenclature_vegetation_stratum: nomenc.id_nomenclature };
      });

      return originalPatchValue(safelyMappedValues, options);
    };
  }

  private listenToDataChanges(): void {
    this.occtaxFormService.occtaxData
      .pipe(
      filter((occtaxData: PhytoData): occtaxData is PhytoDataWithProperties =>
        !!occtaxData?.releve?.properties
      ),
      takeUntil(this.destroy$)
    )
    .subscribe({
      next: (occtaxData: PhytoDataWithProperties) => {
          const savedStrata = occtaxData.releve.properties.t_vegetation_stratum || [];

          this.parentFormControl.patchValue(savedStrata, { emitEvent: false });

        },
        error: (error: unknown) => {
          console.error('Error loading occtaxData for strata table:', error);
        }
      });
  }
}