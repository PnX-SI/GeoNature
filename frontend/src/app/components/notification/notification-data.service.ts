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

export interface NotificationCard {
  id_notification: string;
  title: string;
  content: string;
  url: string;
  code_status: string;
  creation_date: string;
}

@Injectable()
export class NotificationDataService {
  constructor(private _api: HttpClient) {}

  // Create notification
  createNotification(data) {
    return this._api.put(`${AppConfig.API_ENDPOINT}/notifications/notification`, data, {
      headers: new HttpHeaders().set('Content-Type', 'application/json'),
    });
  }

  // returns notifications content for this user
  getNotifications() {
    return this._api.get<NotificationCard[]>(
      `${AppConfig.API_ENDPOINT}/notifications/notifications`
    );
  }

  // returns number of notification for this user
  getNotificationsNumber(): any {
    console.log('Call notification count');
    return this._api.get<any>(`${AppConfig.API_ENDPOINT}/notifications/count`);
  }

  updateNotification(data: any) {
    return this._api.post(`${AppConfig.API_ENDPOINT}/notifications/notification`, data, {
      headers: new HttpHeaders().set('Content-Type', 'application/json'),
    });
  }
}
