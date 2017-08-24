import { Component, OnInit, Input, Output, EventEmitter } from '@angular/core';
import {NomenclatureComponent} from '../nomenclature/nomenclature.component';
import { Counting } from './counting.type';


@Component({
  selector: 'app-counting',
  templateUrl: './counting.component.html',
  styleUrls: ['./counting.component.scss']
})
export class CountingComponent implements OnInit {
  counting: Counting;
  @Input() index: string;
  @Output() countingAdded = new EventEmitter<any>();
  @Output() inputAdded = new EventEmitter<any>();
  constructor() { }

  ngOnInit() {
    this.counting = new Counting();
  }
  updateModelWithLabel(nomenclatureObj, index): void {
    console.log(nomenclatureObj);
    this.inputAdded.emit({nomenclatureObj, index});

  }
  simpleUpdateModel(key, value, index): void {
    const nomenclatureObj = {nomenclature: key, idLabel: value};
    console.log(nomenclatureObj);
    this.inputAdded.emit({nomenclatureObj, index});
   }

  addCounting(): void {
    this.countingAdded.emit();
  }
}
