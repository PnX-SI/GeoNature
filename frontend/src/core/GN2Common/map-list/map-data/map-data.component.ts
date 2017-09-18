import { Component, OnInit, ElementRef, ViewChild} from '@angular/core';
import { MapService } from '../../map/map.service';
import {MapListService} from '../../map-list/map-list.service';

import {BehaviorSubject} from 'rxjs/BehaviorSubject';
import {Observable} from 'rxjs/Observable';
import 'rxjs/add/operator/startWith';
import 'rxjs/add/observable/merge';
import 'rxjs/add/operator/map';
import 'rxjs/add/operator/debounceTime';
import 'rxjs/add/operator/distinctUntilChanged';
import 'rxjs/add/observable/fromEvent';


@Component({
  selector: 'pnx-map-data',
  templateUrl: './map-data.component.html',
  styleUrls: ['./map-data.component.scss']
})
export class MapDataComponent implements OnInit {

  columns = [
    { prop: 'taxon' },
    { prop: 'observer' },
    { prop: 'date' }
  ];
  selected = [];
  rows: BehaviorSubject<RowsData[]> = new BehaviorSubject<RowsData[]>([]);

  constructor(private _mapListService: MapListService) {
    _mapListService.getReleves().subscribe(res => {
      const releves = [];
      res.features.forEach(el => {
        const row: RowsData = {
          id : el.id,
          taxon : el.properties.occurrences.map(occ => occ.nom_cite ).join(', '),
          observer : el.properties.observers.map(obs => obs.prenom_role + ' ' + obs.nom_role).join(', '),
          date  : el.properties.meta_create_date
        };
        releves.push(row);
      });

      this.rows.next(releves);
    });
  }

  ngOnInit() {
    this._mapListService.gettingLayerId$.subscribe(res => console.log(res));
  }

  onSelect({ selected }) {
    this._mapListService.setCurrentLayerId(this.selected[0].id);
  }

}

export interface RowsData {
  id: any;
  taxon: any;
  observer: any;
  date: any;
}

