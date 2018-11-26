import { Component, OnInit } from '@angular/core';

import { AuthService } from '@geonature/components/auth/auth.service';

@Component({
  selector: 'pnx-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.scss']
})
export class AppComponent implements OnInit {
  constructor(private _authService: AuthService) {}

  ngOnInit() {
    // activate idle to disconect the user when long passivity
    this._authService.activateIdle();
  }
}
