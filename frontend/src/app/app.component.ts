import { Component, OnInit } from '@angular/core';
import { TranslateService } from '@ngx-translate/core';
import { AuthService } from '@geonature/components/auth/auth.service';
import { AppConfig } from '../conf/app.config';

@Component({
  selector: 'pnx-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.scss']
})
export class AppComponent implements OnInit {
  constructor(
  	private _authService: AuthService, 
  	private translate: TranslateService
  ) {
  	translate.addLangs(['en', 'fr', 'cn']);
    translate.setDefaultLang(AppConfig.DEFAULT_LANGUAGE);
    translate.use(AppConfig.DEFAULT_LANGUAGE);
  }

  ngOnInit() {}
}
