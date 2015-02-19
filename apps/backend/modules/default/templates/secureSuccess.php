<?php use_helper('Url') ?>

  <h2 style="color:#FFFFFF;font-family:Arial;letter-spacing:2px;margin-top:35px;text-align:center;text-shadow:0 0 3px #555555;">
   GeoNature
  </h2> 

  <div id="success">
    Vous n'avez pas les droits nécessaires pour accéder à cette page.
    <br/><br/><br/>
    <a href="<?php echo url_for('@logout')?>">Vous devez vous identifier de nouveau</a>
  </div>

  <div id="reflectSuccess"></div>