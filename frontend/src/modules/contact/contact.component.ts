import { Component, OnInit } from '@angular/core';
import { NavService } from '../../core/services/nav.service';
import { MapService } from '../../core/GN2Common/map/map.service';
import { AppConfig } from '../../conf/app.config';
import { mapOptions } from '../../core/GN2Common/map/map.options';


@Component({
  selector: 'pnx-contact',
  templateUrl: './contact.component.html',
  styleUrls: ['./contact.component.scss'],
  providers: [MapService]
})
export class ContactComponent implements OnInit {
  public mapEditionOptions: any;
  constructor(private _navService: NavService, private _ms: MapService) {
      _navService.setAppName('Contact Faune - Flore ');
  }

  ngOnInit() {
    this.mapEditionOptions = mapOptions;
   }

}
