/*
 * Copyright (C) 2009  Camptocamp
 *
 * This file is part of MapFish Client
 *
 * MapFish Client is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * MapFish Client is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with MapFish Client.  If not, see <http://www.gnu.org/licenses/>.
 */

/*
 * This code is taken from the OpenLayers code base.
 *
 * Copyright (c) 2006-2007 MetaCarta, Inc., published under the Clear BSD
 * license.  See http://svn.openlayers.org/trunk/openlayers/license.txt for the
 * full text of the license.
 */

(function() {
  /**
   * Namespace: mapfish
   * The mapfish object provides a namespace for all things
   */
  window.mapfish = {

    /**
     * Property: _scriptName
     * {String} Relative path of this script.
     */
    _scriptName: "MapFish.js",

    /**
     * Function: _getScriptLocation
     * Return the path to this script.
     *
     * Returns:
     * Path to this script
     */
    _getScriptLocation: function() {
      // Workaround for Firefox bug:
      // https://bugzilla.mozilla.org/show_bug.cgi?id=351282
      if (window.gMfLocation) {
        return window.gMfLocation;
      }

      var scriptLocation = "";
      var scriptName = mapfish._scriptName;

      var scripts = document.getElementsByTagName('script');
      for (var i = 0; i < scripts.length; i++) {
        var src = scripts[i].getAttribute('src');
        if (src) {
          var index = src.lastIndexOf(scriptName);
          // is it found, at the end of the URL?
          if ((index > -1) && (index + scriptName.length == src.length)) {
            scriptLocation = src.slice(0, -scriptName.length);
            break;
          }
        }
      }
      return scriptLocation;
    }
  };
})();
