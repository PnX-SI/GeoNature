Ext.namespace('mapfish.ux', 'mapfish.ux.Searcher', 'mapfish.ux.Searcher.Form');

/**
 * Class: mapfish.Searcher.Form
 * Use this class to create a form searcher. A form searcher
 * gets search criteria from an Ext.FormPanel form and sends search
 * requests through Ajax.
 *
 * Inherits from:
 * - mapfish.Searcher.Form
 */
mapfish.ux.Searcher.Form.Ext = OpenLayers.Class(mapfish.Searcher.Form, {

    /**
     * APIProperty: form
     * {Ext.form.BasicForm} The Ext form ie. Ext.FormPanel.getForm()
     */
    form: null,

    /**
     * Method: getFilter
     *      Get the search filter.
     *
     * Returns:
     * {Object} The filter.
     */
    getFilter: function() {
        return this.form.getValues();
    }
    
});
