import { Component, Input, OnDestroy, OnInit, ViewChild } from '@angular/core';
import { UntypedFormGroup, UntypedFormArray } from '@angular/forms';
import { Subject } from 'rxjs';
import { filter, takeUntil } from 'rxjs/operators';

import { OcctaxFormService } from '../../occtax-form.service';
import { PhytoOccurrenceService } from '../phyto-occurrence/occurrence.service';
import { PhytoCountingService } from '../phyto-abundance/counting.service';
import { ConfigService } from '@geonature/services/config.service';
import { ModuleService } from '@geonature/services/module.service';
import { OcctaxConfigService } from '../../../services/occtax-config.service';
import { ValidationErrorsId } from '@geonature/services/validators';
import { MediasComponent } from '@geonature_common/form/media/medias.component';

/**
 * Provides the phyto-specific counting form, including phytosociological
 * abundance, while reusing the standard counting layout and media controls.
 */
@Component({
  selector: 'pnx-occtax-form-phyto-advanced-counting',
  templateUrl: './phyto-advanced-counting.component.html',
  styleUrls: ['./phyto-advanced-counting.component.scss', '../../counting/counting.component.scss'],
  providers: [PhytoCountingService],
})
export class PhytoAdvancedCountingComponent implements OnInit, OnDestroy {
  @ViewChild(MediasComponent) private mediasComp?: MediasComponent;
  @Input('value')
  set counting(value: any) {
    this.occtaxFormCountingService.counting.next(value);
  }

  public form!: UntypedFormGroup;
  public readonly ValidationErrorsId = ValidationErrorsId;
  public nbIndiv = 0;
  public cdNomenclatureObjDen = '';

  private readonly destroy$ = new Subject<void>();

  public get additionalFieldsForm(): any[] {
    return this.occtaxFormCountingService.additionalFieldsForm;
  }

  constructor(
    public readonly occtaxFormService: OcctaxFormService,
    public readonly occtaxFormOccurrenceService: PhytoOccurrenceService,
    private readonly occtaxFormCountingService: PhytoCountingService,
    public readonly config: ConfigService,
    public readonly moduleService: ModuleService,
    public readonly occtaxConfig: OcctaxConfigService
  ) {}

  /** Connect the counting form to the shared occurrence life-stage state. */
  public ngOnInit(): void {
    this.form = this.occtaxFormCountingService.form;
    this.form
      .get('id_nomenclature_life_stage')
      .valueChanges.pipe(
        filter((idNomenclatureLifeStage) => idNomenclatureLifeStage !== null),
        takeUntil(this.destroy$)
      )
      .subscribe((idNomenclatureLifeStage) => {
        this.occtaxFormOccurrenceService.lifeStage.next(idNomenclatureLifeStage);
      });
  }

  /** Run deferred media deletions before saving the occurrence. */
  public validateMediasDeletions(): void {
    this.mediasComp?.validateDeletions();
  }

  /** Dispose local subscriptions and unregister this form from the occurrence. */
  public ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();

    const countings = this.occtaxFormOccurrenceService.form.get(
      'cor_counting_occtax'
    ) as UntypedFormArray;
    const idx = countings.controls.indexOf(this.form);
    if (idx !== -1) {
      countings.removeAt(idx);
    }
  }

  public get taxref(): any {
    return this.occtaxFormOccurrenceService.taxref.getValue();
  }

  /** Build media metadata defaults from the current releve and selected taxon. */
  public defaultsMedia(): Record<string, string | boolean> {
    const occtaxData = this.occtaxFormService.occtaxData.getValue();
    const taxref = this.occtaxFormOccurrenceService.taxref.getValue();
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
