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

  /**
   * Return the a view state based on the current user and configuration of GeoNature. The view state can be one of the following:
   * - 'public' → the current user is a public access user, no menu or link to observer sheet is displayed
   * - 'menu' → the current user is a local provider and account management is enabled, a menu with account management options is displayed
   * - 'linkedDisplay' → the current user has an observer sheet (but can't access account management page), a link to the observer sheet is displayed
   * - 'plainDisplay' → the current user does not have an observer sheet, only the display name and organism are displayed
   * @returns {string} The view state
   */
  get viewState(): 'public' | 'menu' | 'linkedDisplay' | 'plainDisplay' {
    if (this.isPublicAccess) {
      return 'public';
    }
    if (this.useLocalProvider && this.accountManagementEnabled) {
      return 'menu';
    }
    if (this.hasObserverSheet) {
      return 'linkedDisplay';
    }
    return 'plainDisplay';
  }
}
