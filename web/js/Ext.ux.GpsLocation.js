/**
 * @class Ext.ux.GpsLocation
 * Fenêtre pour le positionnement à partir de coordonnées fournies (GPS par exemple) 
 * Gil DELUERMOZ 2014
 * @singleton
 */
Ext.ux.GpsLocation = function() {
    var default_projection = new OpenLayers.Projection("EPSG:4326");
    var userProjection = default_projection;    
    var fuseau = '';
    var zone = '';
    var consigneExemple = '';
    var msgInfo = '';
    var xmin = x_min;
    var xmax = x_max;
    var ymin = y_min;
    var ymax = y_max;
    var xex = x_exemple;
    var yex = y_exemple;
    
    var pnNameLong = pn_name_long;
    var setProjection = function(){
        if (userProjection.proj.projName=='utm'){
            fuseau = userProjection.proj.zone;
            zone = fuseau;
            consigneExemple = 'fuseau '+fuseau;
        }
        else{
            consigneExemple = '';
        }
        var geomin = new OpenLayers.Geometry.Point(x_min, y_min);
        var geomax = new OpenLayers.Geometry.Point(x_max, y_max);
        var geomexemple = new OpenLayers.Geometry.Point(x_exemple, y_exemple);
        OpenLayers.Projection.transform(geomin,default_projection,userProjection);
        OpenLayers.Projection.transform(geomax,default_projection,userProjection);
        OpenLayers.Projection.transform(geomexemple,default_projection,userProjection);
        xmin = geomin.x; Ext.getCmp('gps-fiche-longitude').setMinValue(xmin);
        xmax = geomax.x; Ext.getCmp('gps-fiche-longitude').setMaxValue(xmax);
        ymin = geomin.y; Ext.getCmp('gps-fiche-latitude').setMinValue(ymin);
        ymax = geomax.y; Ext.getCmp('gps-fiche-latitude').setMaxValue(ymax);
        xex = geomexemple.x;
        yex = geomexemple.y;
        if(userProjection.proj.units != 'degrees'){
            xmin = Math.round(xmin);
            xmax = Math.round(xmax);
            ymin = Math.round(ymin);
            ymax = Math.round(ymax);
            xex = Math.round(xex);
            yex = Math.round(yex);
        }
        var msgInfo = 'Les coordonnés doivent être en '+userProjection.proj.title+'('+userProjection.projCode+'). <br/>X min = '+xmin+'. X max = '+xmax+'.<br/> Y min = '+ymin+'. Y max = '+ymax+'. <br/>Exemple '+consigneExemple+': X = '+xex+' ;  Y = '+yex;
        Ext.getCmp('gps-info').setText(msgInfo,false);
    };
    
    
    var projectionsStore = new Ext.data.JsonStore({
        data: gps_user_projections
        ,fields: [
            'id_proj'
            ,'nom_projection'
            ,'ol_projection'
        ]
        ,sortInfo: {
            field: 'id_proj'
            ,direction: 'ASC'
        }
        ,autoLoad:true
    });
    
    var submitFormGps = function(layer, longitude, latitude, mapProjection, userProjection) {
        if(Ext.getCmp('form-gps-fiche').getForm().isValid()){
            // création du point et reprojection grace à proj4js;
            //La lib pro4js est nécessaire
            //il faut aussi créer les defs comme par exemple EPSG32622.js dans un répertoire proj4js/defs
            //Les 2 projections nécessaires pour le transform sont définies au moment de la création de la fenêtre GSP sinon il y a un pb de timeout et la reprojection n'a pas le temps de se faire ???
            var features = [];
            var projSource = userProjection;
            var mageometry = new OpenLayers.Geometry.Point(longitude, latitude);
            OpenLayers.Projection.transform(mageometry,projSource,mapProjection);
            var mafeature = new OpenLayers.Feature.Vector(mageometry);
            features.push(mafeature);
            map.setCenter(new OpenLayers.LonLat(mageometry.x, mageometry.y),15); //on centre et on zoome avant d'ajouter le point sinon ajout impossible si echelle de zoom insuffisante voir events.on('featureadded'...
            layer.addFeatures(features);
            layer.redraw();
            Ext.getCmp('window-gps').destroy();
        }
        else{
            Ext.Msg.alert('Attention', 'Une information est mal saisie ou n\'est pas valide.</br>Vous devez la corriger avant de poursuivre.');
        }
    };
    
    return{
        initGpsWindow : function(layer) {
            var mapProjection = map.getProjectionObject();           
            return new Ext.Window({
                id:'window-gps'
                ,layout:'border'
                ,height:250
                ,width: 400
                ,closeAction:'hide'
                ,autoScroll:true
                ,modal: true
                ,plain: true
                ,split: true
                ,buttons: [{
                    text:'Positionner'
                    ,id:'gps-afficher-button'
                    ,handler: function(){
                        var longitude, latitude;
                        // zone = Ext.getCmp('gps-fiche-zone').getValue();
                        longitude = Ext.getCmp('gps-fiche-longitude').getValue();
                        latitude = Ext.getCmp('gps-fiche-latitude').getValue();
                        submitFormGps(layer, longitude, latitude, mapProjection, userProjection);   
                    }
                },{
                    text: 'Annuler et fermer'
                    ,handler: function(){
                        Ext.getCmp('window-gps').destroy();
                        Ext.ux.Toast.msg('Annulation !', 'Aucun point n\'a été positionné.');
                    }
                }]
                ,items: [
                    {
                        id:'form-gps-fiche'
                        ,xtype: 'form'
                        ,title: 'Positionnement d\'un point à partir de coordonnées fournies'
                        ,region: 'center'
                        ,labelWidth: 100
                        ,frame:true
                        ,border:false
                        ,split: false
                        ,autoScroll:false
                        ,monitorValid:true
                        ,bodyStyle:'padding:5px 5px 0'
                        ,width: 350
                        ,defaultType: 'numberfield'
                        ,items: [
                            {
                                id:'combo-projection'
                                ,xtype:"twintriggercombo"
                                ,fieldLabel: 'Projection '
                                ,name: 'projection'
                                ,hiddenName:"ol_projection"
                                ,emptyText: "Choisir un système de coordonnées"
                                ,store: projectionsStore
                                ,valueField: "ol_projection"
                                ,displayField: "nom_projection"
                                ,typeAhead: true
                                ,forceSelection: true
                                ,selectOnFocus: true
                                ,editable: false
                                ,triggerAction: 'all'
                                ,trigger3Class: 'x-form-zoomto-trigger x-hidden'
                                ,mode: 'local'
                                ,listeners: {
                                    expand: function(combo, record) {
                                        combo.getStore().sort('id_proj','ASC');
                                    }
                                    ,select: function(combo, record, index){
                                        userProjection = record.data.ol_projection;
                                        setProjection();                                    
                                    }
                                }
                            }
                            ,{
                                id: 'gps-fiche-longitude'
                                ,xtype: 'numberfield'
                                ,allowDecimals :true
                                ,decimalPrecision:6
                                ,decimalSeparator:'.'
                                ,allowNegative: true
                                ,disabled:false
                                ,fieldLabel: 'X'
                                ,minValue:xmin
                                ,minText:'Cette coordonnée en x n\'est pas valide pour l\'emprise de la carte. Voir le xmin ci-dessous'
                                ,maxValue:xmax
                                ,maxText:'Cette coordonnée en x n\'est pas valide pour l\'emprise de la carte. Voir le xmax ci-dessous'
                                ,allowBlank:false
                                ,blankText: 'La coordonnée en x est obligatoire.'
                                ,name: 'longitude'
                                ,width: 150
                            },{
                                id: 'gps-fiche-latitude'
                                ,xtype: 'numberfield'
                                ,allowDecimals :true
                                ,allowNegative: true
                                ,decimalPrecision:6
                                ,decimalSeparator:'.'
                                ,disabled:false
                                ,fieldLabel: 'Y'
                                ,minValue:ymin
                                ,minText:'Cette coordonnée en y n\'est pas valide pour l\'emprise de la carte. Voir le ymin ci-dessous'
                                ,maxValue:ymax
                                ,maxText:'Cette coordonnée en y n\'est pas valide pour l\'emprise de la carte. Voir le ymax ci-dessous'
                                ,allowBlank:false
                                ,blankText: 'La coordonnée en y est obligatoire.'
                                ,name: 'latitude'
                                ,width: 150
                            }
                            ,{
                                id: 'gps-info'
                                ,xtype: 'label'
                                ,text: msgInfo
                            }
                        ]
                        ,listeners: {
                            clientvalidation:function(form,valid){
                                if(valid){Ext.getCmp('gps-afficher-button').enable();}
                                else{Ext.getCmp('gps-afficher-button').disable();}
                            }
                        }
                    }
                ]
                ,listeners: {
                    hide:function(){this.destroy();}
                } 
            });
            setProjection();
        }
    }
}();