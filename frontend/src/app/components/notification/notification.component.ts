import { Component, OnInit, OnDestroy, ViewChild } from '@angular/core';
import { AppConfig } from '@geonature_config/app.config';
import { AuthService, User } from '@geonature/components/auth/auth.service';
import { NotificationDataService } from '@geonature/components/notification/notification-data.service';
import { MatPaginator } from '@angular/material/paginator';
import { Observable } from 'rxjs';
import { MatTableDataSource } from '@angular/material/table';

export interface NotificationCard {
  title: string;
  content: string;
  url: string;
  code_status: string;
  creation_date: string;
}

const NOTIFICATION_DATA: NotificationCard[] = [
  {
    title: 'Modification du statut',
    code_status: 'unread',
    content: "Le statut de l'observation a été modifié ( Invalide )",
    url: 'http://geonature.jdev.fr/geonature/#/validation/occurrence/2',
    creation_date: '09:32 28/09/2022',
  },
  {
    title: 'Modification du statut',
    code_status: 'unread',
    content: "Le statut de l'observation a été modifié ( Probable )",
    url: 'http://geonature.jdev.fr/geonature/#/validation/occurrence/2',
    creation_date: '09:28 28/09/2022',
  },
  {
    title: 'Modification du statut',
    code_status: 'read',
    content: "Le statut de l'observation a été modifié ( Douteux )",
    url: 'http://geonature.jdev.fr/geonature/#/validation/occurrence/2',
    creation_date: '09:12 10/09/2022',
  },
  {
    title: 'Modification du statut',
    code_status: 'read',
    content: "Le statut de l'observation a été modifié ( Invalide )",
    url: 'http://geonature.jdev.fr/geonature/#/validation/occurrence/2',
    creation_date: '07:55 10/09/2022',
  },
  {
    title: 'Modification du statut',
    code_status: 'read',
    content: "Le statut de l'observation a été modifié",
    url: 'http://geonature.jdev.fr/geonature/#/validation/occurrence/2',
    creation_date: '17:19 28/08/2022',
  },
  {
    title: 'Modification du statut',
    code_status: 'read',
    content: "Le statut de l'observation a été modifié",
    url: 'http://geonature.jdev.fr/geonature/#/validation/occurrence/2',
    creation_date: '10:49 26/08/2022',
  },
  {
    title: 'Modification du statut',
    code_status: 'read',
    content: "Le statut de l'observation a été modifié",
    url: 'http://geonature.jdev.fr/geonature/#/validation/occurrence/2',
    creation_date: '11:28 01/07/2022',
  },
  {
    title: 'Modification du statut',
    code_status: 'read',
    content: "Le statut de l'observation a été modifié",
    url: 'http://geonature.jdev.fr/geonature/#/validation/occurrence/2',
    creation_date: '11:28 01/07/2022',
  },
  {
    title: 'Modification du statut',
    code_status: 'read',
    content: "Le statut de l'observation a été modifié",
    url: 'http://geonature.jdev.fr/geonature/#/validation/occurrence/2',
    creation_date: '11:28 01/07/2022',
  },
  {
    title: 'Modification du statut',
    code_status: 'read',
    content: "Le statut de l'observation a été modifié",
    url: 'http://geonature.jdev.fr/geonature/#/validation/occurrence/2',
    creation_date: '11:28 01/07/2022',
  },
  {
    title: 'Modification du statut',
    code_status: 'read',
    content: "Le statut de l'observation a été modifié",
    url: 'http://geonature.jdev.fr/geonature/#/validation/occurrence/2',
    creation_date: '11:28 01/07/2022',
  },
];

@Component({
  selector: 'pnx-notification',
  templateUrl: './notification.component.html',
  styleUrls: ['./notification.component.scss'],
})
export class NotificationComponent implements OnInit, OnDestroy {
  public currentUser: User;
  public notifications: any;

  @ViewChild(MatPaginator) paginator: MatPaginator;
  obs: Observable<any>;
  dataSource: MatTableDataSource<NotificationCard> = new MatTableDataSource<NotificationCard>(
    NOTIFICATION_DATA
  );
  constructor(
    public authService: AuthService,
    private notificationDataService: NotificationDataService
  ) {}

  ngOnInit(): void {
    this.currentUser = this.authService.getCurrentUser();
    this.obs = this.dataSource.connect();
    //this.getNotifications();
  }

  /**
   * get all notifications for current user
   */
  getNotifications() {
    this.notificationDataService.getNotifications().subscribe((response) => {
      this.setNotifications(response);
    });
  }

  /**
   *  Sort notification by creation_date
   * @param data
   */
  setNotifications(data) {
    let listEl = data.length ? data : [];

    this.notifications = listEl;
  }

  ngOnDestroy() {
    if (this.dataSource) {
      this.dataSource.disconnect();
    }
  }
}
