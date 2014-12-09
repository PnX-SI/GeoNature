<?php
require_once dirname(__FILE__) . '/gjInterface.php';

class gjFeatureCollection extends gjObject
{
    public $type = "FeatureCollection";
	public $features = array();
	
    public function addFeature(gjFeature $gjFeature)
	{
		$this->features[] = $gjFeature;
	}

}
?>