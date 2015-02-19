/**
 * @class application.editZp
 * Singleton to build the editZp window
 *
 * @singleton
 */
application.editZp = function() {
    // private variables

    /**
     * Property: map
     * {OpenLayers.Map}
     */
    var map = null;

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
    var vectorLayer = null;

    /**
     * Property: dragPanControl
     */
    var dragPanControl = null;

    /**
     * Property: drawPolygonControl
     */
    var drawPolygonControl = null;
    
    /**
     * Property: dragPolygonControl
     */
    var dragPolygonControl = null;

    /**
     * Property: modifyFeatureControl
     */
    var modifyFeatureControl = null;

    /**
     * Property: store
     * {Ext.data.Store} The zp store (should contain only one record)
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
     * APIProperty: id_zp
     * The id of zp to update (if applies), null in case of a creating a new zp
     */
    var indexzp = null;

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

    // private functions


    /**
     * Method: initViewport
     */
    var initWindow = function() {
        return new Ext.Window({

            title: "Modifier une zone de prospection"
            ,layout: 'border'
            ,modal: true
            ,plain: true
            ,plugins: [new Ext.ux.plugins.ProportionalWindows()]
            //,aspect: true
            ,width: 600
            ,height: 250
            ,percentage: .95
            ,split: true
            ,closeAction: 'hide'
            ,defaults: {
                border: false
            }
            // ,bbar: new Ext.StatusBar({
                // id: 'edit-zp-status'
                // ,defaultText: ''
            // })
            ,items: [
                getWindowCenterItem()
                ,getViewportEastItem()
            ]
            ,listeners: {
                show: initToolbarItems
                ,hide: resetWindow
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
            ,width: 300
            ,split: true
            ,autoScroll: true
            ,defaults: {
                border: false
            }
            ,items: [{
                id: 'edit-zp-form'
                ,xtype: 'form'
                ,bodyStyle: 'padding: 5px'
                ,disabled: true
                ,defaults: {
                    xtype: 'textfield'
                    ,width: 180
                }
                ,labelAlign: 'top'
                ,items: getFormItems()
                //pour version Extjs 3.3.1
                ,buttons:[{
                        text: 'Annuler'
                    ,xtype: 'button'
                    ,handler: function() {
                        application.editZp.window.hide();
                    }
                    ,scope: this
                },{
                     text: 'Enregistrer'
                    ,xtype: 'button'
                    ,id: 'zpSaveButton'
                    ,iconCls: 'action-save'
                    ,handler: submitForm
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
            ,id: 'edit-zp-mapcomponent'
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
        var comboObservateursZP = new Ext.ux.form.SuperBoxSelect({
            id:'combo-zp-observateurs'
            ,xtype:'superboxselect'
            ,fieldLabel: 'Observateur(s) '
            ,emptyText: 'Sélectionnez un ou plusieurs observateurs'
            ,allowBlank: false
            ,blankText: 'Choisir au moins un observateur est obligatoire'
            ,resizable: true
            ,name: 'lesobservateurs'
            ,store: application.auteursStore
            ,mode: 'local'
            ,displayField: 'auteur'
            ,valueField: 'id_role'
            ,forceSelection : true
            ,selectOnFocus:true            
            ,value:''
            ,anchor:'95%'
            ,listeners:{
                afterrender :function(){
                    Ext.getCmp('edit-zp-form').getForm().findField('ids_observateurs').setValue(this.getValue());
                }
                ,change:function(){
                    Ext.getCmp('edit-zp-form').getForm().findField('ids_observateurs').setValue(this.getValue());
                    // Ext.getCmp('combo-zp-taxon').focus();//ne fonctionne pas
                }
                ,render: function(c) {
                    Ext.QuickTips.register({
                        target: c.getEl(),
                        text: 'Le ou les auteurs de la prospection.'
                    });
                }
            }
        });
        return [{
            xtype:'label'
            ,html: 'Prospection du '
            ,id: 'label-dateobs'
        },comboObservateursZP
        ,{
            fieldLabel: 'Taxon (ne modifier que si nécessaire) '
            ,id:'combo-zp-taxon'
            ,name: 'taxon'
            ,xtype:"combo"
            ,hiddenName:"cd_nom"
            ,store: application.taxonsLStore
            ,valueField: "cd_nom"
            ,displayField: "latin"
            ,typeAhead: true
            ,typeAheadDelay:750
            ,forceSelection: true
            ,selectOnFocus: true
            ,triggerAction: 'all'
            ,mode: 'local'
            ,listeners:{
                afterrender :function(){
                    Ext.getCmp('edit-zp-form').getForm().findField('taxon_saisi').setValue(this.getValue());
                }
                ,select:function(){
                    Ext.getCmp('edit-zp-form').getForm().findField('taxon_saisi').setValue(this.getRawValue());
                    // Ext.getCmp('combo-zp-taxon').focus();//ne fonctionne pas
                }
                ,change:function(){
                    Ext.getCmp('edit-zp-form').getForm().findField('taxon_saisi').setValue(this.getRawValue());
                }
                ,render: function(c) {
                    Ext.QuickTips.register({
                        target: c.getEl(),
                        text: 'Le taxon recherché lors de la prospection.'
                    });
                }
            }
        },{
            id:'datefield-zp-date'
            ,fieldLabel: 'Date '
            ,name: 'dateobs'
            ,xtype:'datefield'
            ,maxValue: new Date()
            ,format: 'd/m/Y'
            ,altFormats:'Y-m-d'
            ,allowBlank: false
            ,blankText:'La date de la prospection est obligatoire'
            ,listeners: {
                render: function(c) {
                    Ext.QuickTips.register({
                        target: c.getEl(),
                        text: 'Date de réalisation de la prospection. Elle ne peut donc être postérieure à la date de saisie.'
                    });
                }
            }
        },{
            fieldLabel: 'Organisme producteur '
            ,id:'combo-zp-organisme'
            ,name: 'organisme'
            ,xtype:"combo"
            ,hiddenName:"id_organisme"
            ,store: application.organismeStore
            ,valueField: "id_organisme"
            ,displayField: "nom_organisme"
            ,typeAhead: true
            ,typeAheadDelay:750
            ,forceSelection: true
            ,selectOnFocus: true
            ,triggerAction: 'all'
            ,mode: 'local'
            ,listeners:{
                render: function(c) {
                    Ext.QuickTips.register({
                        target: c.getEl(),
                        text: 'L\'organisme producteur de la donnée. Seuls les utilisateurs de cet organisme pourront exporter cette donnée.'
                    });
                }
            }
        },{
            name: 'geometry'
            ,xtype: 'hidden'
        },{
            name: 'ids_observateurs'
            ,xtype: 'hidden'
        },{
            name: 'taxon_saisi'
            ,xtype: 'hidden'
        }];
    };

    /**
     * Method: createLayer
     * Creates the vector layer
     *
     * Return
     * <OpenLayers.Layer.Vector>
     */
    var createLayer = function() {
        vectorLayer = new OpenLayers.Layer.Vector("editZp vector layer"
            ,{
                protocol: eventProtocol
                ,strategies: [
                    new mapfish.Strategy.ProtocolListener()
                ]
                ,format: OpenLayers.Format.GeoJSON
            }
        );
        vectorLayer.events.on({
            featureadded: function(obj) {
                var feature = obj.feature;
                if (this.indexzp==null) {
                    activateControls(false);
                } else {
                    deactivateAllEditingControls();
                }
                updateGeometryField(feature);
                //modifyFeatureControl.selectControl.select(feature);
                //modifyFeatureControl.selectControl.handlers.feature.feature = feature;
                Ext.getCmp('edit-zp-form').enable();
                Ext.getCmp('edit-zp-form').ownerCt.ownerCt.doLayout();
            }
            ,featuremodified: function(obj) {
                updateGeometryField(obj.feature);
            }
            ,featureremoved: function(obj) {
                updateGeometryField(null);
                Ext.getCmp('edit-zp-form').disable();
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
        createLayer();
        map.addLayers([vectorLayer]);
        map.zoomToMaxExtent();
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
                drawPolygonControl = new OpenLayers.Control.DrawFeature(vectorLayer, OpenLayers.Handler.Polygon, {
                    title: 'Dessiner un polygone'
                }), {
                    iconCls: 'drawpolygon'
                    ,toggleGroup: this.id
                    ,disabled: true
                }
            );
            
            toolbar.addControl(
                dragPolygonControl = new OpenLayers.Control.DragFeature(vectorLayer, {
                    title: 'Déplacer une l\'aire de présence'
                    ,onComplete:function(feature) {
                        updateGeometryField(feature);
                    }
                }), {
                    iconCls: 'dragpolygon'
                    ,toggleGroup: this.id
                    ,disabled: true
                }
            );

            toolbar.addControl(
                modifyFeatureControl = new OpenLayers.Control.ModifyFeature(vectorLayer, {
                    title: 'Modifier la géométrie'
                }), {
                    iconCls: 'modifyfeature'
                    ,toggleGroup: this.id
                }
            );

            application.utils.addSeparator(toolbar);

            toolbar.add({
                text: 'Effacer la géométrie'
                ,id: 'edit-zp-geometry-erase'
                //,disabled: true
                ,iconCls: 'erase'
                ,qtip: 'Permet de supprimer la géométrie pour en créer une nouvelle'
                ,handler: function() {
                    Ext.Msg.confirm('Attention'
                        ,'Cela supprimera définitivement la géométrie dessinée avec le pda !<br />Confirmer ?'
                        ,function(btn) {
                            if (btn == 'yes') {
                                activateControls(true);
                                vectorLayer.removeFeatures(vectorLayer.features[0]);
                            }
                        }
                    )
                }
            });
            
            application.utils.addSeparator(toolbar);

            toolbar.add({
                text: 'GPX'
                ,id: 'edit-zp-gpx'
                //,disabled: true
                ,iconCls: 'gpx'
                ,qtip: 'Importer un fichier gpx comme aide à la numérisation de la zone de prospection'
                ,handler: function() {
                    application.editZp.addGpx();
                }
            });

            layerTreeTip = application.createLayerWindow(map);
            layerTreeTip.render(Ext.getCmp('edit-zp-mapcomponent').body);
            layerTreeTip.show();
            layerTreeTip.getEl().alignTo(
                Ext.getCmp('edit-zp-mapcomponent').body,
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
            toolbarInitializedOnce = true;

            // Ext.getCmp('edit-zp-status').add({
                // text: 'Annuler'
                // ,xtype: 'button'
                // ,handler: function() {
                    // application.editZp.window.hide();
                // }
                // ,scope: this
            // },{
                // text: 'Enregistrer'
                // ,xtype: 'button'
                // ,id: 'zpSaveButton'
                // ,iconCls: 'action-save'
                // ,handler: submitForm
            // });
        }
        else{ Ext.getCmp('zpSaveButton').enable();}
    };

    /**
     * Method: activateControls
     * Allows to activate / enable / deactivate / disable the draw and modify feature controls
     *
     * Parameters:
     * activateDrawControls - {Boolean} true to activate / enable the draw controls
     */
    var activateControls = function(activateDrawControls) {
        Ext.getCmp('edit-zp-geometry-erase').setDisabled(false);

        toolbar.getButtonForControl(modifyFeatureControl).setDisabled(activateDrawControls);
        toolbar.getButtonForControl(dragPolygonControl).setDisabled(activateDrawControls);
        if (activateDrawControls) {
            dragPolygonControl.deactivate();
            modifyFeatureControl.deactivate(); 
        } else {
            dragPolygonControl.activate();
            modifyFeatureControl.activate();  
        }
        Ext.each([drawPolygonControl]
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
        Ext.getCmp('edit-zp-geometry-erase').setDisabled(true);
        toolbar.getButtonForControl(modifyFeatureControl).setDisabled(true);
        modifyFeatureControl.deactivate();
        toolbar.getButtonForControl(drawPolygonControl).setDisabled(true);
        drawPolygonControl.deactivate();
        toolbar.getButtonForControl(dragPolygonControl).setDisabled(true);
        dragPolygonControl.deactivate();
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
        Ext.getCmp('edit-zp-form').getForm().findField('geometry').setValue(wkt);
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
                    //zpsListGrid.loadMask.show();
                }
                ,crudfinished: function(response) {
                    var feature = response.features[0];
                    Ext.getCmp('label-dateobs').setText('<p class="bluetext">Prospection du '+feature.data.dateobs+'</p><p class="bluetext">Taxon : '+feature.data.taxon_latin+'</p><br/>',false);
                    // Ext.getCmp('hidden-id_secteur_fp').setValue(feature.data.id_secteur_fp);
                    Ext.getCmp('edit-zp-form').getForm().loadRecord(feature);
                    //on limit le zoom à 9
                        var zoomLevel = map.getZoomForExtent(feature.geometry.getBounds());
                        var centerGeom = feature.geometry.getBounds().getCenterLonLat();
                        if (zoomLevel > 9){zoomLevel = 9;}
                        map.setCenter(centerGeom,zoomLevel);
                    //map.zoomToExtent(feature.geometry.getBounds());
                    Ext.getCmp('edit-zp-form').enable();
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
                'indexzp'
                ,'ids_observateurs'
                ,'observateurs'
                ,{name:'dateobs', type: 'date', dateFormat:'d/m/Y'}
                ,'taxon_latin'
                ,'taxon_saisi'
                ,'id_organisme'
                ,'cd_nom'
            ])
            ,listeners: {
                load: function(store, records) {
                    Ext.getCmp('edit-zp-form').getForm().loadRecord(records[0]);
                }
            }
        });
    };

    /**
     * Method: resetWindow
     * Reset the different items status (on close) for next usage
     */
    var resetWindow = function() {
        indexzp = null;
        map.zoomToMaxExtent();
        vectorLayer.removeFeatures(vectorLayer.features);
        Ext.getCmp('edit-zp-form').disable();
        Ext.getCmp('edit-zp-form').getForm().reset();
        dragPanControl.activate();
        if(Ext.getCmp('zp_count').text=="les 50 dernières prospections"){
            Ext.getCmp('hidden-start').setValue('yes')
            application.search.refreshZps();
        }
    };

    /**
     * Method: submitForm
     * Submits the form
     */
    var submitForm = function() {
        Ext.getCmp('zpSaveButton').setText('Enregistrement en cours...');
        Ext.getCmp('zpSaveButton').disable();
        var params = {};
        if (indexzp) {
            params.indexzp = indexzp;
            params.monaction = "update";
        }
        else{
            params.monaction = "add";
            params.id_organisme = application.user.id_organisme;
        }
        Ext.getCmp('edit-zp-form').getForm().submit({
            url: 'zp/save'
            ,params: params
            ,success: function(form, action) {
                application.search.refreshZps();
                if (indexzp) {
                    var index = 'zp-' + indexzp;
                    Ext.getCmp(index).refreshZp();
                    Ext.getCmp('zpSaveButton').setText('Enregistrer');
                    Ext.getCmp('zpSaveButton').enable();
                    application.editZp.window.hide();
                }
                else{
                    indexzp = action.result.indexzp;
                    application.editZp.initNewAp(indexzp);
                }
                
            }
            ,failure: function(form, action) {
                Ext.getCmp('zpSaveButton').setText('Enregistrer');
                Ext.getCmp('zpSaveButton').enable();
                var msg;
                switch (action.failureType) {
                      case Ext.form.Action.CLIENT_INVALID:
                          msg = "Les informations saisies sont invalides";
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
    
//-----------fenêtre de questionnement pour la saisie d'une ap ------------------------------------
    var initWindowNewAp = function(index) {
        var layer = vectorLayer;
        return new Ext.Window({
            id:'window-new-ap'
            ,layout:'fit'
            ,height:120
            ,width: 400
            ,closeAction:'hide'
            ,autoScroll:true
            ,modal: true
            ,plain: true
            ,split: true
            ,html:'<div style="text-align:center;font-size:12px;font-weight:bold;color:blue;">Vous venez de créer une nouvelle zone de prospection. </br>Souhaitez vous ajouter une aire de présence dans de cette zone de prospection ?</div>'
            ,buttons: [{
                text:'Nouvelle aire de présence'
                ,id:'bt-new-ap'
                ,iconCls:'add'
                ,handler: function(){
                    //récupérer l'indexzp nouveau = fait dans le submitform avec la réponse json de l'action save : on met à jour la variable global indexzp)
                   // trouver la zp nouvelle avec le nouvel indexzp dans le store de l'onglet search
                   var reg=new RegExp("^"+index+"$", "g");
                   var id = Ext.getCmp('zp_list_grid').getStore().find('indexzp',reg);
                   var rec = Ext.getCmp('zp_list_grid').getStore().getAt(id);
                   // ouvrir l'onglet de la zp nouvelle
                   application.layout.loadZp(rec);
                   // ouvrir l'editap avec mon action add + la feature contenant la géometrie pour centrer l'editAp sur les bounds de cette geometrie
                   application.editAp.loadAp(null,rec,'add',layer.features[0].geometry.bounds);
                   Ext.getCmp('window-new-ap').destroy();
                   Ext.getCmp('zpSaveButton').setText('Enregistrer');
                   Ext.getCmp('zpSaveButton').enable();
                   application.editZp.window.hide();
                }
            },{
                text: 'Aucune aire de présence'
                ,handler: function(){
                    Ext.getCmp('window-new-ap').destroy();
                    Ext.getCmp('zpSaveButton').setText('Enregistrer');
                    Ext.getCmp('zpSaveButton').enable();
                    application.editZp.window.hide();
                    Ext.ux.Toast.msg('Aucune aire de présence !', 'Il est toujours possible de saisir une aire de présence à posteriori.');
                }
            }]
            ,listeners: {
                hide:function(){this.destroy();}
            } 
        });
    };
//---------------------------------- fin de fenêtre de questionnement pour la saisie d'une ap ----------------------------------
//------------------------------------formulaire de chargement des fichiers---------------------------------------------------
  var getUploadFileFormPanel = function(){
    var formUploadFile = new Ext.FormPanel({
      id: 'form-upload-zp-gpx'
          ,fileUpload: true
          ,width: 400
          ,frame: true
          ,autoHeight: true
          ,bodyStyle: 'padding: 10px 10px 0 10px;'
          ,labelWidth: 50
          ,defaults: {
                anchor: '95%',
                allowBlank: false,
                msgTarget: 'side'
          }
          ,items: [{
                xtype: 'hidden',
                name: 'username',
                value: application.user.nom
          },{
                xtype: 'fileuploadfield',
                emptyText: 'Sélectionner un fichier (format gpx uniquement)',
                fieldLabel: 'Fichier',
                name: 'nom_fichier',
                buttonText: '',
                buttonCfg: {
                      iconCls: 'upload-icon'
                }
          }]
          ,buttons: [{
                text: 'Annuler',
                handler: function(){
                    formUploadFile.getForm().reset();
                }
          },{
                text: 'Enregistrer',
                handler: function(){
                    if(formUploadFile.getForm().isValid()){
                        formUploadFile.getForm().submit({
                            url: 'ap/uploadgpx',
                            enctype:'multipart/form-data',
                            waitMsg: 'chargement de votre fichier gpx...',
                            success: function(form, action){
                                if(action.result.success==true){
                                        application.editZp.createGpxLayer();
                                        Ext.ux.Toast.msg('Téléchargement !', 'Fichier gpx a été télécharger, vous devez zommer sur la localisation de son contenu pour le voir sur la carte');
                                    }
                                    else{
                                        Ext.ux.Toast.msg('Attention !', 'Téléchargement du fichier gpx : <br>'+action.result.errors);
                                    }
                                    application.editZp.windowUploadFile.hide();
                                    
                            },
                            failure :  function(form, action) {
                                if(action.result.success==false){
                                    Ext.ux.Toast.msg('Attention !', 'Une erreur est survenue');
                                }
                                application.editZp.windowUploadFile.hide();
                            }
                        });
                    }
                    else{alert('biiiiiip ! Saisie non valide')}
                }
            }]
        });
        return formUploadFile;
    }
    var initFormUploadFile = function() {
        return new Ext.Window({
          layout:'fit'
            ,title: 'charger un fichier gpx sur le fond de carte'
            ,closeAction:'hide'
            ,plain: true
            ,modal: true
            ,width: 550
            ,buttons: [{
                text: 'Fermer'
                ,handler: function(){
                    application.editZp.windowUploadFile.hide();
                }
            }]
            ,items: [ getUploadFileFormPanel() ]
        });
    };
//---------------------------------------fin du formulaire de chargement des fichiers----------------------------------------------------

    // public space
    return {

        window: null

        ,init: function() {
            createProtocol();
            createStore();
            this.window = initWindow();
        }
        ,initNewAp: function(index) {
            this.windowNewAp = initWindowNewAp(index);
            this.windowNewAp.show();
        }
        ,initWindowUploadFile: function() {
                this.windowUploadFile = initFormUploadFile();
        }
        ,addGpx: function() {
            if (this.windowUploadFile){}
            if (!this.windowUploadFile) {this.initWindowUploadFile();}
            this.windowUploadFile.show();
        }

        /**
         * Method: loadZp
         * Loads a record from the zps list store
         */
        ,loadZp: function(id,monaction,bounds) {
            if (!this.window) {
                this.init();
            }
            this.window.show();
            maLayer = vectorLayer;
            if (monaction=='update') {
                this.window.setTitle('Modification d\'une zone de propection');
                if (id) {
                    indexzp = id;
                    map.getLayersByName('overlay')[0].mergeNewParams({
                      indexzp: indexzp
                    });
                    var options = {
                        url: ['zp/get', id].join('/')
                        ,params: {format: 'geoJSON'}
                    };
                    eventProtocol.read(options);
                }
            }
            if (monaction=='add') {
                activateControls(true);
                updateGeometryField(null);
                this.window.setTitle('Ajout d\'une nouvelle zone de prospection');
                Ext.getCmp('combo-zp-organisme').setValue(application.user.id_organisme);
                Ext.getCmp('label-dateobs').setText( '<p class="redtext">Nouvelle propection - Saisir puis enregistrer pour pouvoir saisir des aires de présence</p>',false);
                Ext.ux.Toast.msg('Attention !', 'Commencer par saisir la zone de propection sur la carte pour activer le formulaire');
                var zoomLevel = map.getZoomForExtent(bounds);
                var centerGeom = bounds.getCenterLonLat();
                if (zoomLevel > 9){zoomLevel = 9;}
                map.setCenter(centerGeom,zoomLevel);
            }
        }    /**
         * Method: createGpsLayer
         * Creates the vector gml layer
         *use : createGpxLayer("../uploads/test.gpx");
         * Return
         * <OpenLayers.Layer.Vector>
         */
         
        ,createGpxLayer: function() {
        if(map.getLayersByName('gps')[0]){
            zpSelcontrol.deactivate();
            map.getLayersByName('gps')[0].events.unregister("loadend", ZpVectorGpxLayer, setExtent);
            map.getLayersByName('gps')[0].destroy();   
        }
            var styleMap = new OpenLayers.StyleMap({
                'default': {
                    fillColor: "gray"
                    ,strokeColor: "yellow"
                    ,cursor: "pointer"
                    ,fillOpacity: 0.5
                    ,strokeOpacity: 0.75
                    ,strokeWidth: 2
                    ,pointRadius: 7
                }
                ,select : {
                    fillColor: "blue"
                    ,strokeColor: "blue"
                    ,cursor: "pointer"
                    ,fillOpacity: 0.6
                    ,strokeOpacity: 1
                    ,strokeWidth: 2
                    ,pointRadius: 7
                }
            });
            // This will enable us to autozoom the map to the displayed data.
			var dataExtent;
			var setExtent = function(){
				if(dataExtent){dataExtent.extend(this.getDataExtent());}
				else{dataExtent = this.getDataExtent();}
                var zoomLevel = map.getZoomForExtent(dataExtent);
                var centerGeom = dataExtent.getCenterLonLat();
                if (zoomLevel > 9){zoomLevel = 9;}
                map.setCenter(centerGeom,zoomLevel);
				// map.zoomToExtent(dataExtent);
			};
            //identification de l'utilisateur dans le nom du gpx
            var reg=new RegExp("( )", "g");
            var gpxFile = application.user.nom.replace(reg,"_")
            ZpVectorGpxLayer = new OpenLayers.Layer.Vector("gps",{
                protocol: new OpenLayers.Protocol.HTTP({
                    url: host_uri+"/flore/uploads/gpx/gpx_"+gpxFile+".gpx"
                    ,format: new OpenLayers.Format.GPX()
                })
                ,strategies: [new OpenLayers.Strategy.Fixed()]
                ,styleMap: styleMap
                ,projection: new OpenLayers.Projection("EPSG:4326")      
            });
            // This will perform the autozoom as soon as the GPX file is loaded.
            ZpVectorGpxLayer.events.register("loadend", ZpVectorGpxLayer, setExtent);
            map.addLayer(ZpVectorGpxLayer);
            // This function creates a popup window. In this case, the popup is a cloud containing the "name" and "desc" elements from the GPX file.
			function createPopup(feature) {
                var gpxDiv = '<div> * Nom gps : <span style="font-weight:bold;">'+ feature.attributes.name+ '</span>';
                if(feature.attributes.desc){gpxDiv = gpxDiv + ' - '+ feature.attributes.desc;}
                if(feature.attributes.ele){gpxDiv = gpxDiv + ' - '+ Math.round(feature.attributes.ele) + ' m';}
                gpxDiv = gpxDiv + '</span></div>';
				feature.popup = new OpenLayers.Popup("gpx",
					feature.geometry.getBounds().getCenterLonLat(),
					null,
					gpxDiv,
					false
				);
                feature.popup.backgroundColor='#ccc';
                feature.popup.opacity=0.75;
                feature.popup.autoSize=true;
				map.addPopup(feature.popup);
			} 
			// This function destroys the popup when the user clicks the X.
			function destroyPopup(feature) {
				feature.popup.destroy();
				feature.popup = null;
			}
			// This feature connects the click events to the functions defined above, such that they are invoked when the user clicks on the map.
			zpSelcontrol = new OpenLayers.Control.SelectFeature(ZpVectorGpxLayer, {
				onSelect: createPopup,
                hover:true,
				onUnselect: destroyPopup
			});
			map.addControl(zpSelcontrol);
			zpSelcontrol.activate();
        }
        
    }
}();
