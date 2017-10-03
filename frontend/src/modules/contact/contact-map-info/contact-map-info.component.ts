import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { Subscription } from 'rxjs/Subscription';
import { ContactFormService } from '../contact-map-form/form/contact-form.service';
import { MapService } from '../../../core/GN2Common/map/map.service';


@Component({
  selector: 'pnx-contact-map-info',
  templateUrl: 'contact-map-info.component.html'
})

export class ContactMapInfoComponent implements OnInit {
  private _sub: Subscription;
  public id: number;
  public releve: any;
  public observers: any;
  constructor(private _cfs: ContactFormService, private _route: ActivatedRoute, private _ms: MapService) { }

  ngOnInit() {
    this._sub = this._route.params.subscribe(params => {
      this.id = +params['id'];
      if (!isNaN(this.id )) {
        // load one releve
        this._cfs.getReleve(this.id)
          .subscribe(data => {
            this.releve = data;
            this.observers = data.properties.observers.map(obs => obs.nom_role + ' ' + obs.prenom_role).join(', ');
            console.log(this.observers);

            this._ms.loadGeometryReleve(data);
        });
      }
  });
  }
}
