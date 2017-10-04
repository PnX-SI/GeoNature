import { Component, OnInit, Input, Output, EventEmitter, OnChanges, OnDestroy, SimpleChanges, ViewEncapsulation } from '@angular/core';
import { FormControl, FormGroup } from '@angular/forms';
import { DataFormService } from '../data-form.service';
import { TranslateService, LangChangeEvent} from '@ngx-translate/core';
import { Subscription } from 'rxjs/Subscription';

@Component({
  selector: 'pnx-nomenclature',
  templateUrl: './nomenclature.component.html',
  styleUrls: ['./nomenclature.component.scss'],
  encapsulation: ViewEncapsulation.None
})
export class NomenclatureComponent implements OnInit, OnChanges, OnDestroy {
  labels: any[];
  selectedId: number;
  labelLang:string;
  subscription: Subscription;
  valueSubscription: Subscription;
  @Input() placeholder: string;
  @Input() parentFormControl: FormControl;
  @Input() idTypeNomenclature: number;
  @Input() regne: string;
  @Input() group2Inpn: string;
  @Input() disabled: boolean;
  @Output() valueSelected = new EventEmitter<number>();

  constructor(private _dfService: DataFormService, private _translate:TranslateService) { }

  ngOnInit() {
    this.labelLang = 'label_'+this._translate.currentLang;
    // load the data
    this.initLabels();
    // subscrib to the language change
    this.subscription = this._translate.onLangChange.subscribe((event: LangChangeEvent) => {
      this.labelLang = 'label_'+this._translate.currentLang;
    });

    // output
    this.valueSubscription = this.parentFormControl.valueChanges
      .subscribe(id => {
        this.valueSelected.emit(id);
      });
  }

  ngOnChanges(changes: SimpleChanges) {
    // if change regne => change groupe2inpn also
    if (changes.regne !== undefined && !changes.regne.firstChange) {
      this.initLabels();
    }
    // if only change groupe2inpn
    if (changes.regne === undefined && changes.group2Inpn !== undefined && !changes.group2Inpn.firstChange) {
      this.initLabels();
    }
  }

  initLabels() {
    this._dfService.getNomenclature(this.idTypeNomenclature, this.regne, this.group2Inpn)
      .subscribe(data => {
        this.labels = data.values;
        // disable the input if undefined
        if (this.labels === undefined) {
          this.parentFormControl.disable();
        }
      });
  }


  ngOnDestroy() {
    this.subscription.unsubscribe();
    this.valueSubscription.unsubscribe();
  }
}
