import { Component, OnInit } from '@angular/core';
import { NavService } from '../../services/nav.service';


@Component({
  selector: 'app-contact-flore',
  templateUrl: './contact-flore.component.html',
  styleUrls: ['./contact-flore.component.scss']
})
export class ContactFloreComponent implements OnInit {

  constructor(private _navService: NavService) {
      _navService.setAppName('Contact Flore');

  }

  ngOnInit() {
  }

}
