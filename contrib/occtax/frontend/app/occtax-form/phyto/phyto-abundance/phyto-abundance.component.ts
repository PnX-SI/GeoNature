import {
  Component,
  Input,
  OnChanges,
  OnDestroy,
  OnInit,
  SimpleChanges,
} from '@angular/core';
import { UntypedFormArray, UntypedFormGroup } from '@angular/forms';
import { PhytoCountingService } from './counting.service';
import { PhytoOccurrenceService } from '../phyto-occurrence/occurrence.service';

/**
 * Displays the phytosociological abundance selector for one vegetation stratum.
 * Its component-scoped counting service owns the form group and registers it
 * with the parent occurrence form; this component removes it when destroyed.
 */
@Component({
  selector: 'pnx-phyto-abundance',
  templateUrl: './phyto-abundance.component.html',
  providers: [PhytoCountingService],
})
export class PhytoAbundanceComponent implements OnInit, OnChanges, OnDestroy {
  @Input()
  set value(counting: any) {
    this.countingService.counting.next(counting);
  }

  @Input() public stratumId: number | null = null;

  public form!: UntypedFormGroup;

  constructor(
    private readonly countingService: PhytoCountingService,
    private readonly phytoOccurrenceService: PhytoOccurrenceService
  ) {}

  public ngOnInit(): void {
    this.form = this.countingService.form;
    this.setStratum();
  }

  public ngOnChanges(changes: SimpleChanges): void {
    if (changes.stratumId && this.form) {
      this.setStratum();
    }
  }

  private setStratum(): void {
    if (this.stratumId != null) {
      this.form
        .get('id_nomenclature_vegetation_stratum')
        ?.setValue(this.stratumId, { emitEvent: false });
    }
  }

  public ngOnDestroy(): void {
    if (!this.form) {
      return;
    }

    const countingForms = this.phytoOccurrenceService.form.get(
      'cor_counting_occtax'
    ) as UntypedFormArray;
    const formIndex = countingForms.controls.indexOf(this.form);
    if (formIndex !== -1) {
      countingForms.removeAt(formIndex);
    }
  }
}
