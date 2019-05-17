import {
  Component,
  OnInit,
  Input,
  OnChanges,
  OnDestroy,
  SimpleChanges,
  ViewEncapsulation
} from '@angular/core';
import { Observable, BehaviorSubject } from 'rxjs';
import { map } from 'rxjs/operators';
import { DataFormService } from '../data-form.service';
import { TranslateService, LangChangeEvent } from '@ngx-translate/core';
import { Subscription } from 'rxjs';
import { GenericFormComponent } from '@geonature_common/form/genericForm.component';

@Component({
  selector: 'pnx-nomenclature',
  templateUrl: './nomenclature.component.html',
  styleUrls: ['./nomenclature.component.scss'],
  encapsulation: ViewEncapsulation.None
})
export class NomenclatureComponent extends GenericFormComponent
  implements OnInit, OnChanges, OnDestroy {
  public labels: Observable<Array<any>>;
  public labelLang: string;
  public definitionLang: string;
  public subscription: Subscription;
  public valueSubscription: Subscription;
  public _currentCdNomenclature: Array<any> = null;
  public currentIdNomenclature: number;
  @Input() codeNomenclatureType: string;
  @Input() regne: string;
  @Input() group2Inpn: string;
  @Input() keyValue;
  @Input() bindAllItem: boolean = false;
  constructor(private _dfService: DataFormService, private _translate: TranslateService) {
    super();
  }

  ngOnInit() {
    this.keyValue = this.keyValue || 'id_nomenclature';
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
    });
  }

  get currentCdNomenclature(): string {
    for (var i = 0; i < this._currentCdNomenclature.length; i++) {
      if (this.currentIdNomenclature === this._currentCdNomenclature[i]['id_nomenclature']) {
        return this._currentCdNomenclature[i]['cd_nomenclature'];
      }
    }
    return null;
  }

  getCdNomenclature():string {
    return this.currentCdNomenclature;
  }

  ngOnChanges(changes: SimpleChanges) {
    super.ngOnChanges(changes);
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
    this.labels = this._dfService
                      .getNomenclature(this.codeNomenclatureType, this.regne, this.group2Inpn, filters)
                      .pipe(
                        map(data => {
                          this._currentCdNomenclature = data.values;
                          return data.values;
                        })
                      );
  }

  ngOnDestroy() {
    this.subscription.unsubscribe();
    this.valueSubscription.unsubscribe();
  }
}
