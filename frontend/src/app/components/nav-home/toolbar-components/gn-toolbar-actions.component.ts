import { Component, Input, Output, EventEmitter } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatTooltipModule } from '@angular/material/tooltip';
import { MatMenuModule } from '@angular/material/menu';
import { MatDividerModule } from '@angular/material/divider';
import { TranslateModule } from '@ngx-translate/core';
import { GnToolbarIconButtonComponent } from './gn-toolbar-icon-button.component';

@Component({
  selector: 'gn-toolbar-actions',
  standalone: true,
  imports: [
    CommonModule,
    MatButtonModule,
    MatIconModule,
    MatTooltipModule,
    MatMenuModule,
    MatDividerModule,
    TranslateModule,
    GnToolbarIconButtonComponent,
  ],
  templateUrl: './gn-toolbar-actions.component.html',
  styleUrls: ['./gn-toolbar-actions.component.scss'],
})
export class GnToolbarActionsComponent {
  @Input() isMobile = false;
  @Input() documentationUrl = '';
  @Input() isPublicAccess = false;

  @Output() logoutClick = new EventEmitter<void>();

  logout(): void {
    this.logoutClick.emit();
  }
}
