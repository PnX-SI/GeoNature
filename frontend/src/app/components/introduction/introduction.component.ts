import { Component, OnInit } from '@angular/core';
import { ConfigService } from '@geonature/services/config.service';

@Component({
  selector: 'pnx-introduction',
  styleUrls: ['introduction.component.scss'],
  templateUrl: 'introduction.component.html',
})
export class IntroductionComponent implements OnInit {
  constructor(public config: ConfigService) {}

  ngOnInit() {}
}
