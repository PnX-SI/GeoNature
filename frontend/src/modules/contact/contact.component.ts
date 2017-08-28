import { Component, OnInit } from '@angular/core';
import { NavService } from '../../core/services/nav.service';
import { MapService } from '../../core/services/map.service';

@Component({
  selector: 'gn-contact',
  templateUrl: './contact.component.html',
  styleUrls: ['./contact.component.scss'],
  providers: [MapService]
})
export class ContactComponent implements OnInit {

  constructor(private _navService: NavService, private _mapService: MapService) {
      _navService.setAppName('Contact Faune');
  }

  ngOnInit() {
  }

}
