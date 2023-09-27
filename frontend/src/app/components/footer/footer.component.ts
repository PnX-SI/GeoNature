import { Component, OnInit } from '@angular/core';
import { ConfigService } from '@geonature/services/config.service';

@Component({
  selector: 'pnx-footer',
  templateUrl: 'footer.component.html',
})
export class FooterComponent implements OnInit {
  constructor(public config: ConfigService) {}

  ngOnInit() {}
}
