import { Component, Input, Output, EventEmitter } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatButtonModule } from '@angular/material/button';
import { MatMenuModule } from '@angular/material/menu';
import { MatIconModule } from '@angular/material/icon';
import { MatDividerModule } from '@angular/material/divider';
import { MatTooltipModule } from '@angular/material/tooltip';
import { TranslateModule } from '@ngx-translate/core';
import { GnToolbarIconButtonComponent } from './gn-toolbar-icon-button.component';

interface LanguageOption {
  code: string;
  label: string;
  tooltip: string;
}

@Component({
  selector: 'gn-toolbar-language',
  standalone: true,
  imports: [
    CommonModule,
    MatButtonModule,
    MatMenuModule,
    MatIconModule,
    MatDividerModule,
    MatTooltipModule,
    TranslateModule,
    GnToolbarIconButtonComponent,
  ],
  templateUrl: './gn-toolbar-language.component.html',
})
export class GnToolbarLanguageComponent {
  @Input() isMobile = false;
  @Input() currentLocale = 'fr';
  @Input() multilingualEnabled = false;

  @Output() languageChange = new EventEmitter<string>();

  languages: LanguageOption[] = [
    { code: 'fr', label: 'AvailableLanguages.French', tooltip: 'Toolbar.Language.FrenchTooltip' },
    { code: 'en', label: 'AvailableLanguages.English', tooltip: 'Toolbar.Language.EnglishTooltip' },
    { code: 'zh', label: 'AvailableLanguages.Chinese', tooltip: 'Toolbar.Language.ChineseTooltip' },
  ];

  selectLanguage(locale: string): void {
    this.languageChange.emit(locale);
  }
}
