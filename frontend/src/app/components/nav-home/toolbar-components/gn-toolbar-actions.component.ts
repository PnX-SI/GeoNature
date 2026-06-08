import { Component, Input, Output, EventEmitter } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatBadgeModule } from '@angular/material/badge';
import { MatTooltipModule } from '@angular/material/tooltip';
import { MatMenuModule } from '@angular/material/menu';
import { MatDividerModule } from '@angular/material/divider';
import { TranslateModule } from '@ngx-translate/core';

@Component({
  selector: 'gn-toolbar-actions',
  standalone: true,
  imports: [
    CommonModule,
    MatButtonModule,
    MatIconModule,
    MatBadgeModule,
    MatTooltipModule,
    MatMenuModule,
    MatDividerModule,
    TranslateModule,
  ],
  templateUrl: './gn-toolbar-actions.component.html',
  styleUrls: ['./gn-toolbar-actions.component.scss'],
})
export class GnToolbarActionsComponent {
  @Input() isMobile = false;
  @Input() notificationsEnabled = false;
  @Input() notificationNumber = 0;
  @Input() documentationUrl = '';
  @Input() isPublicAccess = false;

  @Output() notificationClick = new EventEmitter<void>();
  @Output() logoutClick = new EventEmitter<void>();

  openNotifications(): void {
    this.notificationClick.emit();
  }

  logout(): void {
    this.logoutClick.emit();
  }
}
