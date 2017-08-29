import { Component, OnInit } from '@angular/core';
import { NavService } from '../../core/services/nav.service';

@Component({
  selector: 'pnx-contact',
  templateUrl: './contact.component.html',
  styleUrls: ['./contact.component.scss'],
  providers: []
})
export class ContactComponent implements OnInit {

  constructor(private _navService: NavService) {
      _navService.setAppName('Contact Faune');
  }

  ngOnInit() {
  }

}
