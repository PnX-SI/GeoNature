import {
  ChangeDetectionStrategy,
  Component,
  Input,
  OnChanges,
  OnDestroy,
  OnInit,
  SimpleChanges,
} from '@angular/core';
import { FormArray } from '@angular/forms';
import { PhytoCountingFormService } from '../services/counting-form.service';
import { PhytoOccurrenceService } from '../services/occurrence.service';
import { Counting, CountingForm } from '../utils/interfaces';

/**
 * Displays the phytosociological abundance selector for one vegetation stratum.
 * TODO: [Angular Material v15 / Architecture] Migrate to Standalone Component
 */
@Component({
  selector: 'pnx-phyto-abundance',
  templateUrl: './phyto-abundance.component.html',
  providers: [PhytoCountingFormService],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class PhytoAbundanceComponent implements OnInit, OnChanges, OnDestroy {
  @Input()
  set value(counting: Counting) {
    this.countingFormService.counting.next(counting);
  }

  @Input() public stratumId: number | null = null;

  public form!: CountingForm;

  constructor(
    private readonly countingFormService: PhytoCountingFormService,
    private readonly phytoOccurrenceService: PhytoOccurrenceService
  ) {}

  public ngOnInit(): void {
    this.form = this.countingFormService.form;
    this.setStratum();
  }

  public ngOnChanges(changes: SimpleChanges): void {
    if (changes.stratumId && this.form) {
      this.setStratum();
    }
  }

  private setStratum(): void {
    if (this.stratumId != null) {
      this.form.controls.id_nomenclature_vegetation_stratum.setValue(this.stratumId, {
        emitEvent: false,
      });
    }
  }

  public ngOnDestroy(): void {
    if (!this.form) {
      return;
    }

    const countingForms = this.phytoOccurrenceService.form.get(
      'cor_counting_occtax'
    ) as FormArray<CountingForm>;
    const formIndex = countingForms.controls.indexOf(this.form);
    if (formIndex !== -1) {
      countingForms.removeAt(formIndex);
    }
  }
}
