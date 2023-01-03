import {
  Component,
  OnInit,
  OnDestroy,
  ViewChild,
  ChangeDetectorRef,
  AfterViewInit,
} from '@angular/core';
import { NotificationDataService } from '@geonature/components/notification/notification-data.service';
import { NotificationCard } from '@geonature/components/notification/notification-data.service';
import { MatPaginator } from '@angular/material/paginator';
import { Observable } from 'rxjs';
import { MatTableDataSource } from '@angular/material/table';

@Component({
  selector: 'pnx-notification',
  templateUrl: './notification.component.html',
  styleUrls: ['./notification.component.scss'],
})
export class NotificationComponent implements OnInit, OnDestroy, AfterViewInit {
  @ViewChild(MatPaginator) paginator: MatPaginator;
  obs: Observable<any>;
  dataSource: MatTableDataSource<NotificationCard> = new MatTableDataSource<NotificationCard>();

  constructor(private notificationDataService: NotificationDataService) {}

  ngOnInit(): void {
    this.obs = this.dataSource.connect();
    this.getNotifications();
  }

  /**
   * get all notifications for current user
   */
  getNotifications() {
    this.notificationDataService.getNotifications().subscribe((response) => {
      this.dataSource.data = response;
    });
  }

  updateNotificationStatus(data: NotificationCard) {
    // Only update status if need
    if (data.code_status == 'UNREAD') {
      this.notificationDataService
        .updateNotification(data.id_notification)
        .subscribe((response) => {
          data.code_status = 'READ';
        });
    }
  }

  deleteNotifications() {
    this.notificationDataService.deleteNotifications().subscribe((response) => {
      // refresh rules values
      this.ngOnInit();
    });
  }

  ngOnDestroy() {
    if (this.dataSource) {
      this.dataSource.disconnect();
    }
  }

  ngAfterViewInit(): void {
    this.dataSource.paginator = this.paginator;
  }

  //function with param item object
  OnMatCardClickEvent(notification: NotificationCard) {
    // update status
    this.updateNotificationStatus(notification);
    // open given url if exist
    if (notification.url) {
      window.open(notification.url, '_self');
    }
  }
}
