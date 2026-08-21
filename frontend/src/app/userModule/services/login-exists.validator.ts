import { Injectable } from '@angular/core';
import { AbstractControl, AsyncValidator, ValidationErrors } from '@angular/forms';
import { Observable, of } from 'rxjs';
import { map, debounceTime, switchMap, catchError } from 'rxjs/operators';
import { AuthService } from '@geonature/components/auth/auth.service';
import { UserDataService } from '@geonature/userModule/services/user-data.service';

@Injectable({ providedIn: 'root' })
export class LoginExistsValidator implements AsyncValidator {
  constructor(
    private user_service: UserDataService,
    private authService: AuthService
  ) {}

  validate(control: AbstractControl): Observable<ValidationErrors | null> {
    if (!control.value) {
      return of(null);
    }

    const login = control.value;
    const currentUser = this.authService.getCurrentUser();

    if (currentUser && currentUser.user_login === login) {
      return of(null);
    }

    return of(login).pipe(
      debounceTime(300),
      switchMap((value) =>
        this.user_service.checkLoginExists(value).pipe(
          map((loginExists) => (loginExists ? { loginExists: { value } } : null)),
          catchError(() => of(null))
        )
      )
    );
  }
}
