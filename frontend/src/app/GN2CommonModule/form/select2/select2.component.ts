import { Component, OnInit, OnChanges, Input, Output, EventEmitter } from '@angular/core';
import { FormControl } from '@angular/forms';
import { TranslateService } from '@ngx-translate/core';
import { Select2OptionData } from 'ng-select2';
import { Options } from 'select2';
import { Observable, BehaviorSubject } from 'rxjs';

@Component({
  selector: 'pnx-select2',
  templateUrl: './select2.component.html',
  styleUrls: ['./select2.component.scss']
})
export class Select2Component implements OnInit, OnChanges {

  public select2Data: Array<Select2OptionData>;
  public options: Options;
  public value: string[];

  @Input() parentFormControl: FormControl = null;
  //select2Val:valeurs pouvant être transmises sans lien avec un formulaire
  @Input() select2Val: Observable<string[]>;
  // value of the dropddown
  @Input() values: Observable<any[]>;
  // key of the array of options for the formControl value
  @Input() keyValue: string;
  // key of the array of options for the input displaying
  @Input() keyLabel: string;
  // Display all in the select list (set the control to null)
  @Input() displayAll: boolean = false;
  // disable the input
  @Input() disabledSelect2: boolean = false;
  // label displayed above the input
  @Input() label: string = '';
  // label displayed above the input
  @Input() placeholder: string = '';
  // label displayed above the input
  @Input() width: string = '100%';
  // label displayed above the input
  @Input() multiple: boolean = false;
  //surveille si les données doivent être réactualisées (relance de la requete http)
  @Input() reloadData: BehaviorSubject<boolean> = new BehaviorSubject(false);
  @Output() onChange = new EventEmitter<any>();

  constructor(private _translate: TranslateService) {}

  ngOnInit() {
    if (this.parentFormControl !== null && this.select2Val !== undefined) {
      throw new Error('l\'attribut [parentFormControl] et [select2Val] ne peuvent être déclarés ensemble');
    }

    this.getValues();

    this.options = {
      width: this.width,
      multiple: this.multiple
    };

    //traduction des éléments
    this._translate.get(this.placeholder, {value: this.placeholder}).subscribe((res: string) => {
        this.placeholder = res;
    })

    //creation du formcontrol de ce select si select2 non associé à un form parent
    if (this.parentFormControl === null) {
      this.parentFormControl = new FormControl('');
      this.select2Val.subscribe(res => {this.parentFormControl.setValue(res)});
    }
  }

  getValues() {
    this.values.subscribe(res => {
      //transforme les données values en Select2OptionData {id, text}
      //trie le tableau par ordre alphabetique
      this.select2Data = res.map(val => ({ "id": val[this.keyValue].toString(), "text": val[this.keyLabel] }))
                                    .sort((a, b) => (a.text > b.text) ? 1 : -1);
    });
  }

  onSelect(value) {
    this.onChange.emit(value);
  }

  ngOnChanges() {
    if (this.reloadData.getValue()) {
      this.getValues();
      this.reloadData.next(false);
    }
  }

}
