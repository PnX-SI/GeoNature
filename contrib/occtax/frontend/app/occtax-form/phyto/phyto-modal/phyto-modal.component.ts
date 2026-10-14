import { Component, Inject, QueryList, ViewChildren } from '@angular/core';
import { UntypedFormGroup } from '@angular/forms';
import { MatDialog, MatDialogRef, MAT_DIALOG_DATA } from '@angular/material/dialog';

import { OcctaxFormService } from '../../occtax-form.service';
import { PhytoOccurrenceComponent } from '../phyto-occurrence/phyto-occurrence.component';
import { PhytoOccurrenceService } from '../phyto-occurrence/occurrence.service';
import { PhytoCountingsService } from '../phyto-counting/countings.service';
// import { PhytoAdvancedCountingComponent } from '../phyto-advanced-counting/phyto-advanced-counting.component';
import { OcctaxTaxaListService } from '../../taxa-list/taxa-list.service';
import { OcctaxConfigService } from '../../../services/occtax-config.service';

import { ConfigService } from '@geonature/services/config.service';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { FormService } from '@geonature_common/form/form.service';

@Component({
  selector: 'pnx-phyto-modal',
  templateUrl: './phyto-modal.component.html',
  styleUrls: ['./phyto-modal.component.scss', '../../occurrence/occurrence.component.scss'],
  providers: [PhytoOccurrenceService, PhytoCountingsService],
})
export class PhytoModalComponent extends PhytoOccurrenceComponent {
  public data: { occurrence: any };
  public stratesLabels: Record<number, string> = {};
  // @ViewChildren(PhytoAdvancedCountingComponent)
  // private phytoAdvancedCountingComponents: QueryList<PhytoAdvancedCountingComponent>;

  constructor(
    @Inject(MAT_DIALOG_DATA) data: { occurrence: any },
    public dialogRef: MatDialogRef<PhytoModalComponent>,
    fs: OcctaxFormService,
    phytoCountingsService: PhytoCountingsService,
    phytoOccurrenceService: PhytoOccurrenceService,
    coreFormService: FormService,
    occtaxTaxaListService: OcctaxTaxaListService,
    dataFormService: DataFormService,
    dialog: MatDialog,
    config: ConfigService,
    occtaxConfig: OcctaxConfigService
  ) {
    super(
      fs,
      phytoCountingsService,
      phytoOccurrenceService,
      coreFormService,
      occtaxTaxaListService,
      dataFormService,
      dialog,
      config,
      occtaxConfig
    );
    this.data = data;
    this.phytoOccurrenceService.occurrence.next(data.occurrence);
    this.occurrenceForm = this.phytoOccurrenceService.form;
    dataFormService.getNomenclature('STRATE_VEGETATION').subscribe({
      next: (response) => {
        response.values.forEach((stratum) => {
          this.stratesLabels[stratum.id_nomenclature] = stratum.label_default;
        });
      },
      error: (error) => {
        console.error('Error loading vegetation strata:', error);
      },
    });
  }

  // public submitOccurrenceForm(): void {
  //   document.getElementById('taxonInput')?.focus();
  //   if (this.phytoOccurrenceService.form.valid) {
  //     this.phytoOccurrenceService.submitOccurrence();
  //     this.phytoAdvancedCountingComponents.forEach((component) =>
  //       component.validateMediasDeletions()
  //     );
  //   }
  // }

  public closeDialog(): void {
    this.dialogRef.close();
  }
}
