import { Component, Inject, OnDestroy } from '@angular/core';
import { combineLatest, Subject } from 'rxjs';
import { takeUntil } from 'rxjs/operators';
import { MatDialog, MAT_DIALOG_DATA } from '@angular/material/dialog';
import { TranslateService } from '@ngx-translate/core';
import { ConfigService } from '@geonature/services/config.service';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { FormService } from '@geonature_common/form/form.service';
import { OcctaxConfigService } from '../../../services/occtax-config.service';
import { OcctaxFormService } from '../../occtax-form.service';
import { OcctaxTaxaListService } from '../../taxa-list/taxa-list.service';
import { PhytoOccurrenceComponent } from '../phyto-occurrence/phyto-occurrence.component';
import { PhytoOccurrenceService } from '../phyto-occurrence/occurrence.service';
import { PhytoCountingsService } from '../phyto-abundance/countings.service';

interface VegetationStratum {
  id_nomenclature_vegetation_stratum?: number | null;
  percentage_cover_vegetation_stratum?: number | null;
  average_height?: number | null;
  min_height?: number | null;
  max_height?: number | null;
}

interface StratumNomenclature {
  id_nomenclature: number;
  label_default: string;
}

interface PhytoReleveData {
  releve?: {
    properties?: {
      t_vegetation_stratum?: VegetationStratum[];
    };
  };
}

interface StratumNomenclatureResponse {
  values: StratumNomenclature[];
}

/**
 * Edits one phyto occurrence and ensures its counting list covers each
 * vegetation stratum that has data in the releve.
 */
@Component({
  selector: 'pnx-phyto-occurrence-modal',
  templateUrl: './phyto-occurrence-modal.component.html',
  styleUrls: [
    './phyto-occurrence-modal.component.scss',
    '../../occurrence/occurrence.component.scss',
  ],
  providers: [PhytoOccurrenceService, PhytoCountingsService],
})
export class PhytoOccurrenceModalComponent extends PhytoOccurrenceComponent implements OnDestroy {
  /** Labels used to display counting rows by their vegetation stratum. */
  public stratesLabels: Record<number, string> = {};
  /** Vegetation strata with at least one recorded cover or height value. */
  public releveStrata: VegetationStratum[] = [];
  private readonly modalDestroy$ = new Subject<void>();

  constructor(
    @Inject(MAT_DIALOG_DATA) data: { occurrence: any },
    occtaxFormService: OcctaxFormService,
    private countingsService: PhytoCountingsService,
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
      countingsService,
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

    // Load releve data and stratum labels together before creating missing countings.
    combineLatest([
      occtaxFormService.occtaxData,
      dataFormService.getNomenclature('STRATE_VEGETATION'),
    ])
      .pipe(takeUntil(this.modalDestroy$))
      .subscribe({
        next: ([data, strataResponse]: [PhytoReleveData | null, StratumNomenclatureResponse]) => {
          strataResponse.values.forEach((stratum) => {
            this.stratesLabels[stratum.id_nomenclature] = stratum.label_default;
          });
          const strata = data?.releve?.properties?.t_vegetation_stratum || [];
          this.releveStrata = strata.filter((stratum) => this.hasStratumData(stratum));
          this.addMissingCountings();
        },
        error: (error: unknown) => {
          console.error('Error loading vegetation strata for countings:', error);
        },
      });
  }

  /** Tear down modal-owned streams before delegating shared cleanup to the parent. */
  public override ngOnDestroy(): void {
    this.modalDestroy$.next();
    this.modalDestroy$.complete();
    super.ngOnDestroy();
  }

  /** A stratum is relevant when it has an ID and at least one recorded value. */
  private hasStratumData(
    stratum: VegetationStratum
  ): stratum is VegetationStratum & { id_nomenclature_vegetation_stratum: number } {
    return (
      stratum.id_nomenclature_vegetation_stratum != null &&
      (stratum.percentage_cover_vegetation_stratum != null ||
        stratum.average_height != null ||
        stratum.min_height != null ||
        stratum.max_height != null)
    );
  }

  /** Add one counting for each relevant stratum that is not already represented. */
  private addMissingCountings(): void {
    const countings = this.countingsService.countings || [];
    const existingStratumIds = new Set<number | null>(
      countings.map((counting) => counting.id_nomenclature_vegetation_stratum ?? null)
    );
    const missingCountings = this.releveStrata
      .filter((stratum) => !existingStratumIds.has(stratum.id_nomenclature_vegetation_stratum))
      .map((stratum) => ({
        id_nomenclature_vegetation_stratum: stratum.id_nomenclature_vegetation_stratum,
      }));

    if (missingCountings.length > 0) {
      this.countingsService.countings = [...countings, ...missingCountings];
    }
  }
}
