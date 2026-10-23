import {
  ChangeDetectionStrategy,
  Component,
  Input,
  OnChanges,
  OnDestroy,
  OnInit,
  SimpleChanges,
} from '@angular/core';
import { FormArray, FormControl, FormGroup } from '@angular/forms';
import { PhytoCountingService } from './counting.service';
import { PhytoOccurrenceService } from '../phyto-occurrence/occurrence.service';

export interface PhytoCountingForm {
  id_nomenclature_vegetation_stratum: FormControl<number | null>;
}

/**
 * Displays the phytosociological abundance selector for one vegetation stratum.
 * TODO: [Angular Material v15 / Architecture] Migrate to Standalone Component
 */
@Component({
  selector: 'pnx-phyto-abundance',
  templateUrl: './phyto-abundance.component.html',
  providers: [PhytoCountingService],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class PhytoAbundanceComponent implements OnInit, OnChanges, OnDestroy {
  @Input()
  set value(counting: any) {
    this.countingService.counting.next(counting);
  }

  @Input() public stratumId: number | null = null;

  public form!: FormGroup<PhytoCountingForm>;

  constructor(
    private readonly countingService: PhytoCountingService,
    private readonly phytoOccurrenceService: PhytoOccurrenceService
  ) { }

  public ngOnInit(): void {
    this.form = this.countingService.form as FormGroup<PhytoCountingForm>;
    this.setStratum();
  }

  public ngOnChanges(changes: SimpleChanges): void {
    if (changes.stratumId && this.form) {
      this.setStratum();
    }
  }

  private setStratum(): void {
    if (this.stratumId != null) {
      this.form.controls.id_nomenclature_vegetation_stratum.setValue(
        this.stratumId,
        { emitEvent: false }
      );
    }
  }

  public ngOnDestroy(): void {
    if (!this.form) {
      return;
    }

    const countingForms = this.phytoOccurrenceService.form.get(
      'cor_counting_occtax'
    ) as FormArray<FormGroup<PhytoCountingForm>>;
    const formIndex = countingForms.controls.indexOf(this.form);
    if (formIndex !== -1) {
      countingForms.removeAt(formIndex);
    }
  }
}