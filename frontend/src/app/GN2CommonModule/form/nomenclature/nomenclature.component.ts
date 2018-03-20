import {
  Component,
  OnInit,
  Input,
  Output,
  EventEmitter,
  OnChanges,
  OnDestroy,
  SimpleChanges,
  ViewEncapsulation
} from '@angular/core';
import { FormControl, FormGroup } from '@angular/forms';
import { DataFormService } from '../data-form.service';
import { TranslateService, LangChangeEvent } from '@ngx-translate/core';
import { Subscription } from 'rxjs/Subscription';
import { GenericFormComponent } from '@geonature_common/form/genericForm.component';

@Component({
  selector: 'pnx-nomenclature',
  templateUrl: './nomenclature.component.html',
  styleUrls: ['./nomenclature.component.scss'],
  encapsulation: ViewEncapsulation.None
})
export class NomenclatureComponent extends GenericFormComponent
  implements OnInit, OnChanges, OnDestroy {
  public labels: Array<any>;
  public labelLang: string;
  public definitionLang: string;
  public subscription: Subscription;
  public valueSubscription: Subscription;
  public currentCdNomenclature = 'null';
  public currentIdNomenclature: number;
  @Input() idTypeNomenclature: number;
  @Input() regne: string;
  @Input() group2Inpn: string;
  constructor(private _dfService: DataFormService, private _translate: TranslateService) {
    super();
  }

  ngOnInit() {
    this.labelLang = 'label_' + this._translate.currentLang;
    this.definitionLang = 'definition_' + this._translate.currentLang;
    // load the data
    this.initLabels();
    // subscrib to the language change
    this.subscription = this._translate.onLangChange.subscribe((event: LangChangeEvent) => {
      this.labelLang = 'label_' + this._translate.currentLang;
      this.definitionLang = 'definition_' + this._translate.currentLang;
    });

    // set cdNomenclature
    this.valueSubscription = this.parentFormControl.valueChanges.subscribe(id => {
      this.currentIdNomenclature = id;
      const self = this;
      if (this.labels) {
        this.labels.forEach(label => {
          if (this.currentIdNomenclature === label.id_nomenclature) {
            self.currentCdNomenclature = label.cd_nomenclature;
          }
        });
      }
    });
  }

  getCdNomenclature() {
    let cdNomenclature;
    if (this.labels) {
      this.labels.forEach(label => {
        if (this.currentIdNomenclature === label.id_nomenclature) {
          cdNomenclature = label.cd_nomenclature;
        }
      });
      return cdNomenclature;
    }
  }

  ngOnChanges(changes: SimpleChanges) {
    // if change regne => change groupe2inpn also
    if (changes.regne !== undefined && !changes.regne.firstChange) {
      this.initLabels();
    }
    // if only change groupe2inpn
    if (
      changes.regne === undefined &&
      changes.group2Inpn !== undefined &&
      !changes.group2Inpn.firstChange
    ) {
      this.initLabels();
    }
  }

  initLabels() {
    this._dfService
      .getNomenclature(this.idTypeNomenclature, this.regne, this.group2Inpn)
      .subscribe(data => {
        this.labels = data.values;
      });
  }

  ngOnDestroy() {
    this.subscription.unsubscribe();
    this.valueSubscription.unsubscribe();
  }
}
