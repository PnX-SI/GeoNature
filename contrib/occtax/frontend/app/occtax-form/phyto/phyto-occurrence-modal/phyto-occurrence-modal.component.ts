import { ChangeDetectionStrategy, Component, Inject, OnDestroy } from '@angular/core';
import { combineLatest, Subject } from 'rxjs';
import { takeUntil } from 'rxjs/operators';
import { MatDialog, MAT_DIALOG_DATA } from '@angular/material/dialog';
import { TranslateService } from '@ngx-translate/core';
import { ConfigService } from '@geonature/services/config.service';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { FormService } from '@geonature_common/form/form.service';
import {
  NomenclatureResponse,
  Occurrence,
  PhytoData,
  VegetationStratum,
} from '../utils/interfaces';
import { OcctaxConfigService } from '../../../services/occtax-config.service';
import { OcctaxFormService } from '../../occtax-form.service';
import { OcctaxTaxaListService } from '../../taxa-list/taxa-list.service';
import { PhytoOccurrenceComponent } from '../phyto-occurrence/phyto-occurrence.component';
import { PhytoOccurrenceService } from '../services/occurrence.service';
import { PhytoCountingStateService } from '../services/counting-state.service';
import { getEligibleVegetationStratumRows } from '../utils/vegetation-strata.utils';

/**
 * Edits one phyto occurrence and ensures its counting list covers each
 * vegetation stratum that has data in the releve.
 *
 * TODO: [Angular Material v15 / Architecture] Consider refactoring to Standalone Component
 */
@Component({
  selector: 'pnx-phyto-occurrence-modal',
  templateUrl: './phyto-occurrence-modal.component.html',
  styleUrls: [
    './phyto-occurrence-modal.component.scss',
    '../../occurrence/occurrence.component.scss',
  ],
  providers: [PhytoOccurrenceService, PhytoCountingStateService],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class PhytoOccurrenceModalComponent extends PhytoOccurrenceComponent implements OnDestroy {
  public strataLabels: Record<number, string> = {};
  public abundancesLabels: Record<number, string> = {};
  public releveStrata: VegetationStratum[] = [];
  private readonly modalDestroy$ = new Subject<void>();

  constructor(
    @Inject(MAT_DIALOG_DATA) public data: { occurrence: Occurrence },
    occtaxFormService: OcctaxFormService,
    private modalCountingStateService: PhytoCountingStateService,
    phytoOccurrenceService: PhytoOccurrenceService,
    formService: FormService,
    occtaxTaxaListService: OcctaxTaxaListService,
    dataFormService: DataFormService,
    dialog: MatDialog,
    configService: ConfigService,
    occtaxConfigService: OcctaxConfigService,
    translate: TranslateService
  ) {
    super(
      occtaxFormService,
      modalCountingStateService,
      phytoOccurrenceService,
      formService,
      occtaxTaxaListService,
      dataFormService,
      dialog,
      configService,
      occtaxConfigService,
      translate
    );
    this.phytoOccurrenceService.occurrence.next(data.occurrence);
    this.occurrenceForm = this.phytoOccurrenceService.form;

    combineLatest([
      occtaxFormService.occtaxData,
      dataFormService.getNomenclature('STRATE_VEGETATION'),
      dataFormService.getNomenclature('PHYTO_ABUNDANCE'),
    ])
      .pipe(takeUntil(this.modalDestroy$))
      .subscribe({
        next: ([data, strataResponse, abundancesResponse]: [
          PhytoData | null,
          NomenclatureResponse,
          NomenclatureResponse,
        ]) => {
          const eligibleStrata = getEligibleVegetationStratumRows(
            data?.releve?.properties?.t_vegetation_stratum || [],
            strataResponse.values || []
          );
          this.strataLabels = Object.fromEntries(
            eligibleStrata.map(({ id, label }) => [id, label])
          );
          abundancesResponse.values.forEach((abundance) => {
            this.abundancesLabels[abundance.id_nomenclature] = abundance.label_default;
          });
          this.releveStrata = eligibleStrata.map((row) => row.stratum);
          this.addMissingCountings();
        },
        error: (error: unknown) => {
          console.error('Error loading vegetation strata for countings:', error);
        },
      });
  }

  public override ngOnDestroy(): void {
    this.modalDestroy$.next();
    this.modalDestroy$.complete();
    super.ngOnDestroy();
  }

  private addMissingCountings(): void {
    const countings = this.modalCountingStateService.countings || [];
    const existingStratumIds = new Set<number | null>(
      countings.map((counting) => counting.id_nomenclature_vegetation_stratum ?? null)
    );
    const missingCountings = this.releveStrata
      .filter((stratum) => !existingStratumIds.has(stratum.id_nomenclature_vegetation_stratum))
      .map((stratum) => ({
        id_nomenclature_vegetation_stratum: stratum.id_nomenclature_vegetation_stratum,
      }));

    if (missingCountings.length > 0) {
      this.modalCountingStateService.countings = [...countings, ...missingCountings];
      this.modalCountingStateService.countings = this.modalCountingStateService.countings.sort(
        (a, b) => a.id_nomenclature_vegetation_stratum - b.id_nomenclature_vegetation_stratum
      );
    }
  }
}
