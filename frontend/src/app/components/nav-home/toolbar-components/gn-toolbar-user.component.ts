import { Component, Input, Output, EventEmitter } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatButtonModule } from '@angular/material/button';
import { MatMenuModule } from '@angular/material/menu';
import { MatIconModule } from '@angular/material/icon';
import { MatDividerModule } from '@angular/material/divider';
import { MatTooltipModule } from '@angular/material/tooltip';
import { RouterModule } from '@angular/router';
import { TranslateModule } from '@ngx-translate/core';

interface User {
  user_login: string;
  [key: string]: any;
}

@Component({
  selector: 'gn-toolbar-user',
  standalone: true,
  imports: [
    CommonModule,
    MatButtonModule,
    MatMenuModule,
    MatIconModule,
    MatDividerModule,
    MatTooltipModule,
    RouterModule,
    TranslateModule,
  ],
  templateUrl: './gn-toolbar-user.component.html',
  styleUrls: ['./gn-toolbar-user.component.scss'],
})
export class GnToolbarUserComponent {
  @Input() isMobile = false;
  @Input() currentUser: User | null = null;
  @Input() displayName = '';
  @Input() displayOrganism = '';
  @Input() useLocalProvider = false;
  @Input() accountManagementEnabled = false;
  @Input() hasObserverSheet = false;
  @Input() observerSheetUrl: string | any[] = '';
  @Input() publicAccessUsername = '';

  get isPublicAccess(): boolean {
    return this.currentUser?.user_login === this.publicAccessUsername;
  }
}
