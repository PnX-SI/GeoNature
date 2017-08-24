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
  @Input() length: number;
  @Output() countingAdded = new EventEmitter<any>();
  @Output() countingRemoved = new EventEmitter<any>();
  @Output() inputUpdated = new EventEmitter<any>();
  constructor() { }

  ngOnInit() {
    this.counting = new Counting();
  }
  updateCountingInput(key, value, index): void {
    this.inputUpdated.emit({key, value, index});
  }

  addCounting(): void {
    this.countingAdded.emit();
  }
  onRemoveCounting(index): void {
    this.countingRemoved.emit(index);
  }
}
