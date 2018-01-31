import { Component, OnInit, OnDestroy } from '@angular/core';
import { Http } from '@angular/http';
import { AppConfig } from '../../../conf/app.config';
import { GeoJSON } from 'leaflet';
import { MapListService } from '../../../core/GN2Common/map-list/map-list.service';
import { Subscription } from 'rxjs/Subscription';
import { ContactService } from '../services/contact.service';
import { CommonService } from '../../../core/GN2Common/service/common.service';
import { AuthService } from '../../../core/components/auth/auth.service';
import {TranslateService} from '@ngx-translate/core';
import { Router } from '@angular/router';
import { FormControl } from '@angular/forms';
import { ColumnActions } from '@geonature_common/map-list/map-list.component';

@Component({
  selector: 'pnx-contact-map-list',
  templateUrl: 'contact-map-list.component.html',
  styleUrls: ['./contact-map-list.component.scss']
})

export class ContactMapListComponent implements OnInit {
  public geojsonData: GeoJSON;
  public displayColumns: Array<any>;
  public pathEdit: string;
  public pathInfo: string;
  public idName: string;
  public apiEndPoint: string;
  public inputTaxon = new FormControl();
  public inputObservers = new FormControl();
  public dateMinInput = new FormControl();
  public dateMaxInput = new FormControl();
  public columnActions: ColumnActions;
  constructor( private _http: Http, private _mapListService: MapListService, private _contactService: ContactService,
    private _commonService: CommonService, private _auth: AuthService,
   private _translate: TranslateService,
   private _router: Router
  ) { }

  ngOnInit() {
  // parameters for maplist
  this.displayColumns = [
   {prop: 'taxons', name: 'Taxon', display: true},
   {prop: 'observateurs', 'name': 'Observateurs'},
  ];

  this.idName = 'id_releve_contact';
  this.apiEndPoint = 'contact/vreleve';

  this.columnActions = {
    'editColumn': true,
    'infoColumn': true,
    'deleteColumn': true,
    'validateColumn': false,
    'unValidateColumn': false
  };

  this._mapListService.getData('contact/vreleve')
    .subscribe(res => {
      this._mapListService.page.totalElements = res.items.features.length;
      this.geojsonData = res.items;
    });
  }

   deleteReleve(id) {
    this._contactService.deleteReleve(id)
      .subscribe(
        data => {
          this._mapListService.deleteObs(id);
            this._commonService.translateToaster('success', 'Releve.DeleteSuccessfully');

        },
        error => {
          if (error.status === 403) {
            this._commonService.translateToaster('error', 'NotAllowed');
          } else {
            this._commonService.translateToaster('error', 'ErrorMessage');
          }

        });
   }

   taxonChanged(taxonObj) {
    // refresh taxon in url query
    this._mapListService.urlQuery = this._mapListService.urlQuery.delete('cd_nom');
    this._mapListService.refreshData(this.apiEndPoint, {param: 'cd_nom', 'value': taxonObj.cd_nom});
  }

  observerChanged(observer) {
    this._mapListService.refreshData(this.apiEndPoint, {param: 'observer', 'value': observer.id_role});
  }

  observerDeleted(observer) {
    const idObservers = this._mapListService.urlQuery.getAll('observer');
    this._mapListService.urlQuery = this._mapListService.urlQuery.delete('observer');
    idObservers.forEach(id => {
      if (id !== observer.id_role) {
        this._mapListService.urlQuery = this._mapListService.urlQuery.set('observer', id);
      }
    });
    this._mapListService.refreshData(this.apiEndPoint);
  }

  dateMinChanged(date) {
    this._mapListService.urlQuery = this._mapListService.urlQuery.delete('date_up');
    if (date.length > 0) {
      this._mapListService.refreshData(this.apiEndPoint, {param: 'date_up', 'value': date});
    } else {
      this._mapListService.deleteAndRefresh(this.apiEndPoint, 'date_up');
    }
  }
  dateMaxChanged(date) {
    this._mapListService.urlQuery = this._mapListService.urlQuery.delete('date_low');
    if (date.length > 0) {
      this._mapListService.refreshData(this.apiEndPoint, {param: 'date_low', 'value': date});
    }else {
      this._mapListService.deleteAndRefresh(this.apiEndPoint, 'date_low');
    }
  }

  editReleve(id_releve) {
    this._router.navigate(['occtax/form', id_releve]);
  }

  infoReleve(id_releve) {
    this._router.navigate(['occtax/info', id_releve]);
  }

  addReleve() {
    this._router.navigate(['occtax/form']);
  }



  refreshFilters() {
    this.inputTaxon.reset();
    this.dateMaxInput.reset();
    this.dateMinInput.reset();
    this.inputObservers.reset();
    this._mapListService.genericFilterInput.reset();
    this._mapListService.refreshUrlQuery();
    this._mapListService.refreshData(this.apiEndPoint);
  }

}


