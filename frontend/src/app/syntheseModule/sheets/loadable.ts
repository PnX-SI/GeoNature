export class Loadable {
  _isLoading: boolean;

  constructor(isLoading: boolean = false) {
    this._isLoading = isLoading;
  }

  startLoading() {
    this._isLoading = true;
  }

  stopLoading() {
    this._isLoading = false;
  }

  get isLoading(): boolean {
    return this._isLoading;
  }
}
