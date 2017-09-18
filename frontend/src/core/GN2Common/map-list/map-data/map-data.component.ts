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
  releves = [];
  rows: BehaviorSubject<RowsData[]> = new BehaviorSubject<RowsData[]>([]);

  constructor(private _mapListService: MapListService) {
    _mapListService.getReleves().subscribe(res => {
      res.features.forEach(el => {
        const row: RowsData = {
          id : el.id,
          taxon : el.properties.occurrences.map(occ => occ.nom_cite ).join(', '),
          observer : el.properties.observers.map(obs => obs.prenom_role + ' ' + obs.nom_role).join(', '),
          date  : el.properties.meta_create_date
        };
        this.releves.push(row);
      });

      this.rows.next(this.releves);
    });
    this._mapListService.gettingLayerId$.subscribe(res => {
      this.selected = [];
      this.selected = [ this.releves[1], this.releves[3] ];
      console.log(this.selected);
    });
  }

  ngOnInit() {
  }

  onSelect({ selected }) {
    console.log(selected);
    this._mapListService.setCurrentLayerId(this.selected[0].id);
  }

}

export interface RowsData {
  id: any;
  taxon: any;
  observer: any;
  date: any;
}

