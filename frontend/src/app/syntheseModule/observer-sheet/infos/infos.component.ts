import { CommonModule } from '@angular/common';
import { Component, OnInit } from '@angular/core';
import { ObserverSheetService } from '../observer-sheet.service';
@Component({
  standalone: true,
  selector: 'infos',
  templateUrl: 'infos.component.html',
  styleUrls: ['infos.component.scss'],
  imports: [CommonModule],
})
export class InfosComponent implements OnInit {
  observer: string | null = null;

  constructor(private _oss: ObserverSheetService) {}

  ngOnInit() {
    this._oss.observer.subscribe((observer: string | null) => {
      this.observer = observer;
    });
  }
}
