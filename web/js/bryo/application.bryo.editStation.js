/**
 * @class application.editAp
 * Singleton to build the editAp window
 *
 * @singleton
 */

application.editStation = function() {
    // private variables

    /**
     * Property: map
     * {OpenLayers.Map}
     */
    map = null;

    /**
     * Property: toolbar
     * {mapfish.widgets.ToolBar}
     */
    var toolbar = null;

    /**
     * Property: toolbarInitializedOnce
     * {Boolean} toolbar has already been initialized
     */
    var toolbarInitializedOnce = false;

    /**
     * Property: vectorLayer
     * {OpenLayers.Layer.Vector}
     */
    vectorLayer = null;

    /**
     * Property: dragPanControl
     */
    var dragPanControl = null;

    /**
     * Property: dragPolygonControl
     */
    var dragPolygonControl = null;

    /**
     * Property: store
     * {Ext.data.Store} The ap store (should contain only one record)
     */
    var store = null;

    /**
     * Property: protocol
     * {mapfish.Protocol.MapFish}
     */
    var protocol = null

    /**
     * Property: eventProtocol
     * {mapfish.Protocol.TriggerEventDecorator}
     */
    var eventProtocol = null;

    /**
     * Property: filterProtocol
     * {mapfish.Protocol.MergeFilterDecorator}
     */
    var filterProtocol = null;

    /**
     * Property: format
     * {<OpenLayers.Format.WKT>}
     */
    var format = new OpenLayers.Format.WKT();

    /**
     * APIProperty: id_station
     * The id of station to update (if applies), null in case of a creating a new station
     */
    var id_station = null;
    
    /**
     * APIProperty: old_cd_nom
     * The old cd_nom of the taxon to update
     */
    var old_taxon = null;

    /**
     * Property: layerTreeTip
     * {Ext.Tip} The layerTreeTip created with the factory
     */
    var layerTreeTip = null;

    /**
     * Property: firstGeometryLoad
     * {Boolean} is the geometry has been load once only
     */
    var firstGeometryLoad = true;
    
    /**
     * Property: maProjection
     * {Openlayers.Projection} définie ici sinon temps de retard lors de la création du point gps ???
     */
    var maProjection = null;
    
    // private functions

    /**
     * Method: initViewport
     */
    var initWindow = function() {
        return new Ext.Window({
            title: "Modifier une station"
            ,layout: 'border'
            ,modal: true
            ,plain: true
            ,plugins: [new Ext.ux.plugins.ProportionalWindows()]
            //,aspect: true
            ,width: 600
            ,height: 350
            ,percentage: .95
            ,split: true
            ,closeAction: 'hide'
            ,defaults: {
                border: false
            }
            ,items: [
                getWindowCenterItem()
                ,getViewportEastItem()
            ]
            ,listeners: {
                show: initToolbarItems
                ,hide:function(){           
                    if(Ext.getCmp('station_count').setText("les 50 dernières stations")){
                        Ext.getCmp('hidden-start').setValue('yes')
                    }
                    application.search.refreshStations();
                    this.destroy();
                }
                ,afterlayout: function(){
                  map.baseLayer.redraw();
                }
            }
        });
    };

    /**
     * Method: getViewportNorthItem
     */
    var getViewportEastItem = function() {
        return {
            region: 'east'
            ,width: 500
            ,split: true
            ,autoScroll: true
            ,defaults: {
                border: false
            }
            ,items: [{
                id: 'edit-station-form'
                ,xtype: 'form'
                ,bodyStyle: 'padding: 5px'
                ,disabled: true
                ,defaults: {
                    xtype: 'numberfield'
                    ,labelWidth: 90
                    ,width: 180
                    ,anchor:'-15'
                }
                ,labelAlign: 'left'
                ,monitorValid:true
                ,items: [getFormItems(),getFormTaxons()]
                ,buttons:[{
                    text: 'Annuler'
                    ,xtype: 'button'
                    ,handler: function() {
                        application.editStation.window.hide();
                    }
                    ,scope: this
                },{
                    text: 'Enregistrer'
                    ,xtype: 'button'
                    ,id: 'stationSaveButton'
                    ,iconCls: 'action-save'
                    ,handler:submitForm
                }]
            }]
        }
    };

    /**
     * Method: getViewportCenterItem
     */
    var getWindowCenterItem = function() {
        createMap();
        toolbar = new mapfish.widgets.toolbar.Toolbar({
            map: map,
            configurable: false
        });

        return {
            region: 'center'
            ,id: 'edit-station-mapcomponent'
            ,xtype: 'mapcomponent'
            ,map: map
            ,tbar: toolbar
        };
    };

    /**
     * Method: getFormItems
     * Creates the form items
     */
    var getFormItems = function() { 
        var comboObservateurs = new Ext.ux.form.SuperBoxSelect({
            id:'combo-station-observateurs'
            ,xtype:'superboxselect'
            ,fieldLabel: 'Observateur(s) ' 
            ,name: 'lesobservateurs'
            ,store: application.auteurStore
            ,displayField: 'auteur'
            ,valueField: 'id_role'
            ,allowBlank: false
            ,resizable: true
            ,forceSelection : true
            ,selectOnFocus:true
            ,resizable: true
            ,mode: 'local'
            ,value:''
            ,listeners:{
                afterrender :function(){
                    Ext.getCmp('edit-station-form').getForm().findField('ids_observateurs').setValue(this.getValue());
                }
                ,change:function(){
                    Ext.getCmp('edit-station-form').getForm().findField('ids_observateurs').setValue(this.getValue());
                }
                ,render: function(c) {
                    Ext.QuickTips.register({
                        target: c.getEl(),
                        text: 'Le ou les auteurs du relevé de la station.'
                    });
                }
            }
        });
        return [{
            id:'hidden-idstation'
            ,xtype:'hidden'
            ,name: 'id_station'   
        },{
            xtype:'hidden'
            ,name: 'monaction'
        },{
            xtype: 'hidden'
            ,name: 'geometry' 
        },{
            xtype:'hidden'
            ,name: 'ids_observateurs'
        },{
            id: 'labelstation-station'
            ,xtype:'label'
            ,html: ''
        },{
        // Fieldset 
        xtype:'fieldset'
        ,id:'fieldset-1-station'
        ,columnWidth: 1
        ,title: 'Etape 1'
        ,collapsible: true
        ,autoHeight:true
        ,anchor:'98%'
        //,defaults: {anchor: '-20' // leave room for error icon}
        // ,defaultType: 'textfield'
        ,items :[comboObservateurs
            ,{
                id:'datefield-station-date'
                ,fieldLabel: 'Date '
                ,name: 'dateobs'
                ,xtype:'datefield'
                ,maxValue: 'today'
                ,format: 'd/m/Y'
                ,altFormats:'Y-m-d'
                ,allowBlank: false
                ,blankText:'La date du relevé est obligatoire'
                ,listeners: {
                    render: function(c) {
                        Ext.QuickTips.register({
                            target: c.getEl(),
                            text: 'Date de réalisation du relevé. Elle ne peut donc être postérieure à la date de saisie.'
                        });
                    }
                }
            },{
                id:'textfield-station-acces'
                ,xtype: 'textarea'
                ,fieldLabel: 'Accès '
                ,name: 'info_acces'
                ,anchor:'90%'
                // ,width:250
                ,listeners: {
                    render: function(c) {
                        Ext.QuickTips.register({
                            target: c.getEl(),
                            text: 'Information facultative concernant la façon d\'accéder à la station relevée.'
                        });
                    }
                }
            },{
                id:'combo-station-support'
                ,xtype:"twintriggercombo"
                ,fieldLabel: 'Pointage sur '
                ,name: 'support'
                ,hiddenName:"id_support"
                ,store: application.supportStore
                ,valueField: "id_support"
                ,displayField: "nom_support"
                ,allowBlank:false
                ,blankText:'Le support de pointage doit être renseigné'
                ,typeAhead: true
                ,forceSelection: true
                ,selectOnFocus: true
                ,editable: true
                ,triggerAction: 'all'
                ,trigger3Class: 'x-form-zoomto-trigger x-hidden'
                ,mode: 'local'
            },{
                id:'textfield-station-pdop'
                ,xtype: 'numberfield'
                ,allowDecimals :true
                ,allowNegative: false
                ,decimalSeparator:'.'
                ,decimalPrecision:1
                ,nanText:'Ceci n\'est pas un nombre valide.'
                ,fieldLabel: 'Pdop '
                ,name: 'pdop'
                ,anchor:'40%'
                ,listeners: {
                    render: function(c) {
                        Ext.QuickTips.register({
                            target: c.getEl(),
                            text: 'Information facultative concernant le pdop du GPS s\'il a été utilisé.'
                        });
                    }
                }
            },{
                id:'numberfield-surface'
                ,xtype: 'numberfield'
                ,fieldLabel: 'Surface '
                ,name: 'surface'
                ,allowBlank:false
                ,blankText:'La surface est obligatoire'
                ,anchor:'40%'
                ,listeners: {
                    render: function(c) {
                        Ext.QuickTips.register({
                            target: c.getEl(),
                            text: 'Information relative à la surface de la station ; en m².'
                        });
                    }
                }
            },{
                id:'combo-station-exposition'
                ,xtype:"twintriggercombo"
                ,fieldLabel: 'Exposition '
                ,name: 'exposition'
                ,hiddenName:"id_exposition"
                ,store: application.expositionStore
                ,valueField: "id_exposition"
                ,displayField: "nom_exposition"
                ,allowBlank:false
                ,blankText:'L\'exposition doit être renseignée'
                ,typeAhead: true
                ,forceSelection: true
                ,selectOnFocus: true
                ,editable: true
                ,triggerAction: 'all'
                ,trigger3Class: 'x-form-zoomto-trigger x-hidden'
                ,mode: 'local'
            }]
        } //fin du groupe 1
        ,{ //groupe 2
            xtype:'fieldset'
            ,id:'fieldset-2-station'
            ,columnWidth: 1
            ,title: 'Etape 2'
            ,collapsible: true
            ,autoHeight:true
            ,anchor:'98%'
            //,defaults: {anchor: '-20' // leave room for error icon}
            // ,defaultType: 'textfield'
            ,items :[{
                xtype: 'radiogroup'
                ,fieldLabel: 'Relevé '
                ,anchor    : '90%'
                ,items: [
                    {boxLabel: 'Complet', name: 'releve', inputValue: 'C', checked: true}
                    ,{boxLabel: 'Partiel', name: 'releve', inputValue: 'P'}
                ]
                ,listeners:{
                    render: function(c) {
                        Ext.QuickTips.register({
                            target: c.getEl(),
                            text: 'Précisez si ce relevé est complet ou non.'
                        });
                    } 
                }
            }]
        }  //fin du groupe 2
        ,{ //groupe 3
            xtype:'fieldset'
            ,id:'fieldset-3-station'
            ,columnWidth: 1
            ,title: 'Etape 3'
            ,collapsible: true
            ,autoHeight:true
            ,anchor:'98%'
            ,defaults: {anchor: '-20'} // leave room for error icon
            ,defaultType: 'numberfield'
            ,items :[{
                id:'ta-station-remarques'
                ,xtype: 'textarea'
                ,fieldLabel: 'Remarques '
                ,name: 'remarques'
                ,grow:true
                ,autoHeight: true
                ,height:'auto'
                ,anchor:'95%'
                ,listeners: {
                    render: function(c) {
                        Ext.QuickTips.register({
                            target: c.getEl(),
                            text: 'Mettre en remarque tout ce qui semble utile et qui n\'est pas prévu dans la fiche.'
                        });
                    }
                }
            }]
        }//fin du groupe 3
        ] //fin du return
    };
    var myProxy = new Ext.data.HttpProxy({
        id:'store-taxon-proxy'
        ,url: 'bryo/getonerelevetaxons?id_station='+id_station
        ,method: 'GET'
    });
    var gridStoreTaxonsLoad = function(id_station) {
        myProxy.api.read.url = 'bryo/getonerelevetaxons?id_station='+id_station;
        gridStoreTaxons.reload();
    };
    var getFormTaxons = function(){
        var taxon = Ext.data.Record.create([
            {name: 'id_station',type: 'integer'}   
            ,{name: 'cd_nom',type: 'integer'}
            ,{name: 'nom_complet',type: 'string'}
            ,{name: 'id_abondance',type: 'string'}
        ]);
        var editor = new Ext.ux.grid.RowEditor({
            saveText: 'Enregistrer'
        });
        
        gridStoreTaxons = new Ext.data.JsonStore({
            // url: 'bryo/getonerelevetaxons'
            proxy: myProxy
            ,fields: [
                {name:'id_station'}
                ,{name:'cd_nom'}
                ,{name:'nom_complet'}
                ,{name:'id_abondance'}
                ,{name:'taxon_saisi'}
            ]
            ,sortInfo: {
                field: 'nom_complet'
                ,direction: 'ASC'
            }
        });

        var taxonsEditGrid = new Ext.grid.GridPanel({
            id:'grid-edit-taxon'
            ,store: gridStoreTaxons
            ,width: 580
            ,region:'center'
            ,margins: '0 5 5 5'
            ,autoExpandColumn: 'col-cd_nom'
            ,plugins: [editor]
            ,view: new Ext.grid.GridView({
                markDirty: false
            })
            ,tbar: [{
                iconCls: 'add'
                ,text: 'Nouveau taxon'
                ,handler: function(){
                    newTaxon();
                }
            },{
                ref: '../removeBtn'
                ,iconCls: 'action-remove'
                ,text: 'Supprimer ce taxon'
                ,disabled: true
                ,handler: function(){
                    editor.stopEditing();
                    var s = taxonsEditGrid.getSelectionModel().getSelections();
                    for(var i = 0,r; r = s[i]; i++){
                        var moncdnom = r.data.cd_nom;    
                        var maligne = r;//décidemment je n'y comprend rien en porté de variable en javascript    
                        Ext.Msg.confirm('Attention'
                                ,'Etes-vous certain de vouloir supprimer le taxon '+r.data.taxon_saisi +' ?'
                                ,function(btn) {
                                    if (btn == 'yes') {
                                        Ext.Ajax.request({
                                            url: 'bryo/deletetaxon'
                                            ,method: 'POST'
                                            ,params: {
                                                cd_nom: moncdnom
                                                ,id_station: Ext.getCmp('edit-station-form').getForm().findField('id_station').getValue()
                                            }
                                            ,success: function(request) {
                                                var result = Ext.decode(request.responseText);
                                                if (result.success) {
                                                    Ext.ux.Toast.msg('Ok !', 'Le taxon à été supprimé.');
                                                    var index = 'station-' + Ext.getCmp('edit-station-form').getForm().findField('id_station').getValue();
                                                    var tab = application.layout.tabPanel.getComponent(index);
                                                    if(tab){
                                                        tab.refreshTaxons();
                                                        tab.refreshStation();
                                                    }
                                                    gridStoreTaxons.remove(maligne);
                                                } else {
                                                    OpenLayers.Console.error("une erreur s'est produite !");
                                                }
                                            }
                                            ,failure: application.checklog
                                            // ,scope: this
                                        });
                                    }
                                }
                            );
                            
                    }
                }
            }]
            ,columns: [
            // new Ext.grid.RowNumberer()
            {
                header: 'Taxon saisi'
                ,dataIndex: 'taxon_saisi'
                ,width: 50
                ,sortable: true
                ,hidden:true
                ,editor: {
                    id:'editor-taxonsaisi'
                    ,xtype: 'textfield'
                }
            },{
                id: 'col-cd_nom'
                ,header: 'Taxon'
                ,dataIndex: 'cd_nom'
                ,width: 150
                ,sortable: true
                ,editor: {
                    id:'combo-taxons'
                    ,name: 'cd_nom'
                    ,xtype:"twintriggercombo"
                    ,hiddenName:"cd_nom"
                    ,store: application.filtreTaxonsReferenceStore
                    ,valueField: "cd_nom"
                    ,displayField: "nom_complet"
                    ,storeField: ['cd_nom', 'nom_complet']
                    // ,allowBlank: false
                    // ,blankText:'Vous devez fournir un taxon <br>et sa fréquence dans au moins une strate'
                    ,typeAhead: true
                    ,typeAheadDelay:750
                    ,forceSelection: true
                    ,selectOnFocus: true
                    ,editable: true
                    ,resizable : true
                    ,triggerAction: 'all'
                    ,trigger3Class: 'x-form-zoomto-trigger x-hidden'
                    ,mode: 'local'
                    ,listeners: {
                        select: function(combo,record,index) {
                            var s = Ext.getCmp('grid-edit-taxon').getSelectionModel().getSelections();
                            rec = s[0];
                            //on vérifie que le taxon choisi n'est pas déjà dans la liste
                            var compt = 0;
                            var val = combo.getValue();
                            gridStoreTaxons.each(function(r){
                                if(r.data.cd_nom==val){compt ++;}
                            });
                            if (compt>=1){
                                Ext.Msg.show({
                                    title: 'Attention'
                                    ,buttons: Ext.Msg.OK,icon: Ext.MessageBox.ERROR
                                    ,msg:'Attention ! Ce taxon existe déjà dans la liste.'
                                    ,fn: function(){
                                        // combo.setValue(combo.originalValue);
                                        Ext.getCmp('grid-edit-taxon').plugins[0].stopEditing(false);
                                    }
                                });
                            }
                            else{
                                rec.data.taxon_saisi = combo.getRawValue();
                                Ext.getCmp('editor-taxonsaisi').setValue(combo.getRawValue());
                                rec.commit();
                            }                    
                        }
                        ,beforeedit:function(grid,record,field,value,row,column) {
                            // application.utils.getRecordDisplayFieldValue(grid, 1, value, 'cd_nom', 'nom_complet');
                        }
                        ,afterrender: function(combo){
                            combo.keyNav.tab = function() { // Override TAB handling function
                                this.onViewClick(false); // Select the currently highlighted row
                            };
                        }
                    }
                }
                ,renderer:function(value, metaData, record, rowIndex, colIndex) { return application.utils.getRecordDisplayFieldValue(taxonsEditGrid, colIndex, value, 'cd_nom', 'nom_complet'); }
            },{
                header: 'Abondance'
                ,dataIndex: 'id_abondance'
                ,width: 50
                ,sortable: true
                ,editor: {
                    xtype: 'textfield'
                }
            }]
        });

        // store.on('add', cstore.refreshData, cstore);
        // store.on('remove', cstore.refreshData, cstore);
        // store.on('update', cstore.refreshData, cstore);

        var taxonsPanel = new Ext.Panel({
            id:'taxons-liste-panel'
            ,title: 'Liste des taxons'
            ,layout: 'border'
            ,layoutConfig: {
                columns: 1
            }
            ,width: 580
            ,height: 500
            ,items: [taxonsEditGrid]
        });
        
         /**
         * Method: newTaxon
         * add a taxon record into the editorGrid
         */
        var newTaxon = function(){
            var t = new taxon({
                id_station: id_station
            });
            editor.stopEditing();
            gridStoreTaxons.insert(0, t);
            // taxonsEditGrid.getView().refresh();
            taxonsEditGrid.getSelectionModel().selectRow(0);
            editor.startEditing(0);
            Ext.getCmp('edit-station-form').getForm().findField('monaction').setValue('update');
        }
        
        /**
         * Method: submitTaxon
         * Submits the taxon record to CorFsTaxon
         */
        var submitTaxon = function(id_station,new_cd_nom,old_cd_nom,id_abondance,taxon_saisi) {
            Ext.getCmp('taxons-liste-panel').setTitle('Liste des taxons (Enregistrement en cours...)');
            if (id_station) {
                var params = {};
                params.id_station = id_station;
                params.new_cd_nom = new_cd_nom;
                params.old_cd_nom = old_cd_nom;
                params.id_abondance = id_abondance;
                params.taxon_saisi = taxon_saisi;
            
                Ext.Ajax.request({
                    url: 'bryo/savetaxon'
                    ,params: params
                    ,success: function(result, request) {
                        Ext.getCmp('taxons-liste-panel').setTitle('Liste des taxons');
                        Ext.ux.Toast.msg('Ok !', 'La liste des taxons a été mise à jour.');
                        var index = 'station-' + Ext.getCmp('edit-station-form').getForm().findField('id_station').getValue();
                        var tab = application.layout.tabPanel.getComponent(index);
                        if(tab){
                            tab.refreshTaxons();
                            tab.refreshStation();
                        }
                    }
                    ,failure: function(result, request) {
                        Ext.getCmp('taxons-liste-panel').setTitle('Liste des taxons');
                        Ext.Msg.show({
                          title: 'Erreur'
                          ,msg: 'L\'enregistrement n\'a pas été réalisé'
                          ,buttons: Ext.Msg.OK
                          ,icon: Ext.MessageBox.ERROR
                        });
                    }
                    
                });
            }
            else{
            Ext.Msg.show({
                  title: 'Attention'
                  ,msg: 'Vous devez d\'abord enregistrer la station et obtenir un N° de station - L\'enregistrement n\'a pas été réalisé'
                  ,buttons: Ext.Msg.OK
                  ,icon: Ext.MessageBox.ERROR
                });
            }
        };
        
        taxonsEditGrid.getSelectionModel().on('selectionchange', function(sm){
            taxonsEditGrid.removeBtn.setDisabled(sm.getCount() < 1);
        });
        //definir le cd_nom d'origine pour retrouver dans la base la double clé id_bryo/cd_nom
        editor.on('beforeedit', function(grid, rowIndex){
            var s = taxonsEditGrid.getSelectionModel().getSelections();
                r = s[0].data;
                old_cd_nom = r.cd_nom;
        });
        editor.on('canceledit', function(grid){
            var s = taxonsEditGrid.getSelectionModel().getSelections();
            var r = s[0];
            if(!r.data.cd_nom > 0){gridStoreTaxons.remove(r);}
        });

        //action sur le bouton "Enregistrer" ligne par ligne
        editor.on('afteredit', function(grid, object, record, rowIndex){
            var r = record.data;
            monidstation = Ext.getCmp('edit-station-form').getForm().findField('id_station').getValue();
            // On vérifie qu'un taxon est saisi
            if(!r.cd_nom>0){
                Ext.Msg.show({
                    title: 'Attention'
                    ,buttons: Ext.Msg.OK,icon: Ext.MessageBox.ERROR
                    ,msg:'Attention ! Vous n\'avez pas choisi de taxon.'
                    ,fn: function(){
                        var s = taxonsEditGrid.getSelectionModel().getSelections();
                        var r = s[0];
                        gridStoreTaxons.remove(r);
                        newTaxon();
                    }
                });
            }
            else{
            
                // else{
                //validation pour savoir si on une valeur dans abondance
                var machaine = r.id_abondance;
                if(machaine.length>0){submitTaxon(monidstation,r.cd_nom, old_cd_nom, r.id_abondance,r.taxon_saisi);}
                else{
                    Ext.Msg.show({
                        title: 'Attention'
                        ,buttons: Ext.Msg.OK,icon: Ext.MessageBox.ERROR
                        ,msg:'Attention ! Fournissez une valeur pour l\'abondance.'
                        ,fn: function(){
                            Ext.getCmp('grid-edit-taxon').getSelectionModel().selectRow(rowIndex);
                            Ext.getCmp('grid-edit-taxon').plugins[0].startEditing(rowIndex,1);
                        }
                    });
                }
                // }
            }
        });
        //ajout d'un taxon avec la touche 'n' ou la barre d'espace
        Ext.getCmp('grid-edit-taxon').on('keydown', function (el) {
            if(el.keyCode == 78 || el.keyCode == 32) {
                el.preventDefault();
                newTaxon();
            }
        });
        return taxonsPanel;
    };
    
    /**
     * Method: createLayer
     * Creates the vector layer
     *
     * Return
     * <OpenLayers.Layer.Vector>
     */
    var createLayer = function() {
        var styleMap = new OpenLayers.StyleMap({
            'default': {
                fillColor: "red"
                ,strokeColor: "#ff6666"
                ,cursor: "pointer"
                ,fillOpacity: 0.7
                ,strokeOpacity: 1
                ,strokeWidth: 2
                ,pointRadius: 7
            }
            ,select : {
                fillColor: "blue"
                ,strokeColor: "blue"
                ,cursor: "pointer"
                ,fillOpacity: 0.5
                ,strokeOpacity: 1
                ,strokeWidth: 3
                ,pointRadius: 8
            }
        });
        vectorLayer = new OpenLayers.Layer.Vector("editStation vector layer"
            ,{
                protocol: eventProtocol
                ,strategies: [
                    new mapfish.Strategy.ProtocolListener()
                ]
                ,styleMap: styleMap
                ,format: OpenLayers.Format.GeoJSON
            }
        );
        vectorLayer.events.on({
            featureadded: function(obj) {
                var feature = obj.feature;
                // don't allow BD or massif geometry editing
                if (this.id_station==null) {
                    activateControls(false);
                } else {
                    deactivateAllEditingControls();
                }
                updateGeometryField(feature);
                Ext.getCmp('edit-station-form').enable();
                Ext.getCmp('edit-station-form').ownerCt.ownerCt.doLayout();
            }
            ,featuremodified: function(obj) {
                updateGeometryField(obj.feature);
            }
            ,featureremoved: function(obj) {
                updateGeometryField(null);
                Ext.getCmp('edit-station-form').disable();
            }
        });
    };

    /**
     * Method: createMap
     * Creates the map
     *
     * Return
     * <OpenLayers.Map>
     */
    var createMap = function() {
        map = application.createMap();
        map.getLayersByName('overlay')[0].mergeNewParams({
          id_station:id_station
        });
        createLayer();
        map.addLayers([vectorLayer]);
        map.zoomToMaxExtent();
        maProjection = map.getProjectionObject();
    };

    /**
     * Method: initToolbarItems
     * Creates the map toolbar
     */
    var initToolbarItems = function() {
        if (!toolbarInitializedOnce) {
            toolbar.addControl(
                new OpenLayers.Control.ZoomToMaxExtent({
                    map: map,
                    title: 'Revenir à l\'échelle maximale'
                }), {
                    iconCls: 'zoomfull',
                    toggleGroup: this.id
                }
            );

            application.utils.addSeparator(toolbar);

            toolbar.addControl(
                new OpenLayers.Control.ZoomBox({
                    title: 'Zoomer'
                }), {
                    iconCls: 'zoomin',
                    toggleGroup: this.id
                }
            );

            toolbar.addControl(
                new OpenLayers.Control.ZoomBox({
                    out: true,
                    title: 'Dézoomer'
                }), {
                    iconCls: 'zoomout',
                    toggleGroup: this.id
                }
            );

            toolbar.addControl(
                dragPanControl = new OpenLayers.Control.DragPan({
                    isDefault: true,
                    title: 'Déplacer la carte'
                }), {
                    iconCls: 'pan',
                    toggleGroup: this.id
                }
            );

            application.utils.addSeparator(toolbar);

            toolbar.addControl(
                drawPointControl = new OpenLayers.Control.DrawFeature(vectorLayer, OpenLayers.Handler.Point, {
                    title: 'Dessiner un point'
                }), {
                    iconCls: 'drawpoint'
                    ,toggleGroup: this.id
                    ,disabled: true
                }
            );
            
            toolbar.add({
                text: 'GPS'
                ,id: 'edit-station-gps'
                ,tooltip: 'Pour positionner un point sur la carte à partir de coordonnées GPS en UTM'
                ,handler: function() {
                    vectorLayer.removeFeatures(vectorLayer.features[0]);
                    application.editStation.initGpsWindow()
                }
            });
            
            toolbar.addControl(
                dragPolygonControl = new OpenLayers.Control.DragFeature(vectorLayer, {
                    title: 'Déplacer la station'
                    ,onComplete:function(feature) {
                        updateGeometryField(feature);
                    }
                }), {
                    iconCls: 'dragpolygon'
                    ,toggleGroup: this.id
                    ,disabled: true
                }
            );

            application.utils.addSeparator(toolbar);

            toolbar.add({
                text: 'Effacer la géométrie'
                ,id: 'edit-station-geometry-erase'
                //,disabled: true
                ,iconCls: 'erase'
                ,tooltip: 'Permet de supprimer la géométrie pour en créer une nouvelle'
                ,handler: function() {
                    Ext.Msg.confirm('Attention'
                        ,'Cela supprimera définitivement la géométrie existante !<br />Confirmer ?'
                        ,function(btn) {
                            if (btn == 'yes') {
                                activateControls(true);
                                vectorLayer.removeFeatures(vectorLayer.features[0]);
                            }
                        }
                    )
                }
            });

            layerTreeTip = application.createLayerWindow(map);
            layerTreeTip.render(Ext.getCmp('edit-station-mapcomponent').body);
            layerTreeTip.show();
            layerTreeTip.getEl().alignTo(
                Ext.getCmp('edit-station-mapcomponent').body,
                "tl-tl",
                [5, 5]
            );
            layerTreeTip.hide();

            application.utils.addSeparator(toolbar);

            toolbar.add({
                iconCls: 'legend'
                ,enableToggle: true
                ,tooltip: 'Gérer les couches affichées'
                ,handler: function(button) {
                    showLayerTreeTip(button.pressed);
                }
            });
            toolbar.activate();
            // toolbarInitializedOnce = true;
        }
    };

    /**
     * Method: activateControls
     * Allows to activate / enable / deactivate / disable the draw and modify feature controls
     *
     * Parameters:
     * activateDrawControls - {Boolean} true to activate / enable the draw controls
     */
    var activateControls = function(activateDrawControls) {
        Ext.getCmp('edit-station-geometry-erase').setDisabled(false);
        toolbar.getButtonForControl(dragPolygonControl).setDisabled(activateDrawControls);
        if (activateDrawControls) {
            dragPolygonControl.deactivate();
        } else {
            dragPolygonControl.activate();
        }
        Ext.each([drawPointControl]
            ,function(control) {
                toolbar.getButtonForControl(control).setDisabled(!activateDrawControls);
                if (!activateDrawControls) {
                    control.deactivate();
                }
            }
        );
    };

    /**
     * Method: deactivateAllEditingControls
     */
    var deactivateAllEditingControls = function() {
        Ext.getCmp('edit-station-geometry-erase').setDisabled(true);
        toolbar.getButtonForControl(dragPolygonControl).setDisabled(true);
        dragPolygonControl.deactivate();
        toolbar.getButtonForControl(drawPointControl).setDisabled(true);
        drawPointControl.deactivate();
    };

    /**
     * Method: updateGeometryField
     * Updates the geometry field (hidden) in the form
     *
     * Parameters:
     * geometry - {null|<OpenLayers.Geometry>} Geometry
     */
    var updateGeometryField = function(geometry) {
        if (geometry == null) {wkt = '';}
        else {var wkt = format.write(geometry);}
        Ext.getCmp('edit-station-form').getForm().findField('geometry').setValue(wkt);
        firstGeometryLoad = false;
    };
    
    /**
     * Method: createProtocol
     * Create the search protocol.
     */
    var createProtocol = function() {
        protocol = new mapfish.Protocol.MapFish({});
        eventProtocol = new mapfish.Protocol.TriggerEventDecorator({
            protocol: protocol
            ,eventListeners: {
                crudtriggered: function() {
                    //apsListGrid.loadMask.show();
                }
                ,crudfinished: function(response) {
                    var feature = response.features[0];
                    //mise à jour des label du formulaire
                    Ext.getCmp('labelstation-station').setText('<p class="bluetext">Station N° '+feature.data.id_station+' du '+feature.data.dateobs+' ('+feature.data.commune+')</p>',false);
                    //chargement des valeurs du formulaire
                    Ext.getCmp('edit-station-form').getForm().loadRecord(feature);
                    //on centre en limitant le zoom à 7
                    var centerGeom = feature.geometry.getBounds().getCenterLonLat();
                    map.setCenter(centerGeom,7);
                    Ext.getCmp('edit-station-form').enable();
                }
            }
        });
    };

    /**
     * Method: createStore
     * Create the search result store.
     */
    var createStore = function() {
        store = new Ext.data.Store({
            reader: new mapfish.widgets.data.FeatureReader({}, [
                'id_station'
                ,'ids_observateurs'
                ,{name:'dateobs', type: 'date', dateFormat:'d/m/Y'}
                ,'complet_partiel'
                ,'id_support'
                ,'pdop'
                ,'id_exposition'
                ,'surface'
                ,'info_acces'
                ,'commune'
                ,'litiere'
                ,'remarques'
            ])
            ,listeners: {
                load: function(store, records) {
                    Ext.getCmp('edit-station-form').getForm().loadRecord(records[0]);
                }
            }
        });
    };

    /**
     * Method: resetWindow
     * Reset the different items status (on close) for next usage
     */
    var resetWindow = function() {
        Ext.getCmp('grid-edit-taxon').plugins[0].stopEditing(true);
        id_station = null;
        map.zoomToMaxExtent();
        vectorLayer.removeFeatures(vectorLayer.features);
        Ext.getCmp('edit-station-form').disable();
        Ext.getCmp('edit-station-form').getForm().reset();
        dragPanControl.activate();
        if(Ext.getCmp('station_count').setText("les 50 dernières stations")){
            Ext.getCmp('hidden-start').setValue('yes')
            application.search.refreshStations();
        }
    };

    /**
     * Method: submitForm
     * Submits the form
     */
    var submitForm = function() {
        Ext.getCmp('stationSaveButton').setText('Enregistrement en cours...');
        var params = {};
        if (id_station) {
            params.id_station = id_station;
        }
        Ext.getCmp('edit-station-form').getForm().submit({
            url: 'bryo/save'
            ,params: params
            ,success: function(form,action) {
                Ext.getCmp('stationSaveButton').setText('Enregistrer');
                if (id_station) {
                    var index = 'station-' + Ext.getCmp('edit-station-form').getForm().findField('id_station').getValue();
                    var tab = application.layout.tabPanel.getComponent(index);
                    if(tab){
                        tab.refreshTaxons();
                        tab.refreshStation();
                    }
                    application.editStation.window.hide();
                }
                else{
                    var madateobs = new Date();
                    madateobs = Ext.getCmp('edit-station-form').getForm().findField('dateobs').getValue();
                    madateobs.format("d/m/Y");
                    Ext.getCmp('edit-station-form').getForm().findField('id_station').setValue(action.result.id_station);
                    Ext.getCmp('labelstation-station').setText('<p class="bluetext">Station N° '+action.result.id_station+' du '+madateobs+' ('+action.result.commune+')</p>',false);
                    Ext.getCmp('edit-station-form').getForm().findField('monaction').setValue('update');
                    Ext.getCmp('taxons-liste-panel').show();
                } 
            }
            ,failure: function(form, action) {
                Ext.getCmp('stationSaveButton').setText('Enregistrer');
                var msg;
                switch (action.failureType) {
                      case Ext.form.Action.CLIENT_INVALID:
                          msg = "Les informations saisies sont invalides ou incomplètes. Vérifiez le formulaire (voir champs en rouge).";
                          break;
                      case Ext.form.Action.CONNECT_FAILURE:
                          msg = "Problème de connexion au serveur";
                          break;
                      case Ext.form.Action.SERVER_INVALID:
                          msg = "Erreur lors de l'enregistrement : vérifier les données saisies !";
                          break;
                }
                Ext.Msg.show({
                  title: 'Erreur'
                  ,msg: msg
                  ,buttons: Ext.Msg.OK
                  ,icon: Ext.MessageBox.ERROR
                });
            }
        });
    };

    /**
     * Method: showLayerTreeTip
     * Shows or hide the layer tree tip
     */
    var showLayerTreeTip = function(show) {
        layerTreeTip.setVisible(show);
    };
    
//----------------------------------fenêtre pour le positionnement par gsp----------------------------------
    var submitFormGps = function(zone, longitude, latitude,maProjection,proj31,proj32) {
        if(Ext.getCmp('form-gps-station').getForm().isValid()){
            // création du point et reprojection grace à proj4js;
            //j'ai du télécharger et ajouter le répertoire de la lib pro4js dans js/openlayers/firebug/proj4js
            //puis créer EPSG32632.js,EPSG32631.js,EPSG27572.js (+EPSG2154.js pour le lambert 93 plus tard)
            //Les 3 projections nécessaires pour le transform sont définies au moment de la création de la fenêtre GSP sinon il y a un pb de timeout et la reprojection n'a pas le temps de se faire ???
            var features = [];
            if(zone==31||zone==32){
                if(zone==32){var projSource = proj32;}
                if(zone==31){var projSource = proj31;}
            }
            else{Ext.Msg.alert('Attention', 'Zone 31 ou 32 uniquement'); return false;}
            // if(zone==32){var projSource = new OpenLayers.Projection("EPSG:32632");}
            // if(zone==31){var projSource = new OpenLayers.Projection("EPSG:32631");}
            // var maProjection = map.getProjectionObject();
            // var maProjection = new OpenLayers.Projection('EPSG:27572');

            // alert ('le temps d\'initialisation des projections ou de proj4 ???');
            var mageometry = new OpenLayers.Geometry.Point(longitude, latitude);
            OpenLayers.Projection.transform(mageometry,projSource,maProjection);
            var mafeature = new OpenLayers.Feature.Vector(mageometry);
            features.push(mafeature);
            malayer = vectorLayer; //débugage (voir vite fait la couche et ses features dans le DOM)
            vectorLayer.addFeatures(features);
            vectorLayer.redraw();
            map.setCenter(new OpenLayers.LonLat(mageometry.x, mageometry.y),6);
            // alert('Longitude : ' + mageometry.x +' - Latitude : '+ mageometry.y);
            Ext.getCmp('window-gqs').destroy();
            Ext.getCmp('combo-station-support').setValue(3);
        }
        else{
            Ext.Msg.alert('Attention', 'Une information est mal saisie ou n\'est pas valide.</br>Vous devez la corriger avant de poursuivre.');
        }
    };
    
    var initGpsWindow = function() {
        var maProjection = map.getProjectionObject();
        var proj32 = new OpenLayers.Projection("EPSG:32632");
        var proj31 = new OpenLayers.Projection("EPSG:32631");
        
        return new Ext.Window({
            id:'window-gqs'
            ,layout:'border'
            ,height:250
            ,width: 400
            ,closeAction:'destroy'
            ,autoScroll:true
            ,modal: true
            ,plain: true
            ,split: true
            ,buttons: [{
                text:'Afficher'
                ,id:'gps-afficher-button'
                ,handler: function(){
                    var zone, longitude, latitude;
                    zone = Ext.getCmp('gps-station-zone').getValue();
                    longitude = Ext.getCmp('gps-station-longitude').getValue();
                    latitude = Ext.getCmp('gps-station-latitude').getValue();
                    submitFormGps(zone, longitude, latitude, maProjection, proj31, proj32);   
                }
            },{
                text: 'Annuler et fermer'
                ,handler: function(){
                    Ext.getCmp('window-gqs').destroy();
                    Ext.ux.Toast.msg('Annulation !', 'Aucun point n\'a été positionné.');
                }
            }]
            ,items: [{
                id:'form-gps-station'
                ,xtype: 'form'
                ,title: 'Positionnement d\'un point à partir de coordonnées GPS'
                ,region: 'center'
                ,labelWidth: 100 // label settings here cascade unless overridden
                ,frame:true
                ,border:false
                ,split: false
                ,autoScroll:false
                ,monitorValid:true
                ,bodyStyle:'padding:5px 5px 0'
                ,width: 350
                ,defaultType: 'numberfield'
                ,items: [{
                    id: 'gps-station-zone'
                    ,xtype: 'numberfield'
                    ,allowDecimals :false
                    ,allowNegative: false
                    ,fieldLabel: 'Zone (31 ou 32) '
                    ,allowBlank:false
                    ,enableKeyEvents:true
                    ,minValue:31
                    ,minText:'Cette zone n\'est pas valide. Zone = 31 ou 32'
                    ,maxText:'Cette zone n\'est pas valide. Zone = 31 ou 32'
                    ,maxValue:32
                    ,blankText: 'La zone est obligatoire. Ce doit être un nombre entier = à 31 ou 32.'
                    ,name: 'zone'
                    ,width: 150
                    ,listeners: {
                        keyup:function(field,e){
                            var v = field.getValue();
                            var fLong = Ext.getCmp('gps-station-longitude')
                            var fLat = Ext.getCmp('gps-station-latitude')
                            if(v==31 || v==32){
                                if(v==31){
                                    fLong.show();fLong.setMinValue(719125);fLong.setMaxValue(791514);
                                    fLat.show();fLat.setMinValue(4923086);fLat.setMaxValue(5010936);
                                }
                                if(v==32){
                                    fLong.show();fLong.setMinValue(241546);fLong.setMaxValue(320202);
                                    fLat.show();fLat.setMinValue(4924529);fLat.setMaxValue(5006782);
                                }
                            }
                            else{
                                fLong.hide();
                                fLat.hide();
                            }
                        }
                    }
                },{
                    id: 'gps-station-longitude'
                    ,xtype: 'numberfield'
                    ,allowDecimals :false
                    ,allowNegative: false
                    ,hidden:true
                    ,fieldLabel: 'Longitude '
                    ,minValue:719125
                    ,minText:'Cette longitude n\'est pas valide pour l\'emprise de la carte. Elle doit être supérieure à 719125 (zone 31) ou 241546 (zone 32).'
                    ,maxValue:791514
                    ,maxText:'Cette longitude n\'est pas valide pour l\'emprise de la carte. Elle doit être inférieure à 791514 (zone 31) ou 320202 (zone 32).'
                    ,allowBlank:false
                    ,blankText: 'La longitude est obligatoire. Ce doit être un nombre entier ; coordonnées UTM en mètre'
                    ,name: 'longitude'
                    ,width: 150
                },{
                    id: 'gps-station-latitude'
                    ,xtype: 'numberfield'
                    ,allowDecimals :false
                    ,allowNegative: false
                    ,hidden:true
                    ,fieldLabel: 'Latitude '
                    ,minValue:4923086
                    ,minText:'Cette latitude n\'est pas valide pour l\'emprise de la carte. Elle doit être supérieure à 4923086 (zone 31) ou 4924529 (zone 32).'
                    ,maxValue:5010936
                    ,maxText:'Cette latitude n\'est pas valide pour l\'emprise de la carte. Elle doit être inférieure à 5010936 (zone 31) ou 5006782 (zone 32) .'
                    ,allowBlank:false
                    ,blankText: 'La latitude est obligatoire. Ce doit être un nombre entier ; coordonnées UTM en mètre'
                    ,name: 'latitude'
                    ,width: 150
                }]
                ,listeners: {
                    clientvalidation:function(form,valid){
                        if(valid){Ext.getCmp('gps-afficher-button').enable();}
                        else{Ext.getCmp('gps-afficher-button').disable();}
                    }
                }
            },{
                id:'panel-export-evenement'
                ,xtype: 'panel'
                ,region: 'south'
                ,frame:true
                ,border:false
                ,split: false
                ,autoScroll:false
                ,bodyStyle:'padding:5px 5px 0'
                ,width: 350
                ,html: 'Les coordonnés doivent être en UTM. </br>Zone 31 ou 32 uniquemnet pour le Parc national des Ecrins.'
            }]
            ,listeners: {
                hide:function(){this.destroy();}
            } 
        });
    };
//----------------------------------fin de fenêtre du choix des dates d'export----------------------------------

    // public space
    return {

        window: null

        ,init: function() {
            createProtocol();
            createStore();
            this.window = initWindow();
        }
        
        /**
         * Method: loadAp
         * Loads a record from the aps list store
         */
        ,loadStation: function(id,action,cd) {
            // if (!this.window) {
                this.init();
            // }
            this.window.show();
            if (action=='update') {
                Ext.getCmp('edit-station-form').getForm().findField('monaction').setValue('update');
                this.window.setTitle('Modification d\'une station');
                if (id) {
                    id_station = id;
                    wmslayer = map.getLayersByName('overlay')[0];
                    wmslayer.mergeNewParams({
                      id_station: id_station
                    });
                    wmslayer.setOpacity(0.25);
                    var options = {
                        url: ['bryo/get', id_station].join('/')
                        ,params: {format: 'geoJSON'}
                    };
                    eventProtocol.read(options);
                    //si l'évenement load a un listener on le supprime
                    if(gridStoreTaxons.hasListener('load')){gridStoreTaxons.events['load'].clearListeners();}
                    //si on passe un cd_nom à modifier, on ajout un listener sur load pour mettre ce taxon en édition
                    if(cd>0){
                        gridStoreTaxons.addListener('load',function(){
                            var monIndex = gridStoreTaxons.findExact('cd_nom',cd);
                            old_taxon = cd;
                            // alert("cd : "+cd+" index : "+monIndex);
                            Ext.getCmp('grid-edit-taxon').getSelectionModel().selectRow(monIndex);
                            Ext.getCmp('grid-edit-taxon').plugins[0].startEditing(monIndex,1);
                        });
                    }
                    gridStoreTaxonsLoad(id_station);
                    Ext.getCmp('taxons-liste-panel').show();
                }
            }
            if (action=='add') {
                activateControls(true);
                updateGeometryField(null);
                Ext.getCmp('edit-station-form').getForm().findField('monaction').setValue('add');
                Ext.getCmp('labelstation-station').setText( '<p class="redtext">Nouvelle station - saisir puis enregistrer pour obtenir un N° de station</p>',false);
                this.window.setTitle('Ajout d\'une nouvelle station');
                Ext.getCmp('taxons-liste-panel').hide();
                Ext.ux.Toast.msg('Attention !', 'Commencer par saisir la position de la station sur la carte pour activer le formulaire');
                gridStoreTaxons.removeAll();
            }
        }

        ,initGpsWindow: function() {
            this.GpsWindow = initGpsWindow();
            this.GpsWindow.show();
        }
        
        ,changeLabel: function(fieldId, newLabel){
              var label = Ext.DomQuery.select(String.format('label[for="{0}"]', fieldId));
              if (label){
                label[0].childNodes[0].nodeValue = newLabel;
              }
        }
    }
}();
