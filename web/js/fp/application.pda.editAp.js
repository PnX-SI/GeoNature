/**
 * @class application.editAp
 * Singleton to build the editAp window
 *
 * @singleton
 */

application.editAp = function() {
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
     * Property: dragPolygonControl
     */
    var dragPolygonControl = null;
    
    /**
     * Property: drawPolygonControl
     */
    var drawPolygonControl = null;

    /**
     * Property: modifyFeatureControl
     */
    var modifyFeatureControl = null;

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
     * APIProperty: id_ap
     * The id of ap to update (if applies), null in case of a creating a new ap
     */
    var indexap = null;

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
    var newGeom = true;
    var indexzp = null;
    // private functions

    /**
     * Method: initViewport
     */
    var initWindow = function() {
        return new Ext.Window({

            title: "Modifier une aire de présence"
            ,layout: 'border'
            ,modal: true
            ,plain: true
            ,plugins: [new Ext.ux.plugins.ProportionalWindows()]
            //,aspect: true
            ,width: 600
            ,height: 250
            ,percentage: .80
            ,split: true
            ,closeAction: 'hide'
            ,defaults: {
                border: false
            }
            // ,bbar: new Ext.StatusBar({
                // id: 'edit-ap-status'
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
            ,width: 350
            ,split: true
            ,autoScroll: true
            ,defaults: {
                border: false
            }
            ,items: [{
                id: 'edit-ap-form'
                ,xtype: 'form'
                ,bodyStyle: 'padding: 5px'
                ,disabled: true
                ,defaults: {
                    xtype: 'numberfield'
                    ,labelWidth: 90
                }
                ,labelAlign: 'left'
                ,monitorValid:true
                ,items: getFormItems()
                ,buttons:[{
                    text: 'Annuler'
                    ,xtype: 'button'
                    ,handler: function() {
                        application.editAp.window.hide();
                    }
                    ,scope: this
                },{
                    text: 'Enregistrer'
                    ,xtype: 'button'
                    ,id: 'apSaveButton'
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
            ,id: 'edit-ap-mapcomponent'
            ,xtype: 'mapcomponent'
            ,map: map
            ,tbar: toolbar
        };
    };
    var perturbationStore = new Ext.data.JsonStore({
            url: 'bibs/perturbations'
            ,fields: [
                'codeper'
                ,'classification'
                ,'description'
            ]
            ,sortInfo: {
                field: 'codeper'
                ,direction: 'ASC'
            }
            ,autoLoad: true
        })
    var physionomieStore = new Ext.data.JsonStore({
            url: 'bibs/physionomies'
            ,fields: [
                'id_physionomie'
                ,'groupe_physionomie'
                ,'nom_physionomie'
            ]
            ,sortInfo: {
                field: 'id_physionomie'
                ,direction: 'ASC'
            }
            ,autoLoad: true
        })
    //construction automatique de l'arbre des physionomies à partir de la base de données
    var constructListPhysionomies = function(){
        var monArbre = new Array;
        var childrens = new Array;
        var cl = null;
        var nouvelleClassification=false;
        var child = {};
        var classification = {};
        //on bouble sur les enregistrements du store des perturbations issu de la base
        physionomieStore.each(function(record){
            if(cl==null){cl = record.data.groupe_physionomie}//initialisation
            if(cl != record.data.groupe_physionomie){nouvelleClassification=true;}// si on a changé de niveau de groupe
            if(nouvelleClassification){ //on crée le groupe
                classification = {
                    text: cl
                    ,children:childrens
                };
                monArbre.push(classification); //on ajoute ce groupe à l'arbre
                nouvelleClassification=false; //on repasse à false pour les prochains tests
                childrens = new Array; //on vide la variable qui contenait le groupe pour en accueillir un nouveau
            }
            //création d'un noeud final avec checkbox
            child = {
                    id:record.data.id_physionomie
                    ,text:record.data.nom_physionomie
                    ,leaf:true
                    ,checked:false
                };
            
            childrens.push(child);//ajout du noeud au groupe
            cl = record.data.groupe_physionomie; //cl prend la valeur en cours du groupe pour un nouveau test en début de boucle 
        }) //fin de la boucle
        //ajout du dernier groupe après la fin de la dernière boucle
        classification = {
            text: cl
            ,children:childrens
        };
        monArbre.push(classification);
        ;
        return monArbre;
    };
    //construction automatique de l'arbre des perturbations à partir de la base de données
    var constructListPerturbations = function(){
        var monArbre = new Array;
        var childrens = new Array;
        var cl = null;
        var nouvelleClassification=false;
        var child = {};
        var classification = {};
        //on bouble sur les enregistrements du store des perturbations issu de la base
        perturbationStore.each(function(record){
            if(cl==null){cl = record.data.classification}//initialisation
            if(cl != record.data.classification){nouvelleClassification=true;}// si on a changé de niveau de classification
            if(nouvelleClassification){ //on crée le groupe
                classification = {
                    text: cl
                    ,children:childrens
                };
                monArbre.push(classification); //on ajoute ce groupe à l'arbre
                nouvelleClassification=false; //on repasse à false pour les prochains tests
                childrens = new Array; //on vide la variable qui contenait le groupe pour en accueillir un nouveau
            }
            //création d'un noeud final avec checkbox
            child = {
                    id:record.data.codeper
                    ,text:record.data.description
                    ,leaf:true
                    ,checked:false
                };
            
            childrens.push(child);//ajout du noeud au groupe
            cl = record.data.classification; //cl prend la valeur en cours du groupe pour un nouveau test en début de boucle 
        }) //fin de la boucle
        //ajout du dernier groupe après la fin de la dernière boucle
        classification = {
            text: cl
            ,children:childrens
        };
        monArbre.push(classification);
        ;
        return monArbre;
    };

    /**
     * Method: getFormItems
     * Creates the form items
     */
    var getFormItems = function() { 
        var phenologieStore = new Ext.data.JsonStore({
            url: 'bibs/listpheno'
            ,fields: [
                'codepheno'
                ,'pheno'
            ],
            sortInfo: {
                field: 'codepheno',
                direction: 'ASC'
            }
            ,autoLoad: true
        });
        var frequenceMethodoStore = new Ext.data.JsonStore({
            url: 'bibs/listfrequencemethodonew'
            ,fields: [
                'id_frequence_methodo_new'
                ,'nom_frequence_methodo_new'
            ],
            sortInfo: {
                field: 'id_frequence_methodo_new',
                direction: 'ASC'
            }
            ,autoLoad: true
        });
        var comptageMethodoStore = new Ext.data.JsonStore({
            url: 'bibs/listcomptagemethodo'
            ,fields: [
                'id_comptage_methodo'
                ,'nom_comptage_methodo'
            ],
            sortInfo: {
                field: 'id_comptage_methodo',
                direction: 'ASC'
            }
            ,autoLoad: true
        });
        //calcul de la fréquence à partir du résultat de l'échantillonage
        var calculFrequence = function(p,c){
            if(p!=0&&c!=0){
                if(c>p){
                    Ext.ux.Toast.msg('Attention !', 'Il ne peut y avoir plus de contacts que la somme des points des transects');
                    Ext.getCmp('fieldap-nb-contacts').setValue(null);
                }
                else{
                    Ext.getCmp('fieldap-frequenceap').setValue(Math.round(c/p*100));
                    Ext.getCmp('fieldset-4-pda').expand(true);
                }
            }
        };
        //calcul de la surface réelle en fonction de la pente
        var calculSurfaceReelle = function(s,p){
            if(s!=0&&p!=0){
                if(p<90){
                    var sr = s/Math.cos(Math.PI*(p)/180);
                    Ext.getCmp('labelap-info-surface-reelle').setText('<p>La surface réelle du polygone est de <span style="font-weight:bold">'+Math.round(sr)+'m²</span>.</br>Vous pouvez corriger la surface en fonction de cette information si vous le souhaitez.</p>',false);
                    Ext.getCmp('labelap-info-surface-reelle').getEl().highlight("ff0000", { attr: 'color', duration: 5 });
                }
                else{
                    Ext.ux.Toast.msg('Attention !', 'Si la pente est verticale, vous devez estimer la surface qui ne peut être calculée sur la carte.');
                    Ext.getCmp('labelap-info-surface-reelle').setText('<p>Si le terrain est en pente, donnez une pente en degrés pour calculer la surface réelle du polygone dessiné sur la carte (recommandé).</p></br>',false);
                    Ext.getCmp('labelap-info-surface-reelle').getEl().highlight("ff0000", { attr: 'color', duration: 5 });
                }
            }
        };
        //calcul de l'effectif en fonction du dénombrement des placettes
        var calculDenombrement = function(nbPlacettes,surfacePlacette,comptePlacettes,type){
            var surfaceAp = Ext.getCmp('fieldap-surface').getValue();
            if(nbPlacettes!=0&&surfacePlacette!=0){
                    var n = Math.round((surfaceAp*comptePlacettes)/(nbPlacettes*surfacePlacette));
                    Ext.getCmp('fieldap-'+type).setValue(n);
                    // Ext.ux.Toast.msg('Ok !', 'Rapporté à la surface, il y a .'+n+' éléments '+type+'s dans l\'aire de présence');
            }
        };
        
        return [{
            id:'labelap-ap'
            ,xtype:'label'
            ,html:'AP'
        },{
            id: 'labelap-observateurs'
            ,xtype:'label'
            ,html: '<p>Observateur(s) : </p>'
        },{
            id: 'labelap-pdop'
            ,xtype:'label'
            ,html: ''
        }
        ,{
        // Fieldset 
        xtype:'fieldset'
        ,id:'fieldset-1-pda'
        ,columnWidth: 1
        ,title: 'Etape 1 - Surface'
        ,collapsible: true
        ,collapsed:false
        ,autoHeight:true
        ,anchor:'95%'
        ,defaultType: 'numberfield'
        ,items :[{
                id: 'labelap-info-surface'
                ,xtype:'label'
                ,html: '<p>Information concernant la surface de l\'aire de présence</p>'
            },{
                id: 'fieldap-surface'
                ,fieldLabel: 'Surface en m² '
                ,allowDecimals :false
                ,allowNegative: false
                ,anchor:'98%'
                ,allowBlank:false
                ,blankText: 'La surface est obligatoire. Mettre zéro (0) si inconnue.</br>Ce doit être un nombre entier.'
                ,name:'surface'
                ,enableKeyEvents:true
                ,listeners:{
                    keyup:function(){Ext.getCmp('fieldset-2-pda').expand(true);}
                }
            },{
                id: 'labelap-info-surface-reelle'
                ,xtype:'label'
                ,html: '<p>Si le terrain est en pente, donnez une pente en degrés pour calculer la surface réelle du polygone dessiné sur la carte (recommandé).</p></br>'
            },{
                id: 'fieldap-pente'
                ,fieldLabel: 'pente en degrés '
                ,allowDecimals :false
                ,allowNegative: false
                ,anchor:'98%'
                ,name:'pente'
                ,enableKeyEvents:true
                ,listeners:{
                    keyup:function(){calculSurfaceReelle(Ext.getCmp('fieldap-surface').getValue(),Ext.getCmp('fieldap-pente').getValue());}
                }
            },{
                id: 'labelap-info-altitude'
                ,xtype:'label'
                ,hidden:true
                ,html: '<p>L\'altitude sera calculée lors de l\'enregistrement (recommandé).</br>Si vous fournissez une altitude, c\'est elle qui sera retenue.</p></br>'
            },{
                id: 'fieldap-altitude'
                ,fieldLabel: 'Altitude '
                ,allowDecimals :false
                ,allowNegative: false
                ,allowBlank:false
                ,blankText: 'L\'altitude est obligatoire. Mettre zéro (0) si inconnue.</br>Ce doit être un nombre entier.'
                ,name: 'altitude'
                ,value:0
                ,anchor:'98%'       
            }]
        },{
        // Fieldset 
        xtype:'fieldset'
        ,id:'fieldset-2-pda'
        ,columnWidth: 1
        ,title: 'Etape 2 - Phénologie'
        ,collapsible: true
        ,collapsed:true
        ,autoHeight:true
        ,anchor:'95%'
        ,items :[{
                fieldLabel: 'Phénologie '
                ,name: 'phenologie'
                ,xtype:"combo"
                ,hiddenName:"codepheno"
                ,store: phenologieStore
                ,valueField: "codepheno"
                ,displayField: "pheno"
                ,typeAhead: true
                ,forceSelection: true
                ,selectOnFocus: true
                ,resizable:true
                ,triggerAction: 'all'
                ,mode: 'local'
                ,anchor:'98%'
                ,listeners:{
                    select:function(){Ext.getCmp('fieldset-3-pda').expand(true);}
                }
            }]
        },{
        // Fieldset 
        xtype:'fieldset'
        ,id:'fieldset-3-pda'
        ,columnWidth: 1
        ,labelWidth:130
        ,title: 'Etape 3 - Fréquence'
        ,collapsible: true
        ,collapsed:true
        ,autoHeight:true
        ,anchor:'95%'
        ,defaultType: 'numberfield'
        ,items :[{
                id:'combo-pda-frequence-methodo'
                ,fieldLabel: 'Méthode'
                ,name: 'frequence_methodo'
                ,xtype:"combo"
                ,hiddenName:"id_frequence_methodo_new"
                ,store: frequenceMethodoStore
                ,valueField: "id_frequence_methodo_new"
                ,displayField: "nom_frequence_methodo_new"
                ,allowBlank:false
                ,blankText: 'La méthode de détermination de la fréquence est obligatoire.</br>.'
                ,typeAhead: true
                ,forceSelection: true
                ,selectOnFocus: true
                ,triggerAction: 'all'
                ,mode: 'local'
                ,anchor:'98%'
                ,listeners:{
                    select:function(){
                        application.utils.manageDisplayField('fieldap-frequenceap','show');
                        if(this.getValue()=='N'){
                            Ext.getCmp('fieldap-frequenceap').disable();
                            application.utils.manageDisplayField('fieldap-nb-transects','show');
                            application.utils.manageDisplayField('fieldap-nb-points','show');
                            application.utils.manageDisplayField('fieldap-nb-contacts','show');
                            Ext.getCmp('fieldap-nb-transects').setValue(null);
                            Ext.getCmp('fieldap-nb-points').setValue(null);
                            Ext.getCmp('fieldap-nb-contacts').setValue(null);
                             
                        }
                        else{
                            Ext.getCmp('fieldap-frequenceap').enable();
                            application.utils.manageDisplayField('fieldap-nb-transects','hide');
                            application.utils.manageDisplayField('fieldap-nb-points','hide');
                            application.utils.manageDisplayField('fieldap-nb-contacts','hide');
                            Ext.getCmp('fieldap-nb-transects').setValue(null);
                            Ext.getCmp('fieldap-nb-points').setValue(null);
                            Ext.getCmp('fieldap-nb-contacts').setValue(null);
                            if(indexap){Ext.getCmp('fieldap-frequenceap').setValue(Ext.getCmp('ap_list_grid').getStore().getAt(Ext.getCmp('ap_list_grid').getStore().findExact('indexap',indexap)).data.frequenceap);}
                        }
                    }
                    ,render: function(c) {
                        Ext.QuickTips.register({
                            target: c.getEl(),
                            text: 'Méthode de calcul de la fréquence.'
                        });
                    }
                }
            },{
                id: 'fieldap-nb-transects'
                ,fieldLabel: 'Nombre de transects '
                ,allowDecimals :false
                ,allowNegative: false
                ,minValue:1
                ,name:'nb_transects_frequence'
                ,anchor:'80%'
                ,listeners: {
                    render: function(c) {
                        Ext.QuickTips.register({
                            target: c.getEl(),
                            text: 'Nombre de transects réalisés dans l\'aire de présence.'
                        });
                    }
                }
            },{
                id: 'fieldap-nb-points'
                ,fieldLabel: 'Nombre de points '
                ,allowDecimals :false
                ,allowNegative: false
                ,name:'nb_points_frequence'
                ,anchor:'80%'
                ,enableKeyEvents:true
                ,listeners: {
                    keyup:function(field,e){
                        calculFrequence(field.getValue(),Ext.getCmp('fieldap-nb-contacts').getValue());
                    }
                    ,render: function(c) {
                        Ext.QuickTips.register({
                            target: c.getEl(),
                            text: 'Nombre total de points d\'échantillonnage pour l\ensemble des transects .'
                        });
                    }
                }
            },{
                id: 'fieldap-nb-contacts'
                ,fieldLabel: 'Nombre de contacts '
                ,allowDecimals :false
                ,allowNegative: false
                ,name:'nb_contacts_frequence'
                ,anchor:'80%'
                ,enableKeyEvents:true
                ,listeners: {
                    keyup:function(field,e){
                        calculFrequence(Ext.getCmp('fieldap-nb-points').getValue(),field.getValue());
                    }
                    ,render: function(c) {
                        Ext.QuickTips.register({
                            target: c.getEl(),
                            text: 'Nombre total de contacts avec le taxon pour l\ensemble des transects .'
                        });
                    }
                }
            },{
                id: 'fieldap-frequenceap'
                ,fieldLabel: 'Fréquence en % '
                ,allowDecimals :false
                ,allowNegative: false
                ,allowBlank:false
                ,blankText: 'La fréquence est obligatoire.</br>Ce doit être un nombre entier.'
                ,name:'frequenceap'
                ,anchor:'98%'
                ,enableKeyEvents:true
                ,listeners:{
                    keyup:function(){
                        Ext.getCmp('combo-pda-comptage-methodo').setValue(9);
                        Ext.getCmp('combo-pda-comptage-methodo').fireEvent('select');
                        Ext.getCmp('fieldset-4-pda').expand(true);
                    }
                    ,render: function(c) {
                        Ext.QuickTips.register({
                            target: c.getEl(),
                            text: 'Fréquence pour l\'ensemble de l\'aire de présence. Dans le cas des transects, le calcul est fait automatiquement à partir des données saisies. Vous ne pouvez pas le modifier.'
                        });
                    }
                }
            }]
        },{
        // Fieldset 
        xtype:'fieldset'
        ,id:'fieldset-4-pda'
        ,columnWidth: 1
        ,labelWidth:130
        ,title: 'Etape 4 - Dénombrement'
        ,collapsible: true
        ,collapsed:true
        ,autoHeight:true
        ,anchor:'95%'
        ,defaultType: 'numberfield'
        ,items :[{
                id:'combo-pda-comptage-methodo'
                ,fieldLabel: 'Méthode'
                ,name: 'comptage_methodo'
                ,xtype:"combo"
                ,hiddenName:"id_comptage_methodo"
                ,store: comptageMethodoStore
                ,valueField: "id_comptage_methodo"
                ,displayField: "nom_comptage_methodo"
                ,allowBlank:false
                ,blankText: 'La méthode de comptage est obligatoire.</br> Choisir aucun comptage si besoin.'
                ,typeAhead: true
                ,forceSelection: true
                ,selectOnFocus: true
                ,triggerAction: 'all'
                ,mode: 'local'
                ,anchor:'98%'
                ,listeners:{
                    select:function(){
                        application.utils.manageDisplayField('fieldap-fertile','show');
                        application.utils.manageDisplayField('fieldap-sterile','show');
                        var objets_a_compter = Ext.getCmp('edit-ap-form').getForm().findField('objets_a_compter').getValue();
                        if(this.getValue()==1||this.getValue()==2){
                            if(this.getValue()==2){
                                Ext.getCmp('fieldap-nombre-placettes').show();
                                Ext.getCmp('fieldap-surface-placette').show();
                                if(objets_a_compter.indexOf('EF')!=-1){
                                    Ext.getCmp('fieldap-fertile').disable();
                                    Ext.getCmp('fieldset-pda-fertiles').show();
                                    Ext.getCmp('fieldap-effectifs-fertile').show();
                                    Ext.getCmp('fieldap-effectifs-fertile').setValue(null);
                                }
                                if(objets_a_compter.indexOf('ES')!=-1){
                                    Ext.getCmp('fieldap-sterile').disable();
                                    Ext.getCmp('fieldset-pda-steriles').show();
                                    Ext.getCmp('fieldap-effectifs-sterile').show();
                                    Ext.getCmp('fieldap-effectifs-sterile').setValue(null);
                                }       
                            }
                            if(this.getValue()==1){
                                Ext.getCmp('fieldap-surface-placette').hide();
                                Ext.getCmp('fieldap-nombre-placettes').hide(); 
                                Ext.getCmp('fieldap-nombre-placettes').setValue(null);
                                Ext.getCmp('fieldap-surface-placette').setValue(null);
                                Ext.getCmp('fieldap-effectifs-fertile').setValue(null);
                                Ext.getCmp('fieldap-effectifs-sterile').setValue(null);
                                Ext.getCmp('fieldap-effectifs-fertile').hide();
                                Ext.getCmp('fieldap-effectifs-sterile').hide();
                                if(objets_a_compter.indexOf('EF')!=-1){
                                    Ext.getCmp('fieldap-fertile').enable();
                                    Ext.getCmp('fieldset-pda-fertiles').show();
                                }  
                                if(objets_a_compter.indexOf('ES')!=-1){
                                    Ext.getCmp('fieldap-sterile').enable();       
                                    Ext.getCmp('fieldset-pda-steriles').show();
                                }                               
                                // if(indexap){Ext.getCmp('fieldap-frequenceap').setValue(Ext.getCmp('ap_list_grid').getStore().getAt(Ext.getCmp('ap_list_grid').getStore().findExact('indexap',indexap)).data.frequenceap);}
                            }
                        }
                        else{
                                Ext.getCmp('fieldset-pda-fertiles').hide();
                                Ext.getCmp('fieldset-pda-steriles').hide();
                                Ext.getCmp('fieldap-nombre-placettes').hide();
                                Ext.getCmp('fieldap-surface-placette').hide();
                                Ext.getCmp('fieldap-effectifs-fertile').setValue(null);
                                Ext.getCmp('fieldap-effectifs-sterile').setValue(null);
                                Ext.getCmp('fieldap-fertile').setValue(null);
                                Ext.getCmp('fieldap-sterile').setValue(null);
                                Ext.getCmp('fieldap-nombre-placettes').setValue(null);
                                Ext.getCmp('fieldap-surface-placette').setValue(null);
                        }
                    }
                    ,render: function(c) {
                        Ext.QuickTips.register({
                            target: c.getEl(),
                            text: 'Méthode de dénombrement. Selon la méthode, des informations complémentaires sont à fournir.'
                        });
                    }
                }
            },{   
                id: 'fieldap-nombre-placettes'
                ,fieldLabel: 'Nombre de placettes  '
                ,allowDecimals :false
                ,allowNegative: false
                ,name:'nb_placettes_comptage'
                ,enableKeyEvents:true
                ,listeners:{ 
                    //function pour cacher ou afficher les label en même temps que le champ de saisie
                     beforehide:function(nf){nf.getEl().up('.x-form-item').setDisplayed(false);}
                    ,beforeshow:function(nf){nf.getEl().up('.x-form-item').setDisplayed(true);}
                    ,keyup:function(field,e){Ext.getCmp('fieldap-fertile').setValue(null);Ext.getCmp('fieldap-sterile').setValue(null);Ext.getCmp('fieldap-effectifs-fertile').setValue(null);Ext.getCmp('fieldap-effectifs-sterile').setValue(null);}                    
                    ,render: function(c) {
                        Ext.QuickTips.register({
                            target: c.getEl(),
                            text: 'Nombre total de placettes échantillonnées'
                        });
                    }
                } 
            },{   
                id: 'fieldap-surface-placette'
                ,fieldLabel: 'Surface de la placette  '
                ,allowDecimals :true
                ,allowNegative: false
                ,decimalSeparator: '.'
                ,name:'surface_placette_comptage'
                ,enableKeyEvents:true
                ,listeners:{ 
                    //function pour cacher ou afficher les label en même temps que le champ de saisie
                     beforehide:function(nf){nf.getEl().up('.x-form-item').setDisplayed(false);}
                    ,beforeshow:function(nf){nf.getEl().up('.x-form-item').setDisplayed(true);}
                    ,keyup:function(field,e){Ext.getCmp('fieldap-fertile').setValue(null);Ext.getCmp('fieldap-sterile').setValue(null);Ext.getCmp('fieldap-effectifs-fertile').setValue(null);Ext.getCmp('fieldap-effectifs-sterile').setValue(null);} 
                    ,render: function(c) {
                        Ext.QuickTips.register({
                            target: c.getEl(),
                            text: 'Surface unitaire de chaque placette en m²'
                        });
                    }
                } 
            },{
                // Fieldset 
                xtype:'fieldset'
                ,id:'fieldset-pda-fertiles'
                ,columnWidth: 1
                ,labelWidth:130
                ,title: 'Fertiles'
                ,autoHeight:true
                ,anchor:'98%'
                ,defaultType: 'numberfield'
                ,items :[{   
                    id: 'fieldap-effectifs-fertile'
                    ,fieldLabel: 'Somme des placettes  '
                    ,allowDecimals :false
                    ,allowNegative: false
                    ,name:'effectif_placettes_comptage_fertile'
                    ,anchor:'80%'
                    ,enableKeyEvents:true
                    ,listeners:{
                        //function pour cacher ou afficher les label en même temps que le champ de saisie                    
                         beforehide:function(nf){nf.getEl().up('.x-form-item').setDisplayed(false);}
                        ,beforeshow:function(nf){nf.getEl().up('.x-form-item').setDisplayed(true);}
                        ,keyup:function(field,e){calculDenombrement(Ext.getCmp('fieldap-nombre-placettes').getValue(),Ext.getCmp('fieldap-surface-placette').getValue(),field.getValue(),'fertile');}                           
                        ,render: function(c) {
                            Ext.QuickTips.register({
                                target: c.getEl(),
                                text: 'Nombre total d\'éléments fertiles dénombrés pour l\'ensemble des placettes.'
                            });
                        }
                    } 
                },{
                    id: 'fieldap-fertile'
                    ,fieldLabel: 'Total aire de présence '
                    ,allowDecimals :false
                    ,allowNegative: false
                    ,name:'nbfertile'
                    ,anchor:'80%'
                    //function pour cacher ou afficher les label en même temps que le champ de saisie
                    ,listeners:{ 
                        beforehide:function(nf){nf.getEl().up('.x-form-item').setDisplayed(false);}
                        ,beforeshow:function(nf){nf.getEl().up('.x-form-item').setDisplayed(true);}                
                        ,render: function(c) {
                            Ext.QuickTips.register({
                                target: c.getEl(),
                                text: 'Nombre total d\'éléments fertiles dénombrés. En cas d\'échantillonnage, le calcul est fait automatiquement à partir des données saisies. Vous ne pouvez pas le modifier.'
                            });
                        }
                    } 
                }]
            }
            ,{
                // Fieldset 
                xtype:'fieldset'
                ,id:'fieldset-pda-steriles'
                ,columnWidth: 1
                ,labelWidth:130
                ,title: 'Steriles'
                ,autoHeight:true
                ,anchor:'98%'
                ,defaultType: 'numberfield'
                ,items :[{ 
                    id: 'fieldap-effectifs-sterile'
                    ,fieldLabel: 'Somme des placettes  '
                    ,allowDecimals :false
                    ,allowNegative: false
                    ,name:'effectif_placettes_comptage_sterile'
                    ,anchor:'80%'
                    ,enableKeyEvents:true
                    ,listeners:{ 
                        //function pour cacher ou afficher les label en même temps que le champ de saisie
                        beforehide:function(nf){nf.getEl().up('.x-form-item').setDisplayed(false);}
                        ,beforeshow:function(nf){nf.getEl().up('.x-form-item').setDisplayed(true);}
                        ,keyup:function(field,e){calculDenombrement(Ext.getCmp('fieldap-nombre-placettes').getValue(),Ext.getCmp('fieldap-surface-placette').getValue(),field.getValue(),'sterile');}                        
                        ,render: function(c) {
                            Ext.QuickTips.register({
                                target: c.getEl(),
                                text: 'Nombre total d\'éléments steriles dénombrés pour l\'ensemble des placettes.'
                            });
                        }
                    } 
                },{
                    id: 'fieldap-sterile'
                    ,fieldLabel: 'Total aire de présence '
                    ,allowDecimals :false
                    ,allowNegative: false
                    ,name:'nbsterile'
                    ,anchor:'80%'
                    //function pour cacher ou afficher les label en même temps que le champ de saisie
                    ,listeners:{ 
                        beforehide:function(nf){nf.getEl().up('.x-form-item').setDisplayed(false);}
                        ,beforeshow:function(nf){nf.getEl().up('.x-form-item').setDisplayed(true);}
                        ,render: function(c) {
                            Ext.QuickTips.register({
                                target: c.getEl(),
                                text: 'Nombre total d\'éléments stériles dénombrés. En cas d\'échantillonnage, le calcul est fait automatiquement à partir des données saisies. Vous ne pouvez pas le modifier.'
                            });
                        }
                    }
                }]
            }
            ]
        },{
            xtype: 'treepanel'
            ,autoScroll: true
            ,id: 'tree-perturbations'
            ,animate: false
            ,anchor:'95%'
            ,root: {
                text: 'Perturbations'
                ,children: constructListPerturbations()
            }
            ,listeners:{
                checkchange:function(){
                    var compt=0;
                    var codesper = new Array();
                    Ext.each(Ext.getCmp('tree-perturbations').getRootNode().childNodes, function(themeNode) {
                        Ext.each(themeNode.childNodes, function(node) {
                            if(node.getUI().isChecked()){
                                compt++;
                                codesper.push(parseInt(node.id));
                            }
                        });
                    });
                    Ext.getCmp('tree-perturbations').getRootNode().setText('Perturbations ('+compt+')');
                    Ext.getCmp('edit-ap-form').getForm().findField('codesper').setValue(codesper);
                }
                ,render: function(c) {
                    Ext.QuickTips.register({
                        target: c.getEl(),
                        text: 'Liste de la ou des perturbations susceptibles de concerner l\'aire de présence. Cliquez sur les petits "+" pour ouvrir l\'arborescence et cocher la ou les perturbations.'
                    });
                }
            }
        },{
            xtype: 'treepanel'
            ,autoScroll: true
            ,id: 'tree-physionomies'
            ,animate: false
            ,anchor:'95%'
            ,root: {
                text: 'Milieux'
                ,children: constructListPhysionomies()
            }
            ,listeners:{
                checkchange:function(){
                    var compt=0;
                    var ids_physionomie = new Array();
                    Ext.each(Ext.getCmp('tree-physionomies').getRootNode().childNodes, function(themeNode) {
                        Ext.each(themeNode.childNodes, function(node) {
                            if(node.getUI().isChecked()){
                                compt++;
                                ids_physionomie.push(parseInt(node.id));
                            }
                        });
                    });
                    Ext.getCmp('tree-physionomies').getRootNode().setText('Milieux ('+compt+')');
                    Ext.getCmp('edit-ap-form').getForm().findField('ids_physionomie').setValue(ids_physionomie);
                }
                ,render: function(c) {
                    Ext.QuickTips.register({
                        target: c.getEl(),
                        text: 'Liste du ou des milieux susceptibles de concerner l\'aire de présence. Cliquez sur les petits "+" pour ouvrir l\'arborescence et cocher le ou les milieux.'
                    });
                }
            }
        },{
            id:'ta-pda-remarques'
            ,xtype: 'textarea'
            ,fieldLabel: 'Remarques '
            ,name: 'remarques'
            ,grow: true
            ,autoHeight: true
            ,anchor:'95%'
        },{
            id:'hidden-perturbations'
            ,name: 'codesper'
            ,xtype: 'hidden'
        },{
            id:'hidden-physionomies'
            ,name: 'ids_physionomie'
            ,xtype: 'hidden'
        },{
            name: 'geometry'
            ,xtype: 'hidden'
        },{
            name: 'monaction'
            ,xtype: 'hidden'
        },{
            name: 'objets_a_compter'
            ,xtype: 'hidden'
        },{
            name: 'indexzp'
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
        vectorLayer = new OpenLayers.Layer.Vector("editAp vector layer"
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
                var geom = feature.geometry;
                if (this.indexap==null) {
                    activateControls(false);
                } else {
                    deactivateAllEditingControls();
                }
                updateGeometryField(feature);
                //modifyFeatureControl.selectControl.select(feature);
                //modifyFeatureControl.selectControl.handlers.feature.feature = feature;
                Ext.getCmp('edit-ap-form').enable();
                Ext.getCmp('edit-ap-form').ownerCt.ownerCt.doLayout();
                //assistance à l'utilisateur concernant la surface selon la nature de la géométrie dessinée
                if(newGeom){
                    if(geom.getLength()==0){ //cas du point
                        Ext.getCmp('labelap-info-surface').setText('<p>Vous devez fournir une surface pour ce point</p>',false);
                        Ext.getCmp('edit-ap-form').getForm().findField('fieldap-surface').setValue(0);
                        Ext.getCmp('labelap-info-surface-reelle').setText('<p></p>',false);
                        application.utils.manageDisplayField('fieldap-pente','hide');
                    }
                    else{//cas ligne et polygone
                        if(geom.getArea()==0){//cas de la ligne
                            Ext.getCmp('labelap-info-surface').setText('<p>La longueur de la ligne est de <span style="font-weight:bold">'+Math.round(geom.getLength())+' mètres</span>.<br/>Cette information devrait vous aider à calculer la surface de l\'aire de présence</p>',false);
                            Ext.getCmp('edit-ap-form').getForm().findField('fieldap-surface').setValue(0);
                            Ext.getCmp('labelap-info-surface-reelle').setText('<p></p>',false);
                            application.utils.manageDisplayField('fieldap-pente','hide');
                        }
                        else{//cas du polygone
                            Ext.getCmp('labelap-info-surface').setText('<p>La surface planimétrique du polygone dessiné est de <span style="font-weight:bold">'+Math.round(geom.getArea())+'m²</span>.<br/>Cette surface pourrait être recalculée en fonction de la pente</p>',false);
                            Ext.getCmp('edit-ap-form').getForm().findField('fieldap-surface').setValue(Math.round(geom.getArea()));
                            Ext.getCmp('labelap-info-surface-reelle').setText('<p>Si le terrain est en pente, donnez une pente en degrés pour calculer la surface réelle du polygone dessiné sur la carte (recommandé).</p></br>',false);
                            application.utils.manageDisplayField('fieldap-pente','show');
                            Ext.getCmp('fieldset-2-pda').expand();
                        }
                    }
                    Ext.getCmp('labelap-info-surface').getEl().highlight("ff0000", { attr: 'color', duration: 15 });
                    Ext.getCmp('edit-ap-form').getForm().findField('fieldap-altitude').setValue(0);
                    newgeom = false;
                } 
            }
            ,featuremodified: function(obj) {
                updateGeometryField(obj.feature);
            }
            ,featureremoved: function(obj) {
                updateGeometryField(null);
                Ext.getCmp('labelap-info-surface').setText('<p>Information concernant la surface de l\aire de présence</p>',false);
                Ext.getCmp('edit-ap-form').getForm().findField('fieldap-surface').setValue(0);
                Ext.getCmp('edit-ap-form').getForm().findField('fieldap-altitude').setValue(0);
                Ext.getCmp('edit-ap-form').disable();
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
          indexzp:indexzp
        });
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
                drawPointControl = new OpenLayers.Control.DrawFeature(vectorLayer, OpenLayers.Handler.Point, {
                    title: 'Dessiner un point'
                }), {
                    iconCls: 'drawpoint'
                    ,toggleGroup: this.id
                    ,disabled: true
                }
            );
            toolbar.addControl(
                drawLineControl = new OpenLayers.Control.DrawFeature(vectorLayer, OpenLayers.Handler.Path, {
                    title: 'Dessiner une ligne'
                }), {
                    iconCls: 'drawline'
                    ,toggleGroup: this.id
                    ,disabled: true
                }
            );
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
                    title: 'Déplacer la zone de prospection'
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
                ,id: 'edit-ap-geometry-erase'
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
                                newGeom = true;
                            }
                        }
                    )
                }
            });
            
            application.utils.addSeparator(toolbar);

            toolbar.add({
                text: 'GPX'
                ,id: 'edit-ap-gpx'
                //,disabled: true
                ,iconCls: 'gpx'
                ,qtip: 'Importer un fichier gpx comme aide à la numérisation de l\'aire de présence'
                ,handler: function() {
                    application.editAp.addGpx();
                }
            });

            layerTreeTip = application.createLayerWindow(map);
            layerTreeTip.render(Ext.getCmp('edit-ap-mapcomponent').body);
            layerTreeTip.show();
            layerTreeTip.getEl().alignTo(
                Ext.getCmp('edit-ap-mapcomponent').body,
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

            // Ext.getCmp('edit-ap-status').add({
                // text: 'Annuler'
                // ,xtype: 'button'
                // ,handler: function() {
                    // application.editAp.window.hide();
                // }
                // ,scope: this
            // },{
                // text: 'Enregistrer'
                // ,xtype: 'button'
                // ,id: 'apSaveButton'
                // ,iconCls: 'action-save'
                // ,handler:submitForm
            // });
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
        Ext.getCmp('edit-ap-geometry-erase').setDisabled(false);
        toolbar.getButtonForControl(modifyFeatureControl).setDisabled(activateDrawControls);
        toolbar.getButtonForControl(dragPolygonControl).setDisabled(activateDrawControls);
        if (activateDrawControls) {
            dragPolygonControl.deactivate();
            modifyFeatureControl.deactivate();
        } else {
            dragPolygonControl.activate();
            modifyFeatureControl.activate();
        }
        Ext.each([drawPolygonControl,drawPointControl,drawLineControl]
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
        Ext.getCmp('edit-ap-geometry-erase').setDisabled(true);
        toolbar.getButtonForControl(modifyFeatureControl).setDisabled(true);
        modifyFeatureControl.deactivate();
        toolbar.getButtonForControl(dragPolygonControl).setDisabled(true);
        dragPolygonControl.deactivate();
        toolbar.getButtonForControl(drawPolygonControl).setDisabled(true);
        drawPolygonControl.deactivate();
        toolbar.getButtonForControl(drawLineControl).setDisabled(true);
        drawLineControl.deactivate();
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
        Ext.getCmp('edit-ap-form').getForm().findField('geometry').setValue(wkt);
        firstGeometryLoad = false;
    };
    
    var resetPerturbationsTree = function() {
        Ext.getCmp('tree-perturbations').collapseAll();
        Ext.each(Ext.getCmp('tree-perturbations').getRootNode().childNodes, function(themeNode) {
            Ext.each(themeNode.childNodes, function(node) {
                node.getUI().toggleCheck(false);
            });
        });
        Ext.getCmp('tree-perturbations').getRootNode().setText('Perturbations (0)');
        Ext.getCmp('tree-perturbations').collapseAll();
    };
    
    var resetPhysionomiesTree = function() {
        Ext.getCmp('tree-physionomies').collapseAll();
        Ext.each(Ext.getCmp('tree-physionomies').getRootNode().childNodes, function(themeNode) {
            Ext.each(themeNode.childNodes, function(node) {
                node.getUI().toggleCheck(false);
            });
        });
        Ext.getCmp('tree-physionomies').getRootNode().setText('Milieux (0)');
        Ext.getCmp('tree-physionomies').collapseAll();
    };
    
    var updatePerturbationsTree = function() {
        var p = new Array();
        p = Ext.getCmp('edit-ap-form').getForm().findField('codesper').value;
        Ext.getCmp('tree-perturbations').collapseAll();
        Ext.each(Ext.getCmp('tree-perturbations').getRootNode().childNodes, function(themeNode) {
            Ext.each(themeNode.childNodes, function(node) {
                node.getUI().toggleCheck(false);
            });
        });
        Ext.getCmp('tree-perturbations').getRootNode().setText('Perturbations ('+p.length+')');
        Ext.getCmp('tree-perturbations').collapseAll();
        Ext.each(p, function(record, index) {
            if(node = Ext.getCmp('tree-perturbations').getNodeById(record)){
                node.getUI().toggleCheck(true); 
            }
        });
    };
    var updatePhysionomiesTree = function() {
        var p = new Array();
        p = Ext.getCmp('edit-ap-form').getForm().findField('ids_physionomie').value;
        Ext.getCmp('tree-physionomies').collapseAll();
        Ext.each(Ext.getCmp('tree-physionomies').getRootNode().childNodes, function(themeNode) {
            Ext.each(themeNode.childNodes, function(node) {
                node.getUI().toggleCheck(false);
            });
        });
        Ext.getCmp('tree-physionomies').getRootNode().setText('Milieux ('+p.length+')');
        Ext.getCmp('tree-physionomies').collapseAll();
        Ext.each(p, function(record, index) {
            if(node = Ext.getCmp('tree-physionomies').getNodeById(record)){
                node.getUI().toggleCheck(true); 
            }
        });
    };
    
    var manageDisplayComptageFields = function(feature){
        //masquer - afficher les champ fertile et stérile selon s'ils doivent être compté ou pas
        var objets_a_compter = feature.data.objets_a_compter;
        //si ce taxon ne doit pas être compter, on masque la partie comptage
        if(objets_a_compter.indexOf('EF')==-1&&objets_a_compter.indexOf('ES')==-1){
            Ext.getCmp('fieldset-4-pda').hide();
        }
        // sinon on gère l'affichage des champs selon la méthode de comptage choisie et les objets à compter pour le taxon en question
        else{
            Ext.getCmp('fieldset-4-pda').show(); //on commence par afficher la partie comptage
            if(feature.data.id_comptage_methodo==9){ // = aucun comptage
                Ext.getCmp('fieldset-pda-fertiles').hide();
                Ext.getCmp('fieldset-pda-steriles').hide(); 
                Ext.getCmp('fieldap-nombre-placettes').hide();
                Ext.getCmp('fieldap-surface-placette').hide();                            
            }
            else{
                if(feature.data.id_comptage_methodo==1){ // = ressencement exhaustif
                    Ext.getCmp('fieldap-nombre-placettes').hide();
                    Ext.getCmp('fieldap-surface-placette').hide();
                    if(objets_a_compter.indexOf('EF')==-1){Ext.getCmp('fieldset-pda-fertiles').hide();}
                    else{
                        Ext.getCmp('fieldset-pda-fertiles').show();
                        Ext.getCmp('fieldap-effectifs-fertile').hide();                                
                    }
                    if(objets_a_compter.indexOf('ES')==-1){Ext.getCmp('fieldset-pda-steriles').hide();}
                    else{
                        Ext.getCmp('fieldset-pda-steriles').show();
                        Ext.getCmp('fieldap-effectifs-sterile').hide();
                    }  
                }
                if(feature.data.id_comptage_methodo==2){ // = échantillonnage
                    Ext.getCmp('fieldap-nombre-placettes').show();
                    Ext.getCmp('fieldap-surface-placette').show();
                    if(objets_a_compter.indexOf('EF')==-1){Ext.getCmp('fieldset-pda-fertiles').hide();}
                    else{
                        Ext.getCmp('fieldset-pda-fertiles').show();
                        Ext.getCmp('fieldap-effectifs-fertile').show();
                    }
                    if(objets_a_compter.indexOf('ES')==-1){Ext.getCmp('fieldset-pda-steriles').hide();}
                    else{
                        Ext.getCmp('fieldset-pda-steriles').show();
                        Ext.getCmp('fieldap-effectifs-sterile').show();
                    }  
                }
            }
        }
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
                    manageDisplayComptageFields(feature);
                    application.utils.manageDisplayField('fieldap-frequenceap','show');
                    if(feature.data.id_frequence_methodo_new=='N'){
                        Ext.getCmp('fieldap-frequenceap').disable();
                        application.utils.manageDisplayField('fieldap-nb-transects','show');
                        application.utils.manageDisplayField('fieldap-nb-points','show');
                        application.utils.manageDisplayField('fieldap-nb-contacts','show');  
                    }
                    else{
                        Ext.getCmp('fieldap-frequenceap').enable();
                        application.utils.manageDisplayField('fieldap-nb-transects','hide');
                        application.utils.manageDisplayField('fieldap-nb-points','hide');
                        application.utils.manageDisplayField('fieldap-nb-contacts','hide');
                        
                    }
                    Ext.getCmp('labelap-ap').setText( '<p class="bluetext">Aire de présence pour la prospection de</br> '+feature.data.taxon+' du '+feature.data.dateobs+'</p>',false);
                    Ext.getCmp('labelap-observateurs').setText( '<p>Observateur(s) : '+feature.data.observateurs+'</p>',false);
                    //chargement des valeur du formulaire
                    Ext.getCmp('edit-ap-form').getForm().loadRecord(feature);
                    //on limit le zoom à 9
                        var zoomLevel = map.getZoomForExtent(feature.geometry.getBounds());
                        var centerGeom = feature.geometry.getBounds().getCenterLonLat();
                        if (zoomLevel > 9){zoomLevel = 9;}
                        map.setCenter(centerGeom,zoomLevel);
                    //map.zoomToExtent(feature.geometry.getBounds());
                    Ext.getCmp('edit-ap-form').enable();
                    updatePerturbationsTree();
                    updatePhysionomiesTree();
                }
            }
        });
    };

    /**
     * Method: createStore
     * Create the search result store
     */
    var createStore = function() {
        store = new Ext.data.Store({
            reader: new mapfish.widgets.data.FeatureReader({}, [
                'indexap'
                ,'indexzp'
                ,{name:'dateobs', type: 'date', dateFormat:'d/m/Y'}
                ,'codepheno'
                ,'pdop'
                ,'taxon'
                ,'altitude'
                ,'surface'
                ,'id_frequence_methodo_new'
                ,'frequenceap'
                ,'nb_transects_frequence'
                ,'nb_points_frequence'
                ,'nb_contacts_frequence'
                ,'nb_placettes_comptage'
                ,'id_comptage_methodo'
                ,'effectif_placettes_comptage_sterile'
                ,'nbsterile'
                ,'effectif_placettes_comptage_fertile'
                ,'nbfertile'
                ,'surface_placette_comptage'
                ,'observateurs'
                ,'perturbations'
                ,'objets_a_compter'
                ,'codesper'
                ,'ids_physionomie'
            ])
            ,listeners: {
                load: function(store, records) {
                    Ext.getCmp('edit-ap-form').getForm().loadRecord(records[0]);
                }
            }
        });
    };

    /**
     * Method: resetWindow
     * Reset the different items status (on close) for next usage
     */
    var resetWindow = function() {
        indexap = null;
        map.zoomToMaxExtent();
        vectorLayer.removeFeatures(vectorLayer.features);
        Ext.getCmp('edit-ap-form').disable();
        Ext.getCmp('edit-ap-form').getForm().reset();
        dragPanControl.activate();
        if(Ext.getCmp('zp_count').text=="les 50 dernières prospections"){
            Ext.getCmp('hidden-start').setValue('yes')
            application.search.refreshZps();
        }
        Ext.getCmp('fieldset-2-pda').collapse();
        Ext.getCmp('fieldset-3-pda').collapse();
        Ext.getCmp('fieldset-4-pda').collapse();
        Ext.getCmp('fieldap-nb-transects').setValue(null);
        Ext.getCmp('fieldap-nb-points').setValue(null);
        Ext.getCmp('fieldap-nb-contacts').setValue(null);
        Ext.getCmp('fieldset-pda-fertiles').hide();
        Ext.getCmp('fieldset-pda-steriles').hide();
        Ext.getCmp('fieldap-effectifs-fertile').hide();
        Ext.getCmp('fieldap-effectifs-sterile').hide();
        Ext.getCmp('fieldap-nombre-placettes').hide();
        Ext.getCmp('fieldap-surface-placette').hide();
        Ext.getCmp('fieldap-effectifs-fertile').setValue(null);
        Ext.getCmp('fieldap-effectifs-sterile').setValue(null);
        Ext.getCmp('fieldap-fertile').setValue(null);
        Ext.getCmp('fieldap-sterile').setValue(null);
        Ext.getCmp('fieldap-nombre-placettes').setValue(null);
        Ext.getCmp('fieldap-surface-placette').setValue(null);
        Ext.getCmp('fieldap-altitude').setValue(0);
        Ext.getCmp('labelap-info-surface-reelle').setText('<p></p>',false);
        application.utils.manageDisplayField('fieldap-pente','hide');
        resetPerturbationsTree();
        resetPhysionomiesTree();
    };

    /**
     * Method: submitForm
     * Submits the form
     */
    var submitForm = function() {
        Ext.getCmp('apSaveButton').setText('Enregistrement en cours...');
        Ext.getCmp('fieldap-frequenceap').enable();
        Ext.getCmp('fieldap-fertile').enable();
        Ext.getCmp('fieldap-sterile').enable();
        var params = {};
        if (indexap) {
            params.indexap = indexap;
        }
        Ext.getCmp('edit-ap-form').getForm().submit({
            url: 'ap/save'
            ,params: params
            ,success: function(response) {
                application.search.refreshZps();
                if (indexzp) {
                    var index = 'zp-' + indexzp;
                    Ext.getCmp(index).refreshZp();
                    var tab = application.layout.tabPanel.getComponent(index);
                    tab.refreshAps();
                }
                // if (indexap) {
                    // var index = 'zp-' + Ext.getCmp('edit-ap-form').getForm().findField('indexzp').getValue();
                    // var tab = application.layout.tabPanel.getComponent(index);
                    // tab.refreshAps();
                // }
                Ext.getCmp('apSaveButton').setText('Enregistrer');
                application.editAp.window.hide();
            }
            ,failure: function(form, action) {
                Ext.getCmp('apSaveButton').setText('Enregistrer');
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
//------------------------------------formulaire de chargement des fichiers---------------------------------------------------
  var getUploadFileFormPanel = function(){
    var formUploadFile = new Ext.FormPanel({
      id: 'form-upload-ap-gpx'
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
                                        application.editAp.createGpxLayer();
                                        Ext.ux.Toast.msg('Téléchargement !', 'Fichier gpx a été télécharger, vous devez zommer sur la localisation de son contenu pour le voir sur la carte');
                                    }
                                    else{
                                        Ext.ux.Toast.msg('Attention !', 'Téléchargement du fichier gpx : <br>'+action.result.errors);
                                    }
                                    application.editAp.windowUploadFile.hide();
                                    
                            },
                            failure :  function(form, action) {
                                if(action.result.success==false){
                                    Ext.ux.Toast.msg('Attention !', 'Une erreur est survenue');
                                }
                                application.editAp.windowUploadFile.hide();
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
                    application.editAp.windowUploadFile.hide();
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
        ,initWindowUploadFile: function() {
                this.windowUploadFile = initFormUploadFile();
        }
        ,addGpx: function() {
            if (this.windowUploadFile){}
            if (!this.windowUploadFile) {this.initWindowUploadFile();}
            this.windowUploadFile.show();
        }
        
        /**
         * Method: loadAp
         * Loads a record from the aps list store
         */
        ,loadAp: function(ap, zp,monaction,bounds) {
            if (!this.window) {
                this.init();
            }
            this.window.show();
            indexzp = zp.data.indexzp;
            maMap = map;
            wmslayer = map.getLayersByName('overlay')[0];
            var zpSelected = new OpenLayers.Layer.WMS("zpselected"
                ,wms_uri
                ,{
                    layers: ['zp_Selected'],
                    transparent: true,
                    statuscode: application.user.statuscode,
                    indexzp: indexzp
                },
                {singleTile: true}
            );
            map.addLayers([zpSelected]);
            if (monaction=='update') {
                this.window.setTitle('Modification d\'une aire de présence');
                maLayer = vectorLayer;//debug
                if (ap) {
                    indexap = ap;
                    wmslayer.mergeNewParams({
                      indexap: indexap
                    });
                    wmslayer.setOpacity(0.25);
                    var options = {
                        url: ['ap/listone', indexap].join('/')
                        ,params: {format: 'geoJSON'}
                    };
                    eventProtocol.read(options);
                    newGeom = false;
                    Ext.getCmp('edit-ap-form').getForm().findField('monaction').setValue('update');
                    Ext.getCmp('fieldset-2-pda').expand();
                    Ext.getCmp('fieldset-3-pda').expand();
                    Ext.getCmp('fieldset-4-pda').expand();
                }
            }            
            if (monaction=='add') {
                activateControls(true);
                updateGeometryField(null);
                this.window.setTitle('Ajout d\'une nouvelle aire présence');
                Ext.getCmp('labelap-ap').setText( '<p class="redtext">Nouvelle aire de présence pour la prospection de</br> '+zp.data.taxon_latin+' du '+zp.data.feature.data.dateobs+'</p>',false);
                Ext.getCmp('labelap-observateurs').setText( '<p>Observateur(s) : '+zp.data.observateurs+'</p>',false);
                Ext.ux.Toast.msg('Attention !', 'Commencer par saisir l\'aire de présence sur la carte pour activer le formulaire');
                // forcer l'affichage de l'ortho
                Ext.getCmp('layer-tree-tip').nodeHash.layer_ortho.ui.toggleCheck(true);
                   
                if(Ext.getCmp('zp-layertreetip')){
                    Ext.getCmp('zp-layertreetip').toggle(false);
                }
                if(Ext.getCmp('search-layertreetip')){
                    Ext.getCmp('search-layertreetip').toggle(false);
                }
                //on zoom sur la zp mais on limit le zoom à 9 si la zp est trop petite
                var zoomLevel = map.getZoomForExtent(bounds);
                var centerGeom = bounds.getCenterLonLat();
                if (zoomLevel > 9){zoomLevel = 9;}
                map.setCenter(centerGeom,zoomLevel);
                //on gèere l'affichage des champs pour le comptage
                manageDisplayComptageFields(zp.data.feature);
                Ext.getCmp('edit-ap-form').getForm().findField('indexzp').setValue(indexzp);
                Ext.getCmp('edit-ap-form').getForm().findField('objets_a_compter').setValue(zp.data.objets_a_compter);
                newGeom = true;
                Ext.getCmp('edit-ap-form').getForm().findField('monaction').setValue('add');
                application.utils.manageDisplayField('fieldap-nb-transects','hide');
                application.utils.manageDisplayField('fieldap-nb-points','hide');
                application.utils.manageDisplayField('fieldap-nb-contacts','hide');
                resetPerturbationsTree();
                resetPhysionomiesTree(); 
            }
            wmslayer.mergeNewParams({
                  indexzp: indexzp
            });
        }
        
            /**
         * Method: createGpsLayer
         * Creates the vector gml layer
         *use : createGpxLayer("../uploads/test.gpx");
         * Return
         * <OpenLayers.Layer.Vector>
         */
         
        ,createGpxLayer: function() {
        if(map.getLayersByName('gps')[0]){
            map.getLayersByName('gps')[0].destroy();
            selcontrol.deactivate();
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
				map.zoomToExtent(dataExtent);
			};
            //identification de l'utilisateur dans le nom du gpx
            var reg=new RegExp("( )", "g");
            var gpxFile = application.user.nom.replace(reg,"_")
            vectorGpxLayer = new OpenLayers.Layer.Vector("gps",{
                protocol: new OpenLayers.Protocol.HTTP({
                    url:"http://dev.ecrins-parcnational.fr/flore/uploads/gpx/gpx_"+gpxFile+".gpx"
                    ,format: new OpenLayers.Format.GPX()
                })
                ,strategies: [new OpenLayers.Strategy.Fixed()]
                ,styleMap: styleMap
                ,projection: new OpenLayers.Projection("EPSG:4326")      
            });
            // This will perform the autozoom as soon as the GPX file is loaded.
            vectorGpxLayer.events.register("loadend", vectorGpxLayer, setExtent);
            map.addLayer(vectorGpxLayer);
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
			selcontrol = new OpenLayers.Control.SelectFeature(vectorGpxLayer, {
				onSelect: createPopup,
                hover:true,
				onUnselect: destroyPopup
			});
			map.addControl(selcontrol);
			selcontrol.activate();
        }
        
        ,changeLabel: function(fieldId, newLabel){
              var label = Ext.DomQuery.select(String.format('label[for="{0}"]', fieldId));
              if (label){
                label[0].childNodes[0].nodeValue = newLabel;
              }
        }
    }
}();
