import { Component, Input } from '@angular/core';

import { ConfigService } from '@geonature/services/config.service';

@Component({
  selector: 'gn-auth-layout',
  templateUrl: './auth-layout.component.html',
  styleUrls: ['./auth-layout.component.scss'],
})
export class AuthLayoutComponent {
  @Input() formMaxWidth = '440px';

  constructor(public config: ConfigService) {}
}
