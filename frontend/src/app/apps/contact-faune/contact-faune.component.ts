import { Component, OnInit } from '@angular/core';
import { NavService } from '../../services/nav.service';


@Component({
  selector: 'app-contact-faune',
  templateUrl: './contact-faune.component.html',
  styleUrls: ['./contact-faune.component.scss']
})
export class ContactFauneComponent implements OnInit {

  constructor(private _navService: NavService) {
      _navService.setAppName('Contact Faune');
  }

  ngOnInit() {
  }

}
