import { Injectable } from '@angular/core';
import {
  HttpClient,
  HttpParams,
  HttpHeaders,
  HttpEventType,
  HttpErrorResponse,
  HttpEvent,
} from '@angular/common/http';

import { AppConfig } from '../../../conf/app.config';

import { Observable } from 'rxjs';

/** Interface to display notifications */
export interface NotificationCard {
  id_notification: string;
  title: string;
  content: string;
  url: string;
  code_status: string;
  creation_date: string;
}

/** Interface to serialise method rules */
export interface NotificationMethod {
  code: string;
  label: string;
  description: string;
}

/** Interface to serialise categorie rules */
export interface NotificationCategory {
  code: string;
  label: string;
  description: string;
}

/** Interface to serialise categorie rules */
export interface NotificationRule {
  id: number;
  code_category: string;
  code_method: string;
  method?: NotificationMethod;
  category?: NotificationCategory;
  subscribed: boolean;
}

@Injectable()
export class NotificationDataService {
  constructor(private _api: HttpClient) {}

  // returns notifications content for this user
  getNotifications(): Observable<NotificationCard[]> {
    return this._api.get<NotificationCard[]>(
      `${AppConfig.API_ENDPOINT}/notifications/notifications`
    );
  }

  // returns number of notification for this user
  getNotificationsNumber(): any {
    return this._api.get<any>(`${AppConfig.API_ENDPOINT}/notifications/count`);
  }

  deleteNotifications() {
    return this._api.delete<any>(`${AppConfig.API_ENDPOINT}/notifications/notifications`);
  }

  // update notification status
  updateNotification(idNotification) {
    return this._api.post(
      `${AppConfig.API_ENDPOINT}/notifications/notifications/${idNotification}`,
      {
        headers: new HttpHeaders().set('Content-Type', 'application/json'),
      }
    );
  }

  // returns all rules for current user
  getRules() {
    return this._api.get<NotificationRule[]>(`${AppConfig.API_ENDPOINT}/notifications/rules`);
  }

  // returns notifications content for this user
  getRulesCategories() {
    return this._api.get<NotificationCategory[]>(
      `${AppConfig.API_ENDPOINT}/notifications/categories`
    );
  }

  // returns notifications content for this user
  getRulesMethods() {
    return this._api.get<NotificationMethod[]>(`${AppConfig.API_ENDPOINT}/notifications/methods`);
  }

  subscribe(category, method) {
    return this._api.post(
      `${AppConfig.API_ENDPOINT}/notifications/rules/category/${category}/method/${method}/subscribe`,
      null
    );
  }

  unsubscribe(category, method) {
    return this._api.post(
      `${AppConfig.API_ENDPOINT}/notifications/rules/category/${category}/method/${method}/unsubscribe`,
      null
    );
  }

  clearSubscriptions() {
    return this._api.delete<any>(`${AppConfig.API_ENDPOINT}/notifications/rules`);
  }
}
