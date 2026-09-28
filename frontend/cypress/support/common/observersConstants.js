/**
 * Constants shared by the `pnx-observers` Cypress commands (./observers.js) and specs.
 * Kept in a side-effect-free module so specs can import them without re-registering commands.
 */

export const OBSERVERS_SELECT = '[data-qa="gn-common-form-observers-select"]';

// Matches /users/menu/, /users/menu/<id_menu> and /users/menu_from_code/<code> (with any query)
export const USERS_MENU_URL = /\/users\/menu(_from_code)?\/[^/?]*(\?.*)?$/;
// Same routes, only when called with a `nom_complet` search parameter
export const USERS_MENU_SEARCH_URL = /\/users\/menu(_from_code)?\/[^/?]*\?(.*&)?nom_complet=/;

export const OBSERVERS_MIN_CHARS_MESSAGE = 'Saisir au moins 2 caractères';

// Longer than the component's 300ms debounce
export const OBSERVERS_DEBOUNCE_WAIT = 800;
