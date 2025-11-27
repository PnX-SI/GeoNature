import { CommonModule } from '@angular/common';
import { Component, OnInit } from '@angular/core';
import { ObserverSheetService } from '../observer-sheet.service';
import { Observer } from '../observer';
@Component({
  standalone: true,
  selector: 'infos',
  templateUrl: 'infos.component.html',
  styleUrls: ['infos.component.scss'],
  imports: [CommonModule],
})
export class InfosComponent implements OnInit {
  observer: Observer;

  constructor(private _oss: ObserverSheetService) {}

  ngOnInit() {
    this._oss.observer.subscribe((observer: Observer) => {
      this.observer = observer;
    });
  }
}
