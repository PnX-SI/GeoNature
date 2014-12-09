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
 * @requires OpenLayers/Util.js
 * @include GeoExt/widgets/form.js
 */

Ext.namespace("mapfish.widgets.search");

/**
 * Class: mapfish.widgets.search.Form
 */

/**
 * Constructor: mapfish.widgets.search.Form
 *
 * Parameters:
 * config - {Object} A config object accepting the following
 * properties:
 * form - {Ext.form.FormPanel} or {Ext.form.BasicForm} The form
 *     this searcher wraps; mandatory.
 * protocol - {<OpenLayers.Protocol>} An OpenLayers protocol, the
 *     searcher searches this protocol for a
 *     {<mapfish.Protocol.MergeFilterDecorator>} instance (following
 *     the protocol chain) and registers itself into this
 *     instance, the protocol passed can itself be a
 *     {<mapfish.Protocol.MergeFilterDecorator>} instance;
 *     optional.
 * autobind - {Boolean} If false the searcher will not be
 *     registered into the protocol specified using the
 *     protocol option, optional.
 */
mapfish.widgets.search.Form = function(config) {
    config = config || {};

    if (config.autobind !== false) {
        this.bind(config.protocol);
    }
    delete config.autobind;
    delete config.protocol;

    Ext.apply(this, config);

    if (this.form instanceof Ext.form.FormPanel) {
        this.form = this.form.getForm();
    }
};

mapfish.widgets.search.Form.prototype = {
    /**
     * APIProperty: form
     * {<GeoExt.form.BasicForm>}
     */
    form: null,

    /**
     * APIMethod: getFilter
     * Return a {OpenLayers.Filter} from this searcher's form. 
     *
     * Returns:
     * {<OpenLayers.Filter>}
     */
    getFilter: function() {
        return GeoExt.form.toFilter(this.form);
    },

    /**
     * Method: bind
     * Bind this searcher to a {<mapfish.Protocol.MergeFilterDecorator>}
     * instance, the merge filter protocol is searched in the protocol
     * chain.
     *
     * Parameters:
     * protocol - {<OpenLayers.Protocol>}
     *
     * Returns:
     * {<mapfish.Protocol.MergeFilterDecorator>}
     */
    bind: function(protocol) {
        return (new mapfish.Searcher()).bind.apply(this, [protocol]);
    },

    /**
     * APIMethod: triggerSearch
     * Trigger search request.
     */
    triggerSearch: function() {
        var action = new GeoExt.form.SearchAction(this.form);
        this.form.doAction(action);
    }
};
