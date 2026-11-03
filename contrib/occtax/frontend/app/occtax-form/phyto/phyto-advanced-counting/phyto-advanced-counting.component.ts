import {
  ChangeDetectionStrategy,
  Component,
  Input,
  OnDestroy,
  OnInit,
  ViewChild,
} from '@angular/core';
import { FormArray } from '@angular/forms';
import { Subject } from 'rxjs';
import { filter, takeUntil } from 'rxjs/operators';

import { OcctaxFormService } from '../../occtax-form.service';
import { PhytoOccurrenceService } from '../services/occurrence.service';
import { PhytoCountingFormService } from '../services/counting-form.service';
import { ConfigService } from '@geonature/services/config.service';
import { ModuleService } from '@geonature/services/module.service';
import { OcctaxConfigService } from '../../../services/occtax-config.service';
import { ValidationErrorsId } from '@geonature/services/validators';
import { MediasComponent } from '@geonature_common/form/media/medias.component';
import {
  AdditionalFieldDefinition,
  Counting,
  CountingForm,
  TaxonReference,
} from '../utils/interfaces';

/**
 * Provides the phyto-specific counting form, including phytosociological
 * abundance, while reusing the standard counting layout and media controls.
 *
 * TODO: [Angular Material v15 / Architecture] Consider migrating to Standalone Component
 */
@Component({
  selector: 'pnx-occtax-form-phyto-advanced-counting',
  templateUrl: './phyto-advanced-counting.component.html',
  styleUrls: ['../../counting/counting.component.scss'],
  providers: [PhytoCountingFormService],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class PhytoAdvancedCountingComponent implements OnInit, OnDestroy {
  @ViewChild(MediasComponent) private mediasComp?: MediasComponent;
  @Input('value')
  set counting(value: Counting) {
    this.countingFormService.counting.next(value);
  }

  public form!: CountingForm;
  public readonly ValidationErrorsId = ValidationErrorsId;
  public nbIndiv = 0;
  public cdNomenclatureObjDen = '';

  private readonly destroy$ = new Subject<void>();

  public get additionalFieldsForm(): AdditionalFieldDefinition[] {
    return this.countingFormService.additionalFieldsForm;
  }

  constructor(
    public readonly occtaxFormService: OcctaxFormService,
    public readonly phytoOccurrenceService: PhytoOccurrenceService,
    private readonly countingFormService: PhytoCountingFormService,
    public readonly config: ConfigService,
    public readonly moduleService: ModuleService,
    public readonly occtaxConfig: OcctaxConfigService
  ) {}

  public ngOnInit(): void {
    this.form = this.countingFormService.form;
    this.form.controls.id_nomenclature_life_stage.valueChanges
      .pipe(
        filter((idNomenclatureLifeStage: number | null) => idNomenclatureLifeStage !== null),
        takeUntil(this.destroy$)
      )
      .subscribe((idNomenclatureLifeStage: number) => {
        this.phytoOccurrenceService.lifeStage.next(idNomenclatureLifeStage);
      });
  }

  public validateMediasDeletions(): void {
    this.mediasComp?.validateDeletions();
  }

  public ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();

    const countings = this.phytoOccurrenceService.form.get(
      'cor_counting_occtax'
    ) as FormArray<CountingForm>;
    const idx = countings.controls.indexOf(this.form);
    if (idx !== -1) {
      countings.removeAt(idx);
    }
  }

  public get taxref(): TaxonReference | null {
    return this.phytoOccurrenceService.taxref.getValue();
  }

  public defaultsMedia(): Record<string, string | boolean> {
    const occtaxData = this.occtaxFormService.occtaxData.getValue();
    const taxref = this.phytoOccurrenceService.taxref.getValue();
    const releveProperties = occtaxData?.releve?.properties;

    if (!releveProperties || !taxref) {
      return {
        displayDetails: false,
      };
    }

    const observers = releveProperties.observers || [];
    const author = observers.map((o) => o.nom_complet).join(', ');

    const dateMin = releveProperties.date_min || null;

    const cdNom = String(taxref.cd_nom ?? '');
    const scientificName = String(taxref.lb_nom ?? '');
    const dateForTitle = dateMin ? `${dateMin.year}_${dateMin.month}_${dateMin.day}` : '';
    const dateForDescription = dateMin ? `${dateMin.day}/${dateMin.month}/${dateMin.year}` : '';

    return {
      displayDetails: false,
      author,
      title_fr: `${dateForTitle}_${scientificName.replace(' ', '_')}_${cdNom}`,
      description_fr: `${scientificName} observé le ${dateForDescription}`,
    };
  }

  public setNbIndiv(nbIndiv: number): void {
    this.nbIndiv = nbIndiv;
  }

  public setCdNomenclatureObjDen(cdNomenclature: string): void {
    this.cdNomenclatureObjDen = cdNomenclature;
  }
}
