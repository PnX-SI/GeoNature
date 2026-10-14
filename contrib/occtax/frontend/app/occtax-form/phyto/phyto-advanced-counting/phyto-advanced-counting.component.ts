import { Component, OnInit, Input, OnDestroy, Output, EventEmitter } from '@angular/core';
import { UntypedFormGroup, UntypedFormArray } from '@angular/forms';
import { Subscription } from 'rxjs';
import { filter } from 'rxjs/operators';

import { OcctaxFormService } from '../../occtax-form.service';
import { PhytoOccurrenceService } from '../phyto-occurrence/occurrence.service';
import { PhytoCountingService } from '../phyto-counting/counting.service';
import { ConfigService } from '@geonature/services/config.service';
import { ModuleService } from '@geonature/services/module.service';
import { OcctaxConfigService } from '../../../services/occtax-config.service';

import { ValidationErrorsId } from '@geonature/services/validators';
import { ViewChild } from '@angular/core';
import { MediasComponent } from '@geonature_common/form/media/medias.component';

@Component({
  selector: 'pnx-occtax-form-phyto-advanced-counting',
  templateUrl: './phyto-advanced-counting.component.html',
  styleUrls: ['./phyto-advanced-counting.component.scss'],
  providers: [PhytoCountingService],
})
export class PhytoAdvancedCountingComponent implements OnInit, OnDestroy {
  public data: any;
  @ViewChild(MediasComponent) mediasComp: MediasComponent;
  @Input('value')
  set counting(value: any) {
    this.occtaxFormCountingService.counting.next(value);
  }
  public sub: Subscription;
  @Output() lifeStageChange = new EventEmitter();

  form: UntypedFormGroup;
  get additionalFieldsForm(): any[] {
    return this.occtaxFormCountingService.additionalFieldsForm;
  }

  public nbIndiv: number = 0;
  public cdNomenclatureObjDen: string = '';

  constructor(
    public occtaxFormService: OcctaxFormService,
    public occtaxFormOccurrenceService: PhytoOccurrenceService,
    private occtaxFormCountingService: PhytoCountingService,
    public config: ConfigService,
    public moduleService: ModuleService,
    public occtaxConfig: OcctaxConfigService
  ) {}

  ValidationErrorsId = ValidationErrorsId;

  ngOnInit() {
    this.form = this.occtaxFormCountingService.form;
    this.sub = this.form
      .get('id_nomenclature_life_stage')
      .valueChanges.pipe(filter((idNomenclatureLifeStage) => idNomenclatureLifeStage !== null))
      .subscribe((idNomenclatureLifeStage) => {
        this.occtaxFormOccurrenceService.lifeStage.next(idNomenclatureLifeStage);
      });
  }

  validateMediasDeletions() {
    this.mediasComp?.validateDeletions();
  }

  ngOnDestroy() {
    // Remove this counting form from the parent occurrence form.
    const countings = this.occtaxFormOccurrenceService.form.get(
      'cor_counting_occtax'
    ) as UntypedFormArray;
    const idx = countings.controls.findIndex((elem) => elem === this.form);
    if (idx !== -1) {
      countings.removeAt(idx);
    }
  }

  get taxref() {
    return this.occtaxFormOccurrenceService.taxref.getValue();
  }

  defaultsMedia() {
    const occtaxData = this.occtaxFormService.occtaxData.getValue();
    const taxref = this.occtaxFormOccurrenceService.taxref.getValue();

    if (!(occtaxData && taxref)) {
      return {
        displayDetails: false,
      };
    }

    const observers = (occtaxData && occtaxData.releve.properties.observers) || [];
    const author = observers.map((o) => o.nom_complet).join(', ');

    const date_min = (occtaxData && occtaxData.releve.properties.date_min) || null;

    const cd_nom = String(taxref && taxref.cd_nom) || '';
    const lb_nom = (taxref && `${taxref.lb_nom}`) || '';
    const date_txt = date_min ? `${date_min.year}_${date_min.month}_${date_min.day}` : '';
    const date_txt2 = date_min ? `${date_min.day}/${date_min.month}/${date_min.year}` : '';

    return {
      displayDetails: false,
      author: author,
      title_fr: `${date_txt}_${lb_nom.replace(' ', '_')}_${cd_nom}`,
      description_fr: `${lb_nom} observé le ${date_txt2}`,
    };
  }

  setNbIndiv(nbIndiv: number) {
    this.nbIndiv = nbIndiv;
  }

  setCdNomenclatureObjDen(cdNomenclature: string) {
    this.cdNomenclatureObjDen = cdNomenclature;
  }
}
