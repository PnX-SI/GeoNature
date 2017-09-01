import { Component, OnInit } from '@angular/core';
import { NavService } from '../../core/services/nav.service';
import { MapService } from '../../core/GN2Common/map/map.service';


@Component({
  selector: 'pnx-contact',
  templateUrl: './contact.component.html',
  styleUrls: ['./contact.component.scss'],
  providers: [MapService]
})
export class ContactComponent implements OnInit {
  public coord: any;

  constructor(private _navService: NavService, private _ms: MapService) {
      _navService.setAppName('Contact Faune - Flore ');
  }

  ngOnInit() { }

}
