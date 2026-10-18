import { ComponentFixture, TestBed } from '@angular/core/testing';
import { of } from 'rxjs';
import { NotificationComponent } from './notification.component';
import { NotificationDataService } from './notification-data.service';

describe('NotificationComponent', () => {
  let component: NotificationComponent;
  let fixture: ComponentFixture<NotificationComponent>;
  let service: {
    getNotifications: jest.Mock;
    updateNotification: jest.Mock;
    deleteNotifications: jest.Mock;
  };

  beforeEach(() => {
    service = {
      getNotifications: jest
        .fn()
        .mockReturnValue(of([{ id_notification: 1, code_status: 'UNREAD' }])),
      updateNotification: jest.fn().mockReturnValue(of({})),
      deleteNotifications: jest.fn().mockReturnValue(of({})),
    };
    TestBed.configureTestingModule({
      declarations: [NotificationComponent],
      providers: [{ provide: NotificationDataService, useValue: service }],
    });
    // the template needs the material table modules, only the logic is tested here
    TestBed.overrideComponent(NotificationComponent, { set: { template: '' } });
    fixture = TestBed.createComponent(NotificationComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('loads the notifications of the user', () => {
    expect(component.dataSource.data).toEqual([{ id_notification: 1, code_status: 'UNREAD' }]);
  });

  it('marks an unread notification as read', () => {
    const notification: any = { id_notification: 1, code_status: 'UNREAD' };
    component.updateNotificationStatus(notification);
    expect(service.updateNotification).toHaveBeenCalledWith(1);
    expect(notification.code_status).toBe('READ');
  });

  it('does not update a notification already read', () => {
    component.updateNotificationStatus({ id_notification: 1, code_status: 'READ' } as any);
    expect(service.updateNotification).not.toHaveBeenCalled();
  });

  it('reloads the notifications once deleted', () => {
    service.getNotifications.mockClear();
    component.deleteNotifications();
    expect(service.deleteNotifications).toHaveBeenCalled();
    expect(service.getNotifications).toHaveBeenCalled();
  });
});
