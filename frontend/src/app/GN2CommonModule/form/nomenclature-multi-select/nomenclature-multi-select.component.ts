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
import { CommonService } from '@geonature_common/service/common.service';


@Component({
  selector: 'pnx-nomenclature-multi-select',
  templateUrl: './nomenclature-multi-select.component.html',
  styleUrls: ['./nomenclature-multi-select.component.scss'],
  encapsulation: ViewEncapsulation.None

})

export class NomenclatureMultiSelectComponent  extends GenericFormComponent
implements OnInit, OnChanges, OnDestroy {
  public labels: Array<any>;
  public labelLang: string;
  public definitionLang: string;
  public subscription: Subscription;
  public valueSubscription: Subscription;
  public currentCdNomenclature = 'null';
  public currentIdNomenclature: number;
  @Input() etiquette: string;
  @Input() parentFormControl: FormControl;
  @Input() codeNomenclatureType: string;
  @Input() regne: string;
  @Input() group2Inpn: string;
  @Input() disabled: boolean;
  @Input() debounceTime: number;

  constructor(private _dfService: DataFormService, private _translate: TranslateService, private _commonService: CommonService) {
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
    const filters = { orderby: 'label_default' };
    this._dfService
      .getNomenclature(this.codeNomenclatureType, this.regne, this.group2Inpn, filters)
      .subscribe(data => {
        this.labels = data.values;
      });
  }

  ngOnDestroy() {
    this.subscription.unsubscribe();
    this.valueSubscription.unsubscribe();
  }
}
