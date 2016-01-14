<body>
<div id="home">
    
    <div class="jumbotron">
        <div id="bandeau_accueil"></div>
        <h1 id="home_title" ><small class="text-muted"><?php echo sfGeonatureConfig::$apptitle_main; ?></small></h1>
    </div>
    <div id="accueil" class="container">

        <h2>SYNTHÈSE</h2>
            <p>Pour consulter la synthèse des observations faune et flore, tous protocoles confondus.</p>
            <p class="ligne_lien">
                 <a href="synthese" class="btn btn-default"><img src="images/pictos/oiseau.gif">Synthèse des observations</a>
            </p>
            <div id="interligne50"></div>
            
        <h2>PROTOCOLES</h2>
            <p>
                Pour saisir de nouvelles données, vous pouvez utiliser l'un des liens ci-dessous.<br/>
                Pour modifier des données saisies à l'aide d'un des formulaires proposés en lien ci-dessous, vous devez passer par la synthèse pour retrouver les enregistrements à modifier.
            </p>
            <p>
                <?php echo $liens_saisie;?>
            </p>

        <h2>STATISTIQUES</h3>
            <div class="row" style="border:1px solid #ddd;">
                <div class="col-xs-12 col-sm-6 col-md-6 col-lg-4 col-lg-offset-1 text-center">
                    <h3 class="text-primary text-center">Règnes</h3>
                    <label class="label label-success">Nombre d'observations</label>
                    <div id="kd-chart" style="height: 250px;" ></div>
                </div>
                <div class="col-xs-12 col-sm-6 col-md-6 col-lg-4 col-lg-offset-1 text-center">
                    <h3 class="text-primary text-center">Classes animales</h3>
                    <label class="label label-success">Nombre d'observations</label>
                    <div id="cl-chart" style="height: 250px;" ></div>
                </div>
            </div>
        
        <footer>
            <h5>
            <small>
                <a href="https://github.com/PnEcrins/GeoNature/" target="_blank">GeoNature</a>
                , développé par le 
                <a href="http://www.ecrins-parcnational.fr" target="_blank">
                Parc national des Ecrins</a>
            </small>
            <a class="pull-right" href="deconnexion"><img src="images/logout.gif" title="Déconnexion"/></a>
            </h5>
        </footer>
        
    </div>
</div>
<script>
var constructDatas = function(arr) {
    var datas = [];
    var item;
    for(var i=0; i<arr.length ; i++){
        if(arr[i][0] !=null){
            item = {value: arr[i][1], label: arr[i][0]};
            datas.push(item);
        }
    }
    return datas;
};
var constructDonuts = function(datas,div) {
    return new Morris.Donut({
        element: div
        ,data: datas
        ,backgroundColor: '#ccc'
        ,labelColor: '#666699'
        ,colors:['#f2e5ff','#e5ccff','#d9b3ff','#cc99ff','#bf80ff','#bf80ff','#b266ff','#a64dff','#9933ff','#8c1aff','#7f00ff','#7300e6','#6600cc','#5900b3','#4c0099','#400080','#330066','#26004d','#190033','#0d001a']
        ,formatter: function (x) { return x }
    });
};
function onDataReceived1(series) {
    var datas = constructDatas(series);
    constructDonuts(datas,'kd-chart');  
};
function onDataReceived2(series) {
    var datas = constructDatas(series);
    constructDonuts(datas,'cl-chart');   
};
//on lance la requête ajax
$.ajax({
    url: 'datasnbobskd'
    ,type: "GET"
    ,dataType: "json"
    ,success: onDataReceived1
});
$.ajax({
    url: 'datasnbobscl'
    ,type: "GET"
    ,dataType: "json"
    ,success: onDataReceived2
});

</script>
 </body>
