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

  rows: Observable<any[]>;
  columns = [
    { name: 'Name' },
    { name: 'Gender' },
    { name: 'Company' }
  ];

  // displayedColumns = ['taxon', 'observateurs', 'dataset', 'date'];
  // releves: BehaviorSubject<any[]> = new BehaviorSubject<any[]>([]);
  // dataSource = new MapListDataSource(this.releves);

  constructor(private _mapListService: MapListService) {
    // _mapListService.getReleves().subscribe(res => this.releves.next(res));
    this.rows = Observable.create((subscriber) => {
      this.fetch((data) => {
        subscriber.next(data.splice(0, 15));
        subscriber.next(data.splice(15, 30));
        subscriber.complete();
      });
    });


    // Rx.DOM.ajax({ url: '/products', responseType: 'json'}).subscribe()
    // this.rows = Observable.from(rows);
  }

  ngOnInit() {}

  fetch(cb) {
    const req = new XMLHttpRequest();
    req.open('GET', `assets/data/company.json`);

    req.onload = () => {
      cb(JSON.parse(req.response));
    };

    req.send();
  }

}

// export class MapListDataSource extends DataSource<any> {

//   constructor(private _releves: BehaviorSubject<any[]>) {
//     super();
//   }
//   /** Connect function called by the table to retrieve one stream containing the data to render. */
//   connect() {
//     return this._releves;
//   }

//   disconnect() {}
// }
