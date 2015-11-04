<!-- TODO : CSS à basculer dans css/main.css -->
<style type="text/css">
  body {
    margin: auto; 
    font-family: Arial; 
    font-size: 14px;
  }
  h1 {
    font-weight: bold; 
    text-align: center; 
    font-size: 3em; 
    margin: 30px 0px; 
    line-height: 100%;
  }
  #bandeau_accueil {
    background: url("images/bandeau_geonature.jpg") no-repeat;;
    height: 60px;
  }
  #container {
    max-width: 1024px;
    margin: 10px auto;
    padding: 10px;
    box-shadow: 0 0 3px #000;
  }
  .bloc_accueil {
    color: #FFFFFF;
    background: linear-gradient(90deg, #f09819 30%, #edde5d 90%) repeat scroll 0 0 rgba(0, 0, 0, 0);
    letter-spacing: 5px;
    font-weight: bold;
    text-shadow: 0 0 3px #000;
    height: 25px;
  }
  .bloc_accueil .centre { 
      vertical-align:middle;
      display:inline-block;
  }
  .contenu_bloc {
    margin-bottom:20px
  }
  .contenu_bloc a {
    text-decoration: none;
  }
  .ligne_lien{
    margin:10px 0 0 30px;
  }
</style>


<body>
    <div id="bandeau_accueil"></div>
    <h1><?php echo sfGeonatureConfig::$apptitle_main; ?></h1>
    <div id="container">
  
        <div class="bloc_accueil">
            <img src="images/logo_pag.png" height="25px"> <span class="centre">CONSULTATION</span>
        </div>
        <div class="contenu_bloc">  
            <p>
                Pour consulter la synthèse des observations faune et flore, tous protocoles confondus.
            </p>
            <p class="ligne_lien">
                <img src="images/pictos/oiseau.gif"> <a href="synthese">Synthèse des observations</a>
            </p>
        </div>
        
        <div class="bloc_accueil">
            <img src="images/logo_pag.png" height="25px"> <span class="centre">SAISIE</span>
        </div>
        <div class="contenu_bloc">
            <p>
                Pour saisir de nouvelles données, vous pouvez utiliser l'un des liens ci-dessous.<br/>
                Pour modifier des données saisies à l'aide d'un des formulaires proposés en lien ci-dessous, vous devez passer par la synthèse pour retrouver les enregistrements à modifier.
            </p>
            <p>
                <? echo $liens_saisie;?>
            </p>
        </div>
        <!-- BLOC DE STATS PNE NON AFFICHES. A REINTEGRER SOUS FORME DE IFRAME CUSTOMISABLE ?
        <div id="bande_consultation" style="color:#FFFFFF;background: linear-gradient(90deg, #f09819 30%, #edde5d 90%) repeat scroll 0 0 rgba(0, 0, 0, 0);letter-spacing:5px;font-weight:bold;text-shadow:0 0 3px #000;height:25px;">
            <div style="vertical-align:middle;display:inline-block;"><img src="images/logo_pag.png" border="0" width="25px" height="25px"></div>
            <div style="vertical-align:middle;display:inline-block;">STATISTIQUES</div>
        </div>
        <div>
            <div id="header">
                <h2>Utilisation des outils de saisie Faune</h2>
            </div>
            <div id="content">
                <div id="header">
                    <h3>Cumul des observations selon le mode de saisie</h3>
                </div>
                <div class="demo-container">
                    <p>Faune vertébrée</p>
                    <div id="placeholder1" class="demo-placeholder"></div>
                </div>             
                <div class="demo-container">
                    <p>Faune invertébrée</p>
                    <div id="placeholder3" class="demo-placeholder"></div>
                </div>

                <br/>
                <div id="header">
                    <h3>Evolution du nombre d'espèces vues ou à rechercher</h3>
                </div>
                <div class="demo-container">
                    <p>Faune vertébrée</p>
                    <div id="placeholder2" class="demo-placeholder"></div>
                </div>
                
                <div class="demo-container">
                    <p>Faune invertébrée</p>
                    <div id="placeholder4" class="demo-placeholder"></div>
                </div>
            </div>
        </div>
        -->
    </div>
 </body>
