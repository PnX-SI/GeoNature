import { Component, OnInit } from '@angular/core';
import { NavService } from '../../services/nav.service';
import { MapService } from '../../services/map.service';

@Component({
  selector: 'app-contact-faune',
  templateUrl: './contact-faune.component.html',
  styleUrls: ['./contact-faune.component.scss'],
  providers: [MapService]
})
export class ContactFauneComponent implements OnInit {

  constructor(private _navService: NavService, private _mapService: MapService) {
      _navService.setAppName('Contact Faune');
  }

  ngOnInit() {
  }

}
