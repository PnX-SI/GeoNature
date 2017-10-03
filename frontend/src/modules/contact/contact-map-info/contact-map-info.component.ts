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
  constructor(private _cfs: ContactFormService, private _route: ActivatedRoute, private _ms: MapService) { }

  ngOnInit() {
    this._sub = this._route.params.subscribe(params => {
      this.id = +params['id'];
      if (!isNaN(this.id )) {
        // load one releve
        this._cfs.getReleve(this.id)
          .subscribe(data => {
            console.log(data);
            this._ms.loadGeometryReleve(data);
        });
      }
  });
  }
}
