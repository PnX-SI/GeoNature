import { Component, OnInit, Input, Output, EventEmitter, OnChanges, OnDestroy, SimpleChanges } from '@angular/core';
import { FormControl, FormGroup } from '@angular/forms';
import { DataFormService } from '../data-form.service';
import { TranslateService, LangChangeEvent} from '@ngx-translate/core';
import { Subscription } from 'rxjs/Subscription';

@Component({
  selector: 'pnx-nomenclature',
  templateUrl: './nomenclature.component.html',
  styleUrls: ['./nomenclature.component.scss']
})
export class NomenclatureComponent implements OnInit, OnChanges, OnDestroy {
  labels: any[];
  nomenclature: any;
  selectedId: number;
  labelLang:string;
  subscription: Subscription;
  @Input() placeholder: string;
  @Input() parentFormControl: FormGroup;
  @Input() idTypeNomenclature: number;
  @Input() regne: string;
  @Input() group2Inpn: string;
  @Output() valueSelected = new EventEmitter<any>();

  constructor(private _dfService: DataFormService, private _translate:TranslateService) { }

  ngOnInit() {
    this.labelLang = 'definition_'+this._translate.currentLang;    
    // load the data
    this.initLabels();
    // subscrib to the language change
    this.subscription = this._translate.onLangChange.subscribe((event: LangChangeEvent) => {
      this.labelLang = 'definition_'+this._translate.currentLang;  
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

  initLabels(){
    this._dfService.getNomenclature(this.idTypeNomenclature, this.regne, this.group2Inpn)
      .subscribe(data => {
        this.labels = data.values;
        // disable the input if undefined
        if(this.labels === undefined){
          this.parentFormControl.disable();
        }
      });
  }
  // Output
  onLabelChange() {
    this.valueSelected.emit(this.selectedId);
  }

  ngOnDestroy(){
    this.subscription.unsubscribe();
  }
}
