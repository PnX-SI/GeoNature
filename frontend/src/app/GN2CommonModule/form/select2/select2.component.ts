import { Component, OnInit, Input } from '@angular/core';
import { FormControl } from '@angular/forms';
import { TranslateService } from '@ngx-translate/core';
import { Select2OptionData } from 'ng-select2';
import { Options } from 'select2';
import { Observable } from 'rxjs/Observable';

@Component({
  selector: 'pnx-select2',
  templateUrl: './select2.component.html',
  styleUrls: ['./select2.component.scss']
})
export class Select2Component implements OnInit {

  public select2Data: Array<Select2OptionData>;
  public options: Options;
  public value: string[];

  @Input() parentFormControl: FormControl;
  // value of the dropddown
  @Input() values: Observable<Array<any>>;
  // key of the array of options for the formControl value
  @Input() keyValue: string;
  // key of the array of options for the input displaying
  @Input() keyLabel: string;
  // Display all in the select list (set the control to null)
  @Input() displayAll: boolean = false;
  // disable the input
  @Input() disabledControl: boolean = false;
  // label displayed above the input
  @Input() label: string = '';
  // label displayed above the input
  @Input() placeholder: string = '';
  // label displayed above the input
  @Input() width: string = '100%';
  // label displayed above the input
  @Input() multiple: boolean = false;

  constructor(private _translate: TranslateService) {}

  ngOnInit() {
    this.values.subscribe(res => {
      //transforme les données values en Select2OptionData {id, text}
      //trie le tableau par ordre alphabetique
      this.select2Data = res.map(val => ({ "id": val[this.keyValue], "text": val[this.keyLabel] }))
                                    .sort((a, b) => (a.text > b.text) ? 1 : -1);
    });

    this.options = {
      width: this.width,
      multiple: this.multiple
    };
  }
}
