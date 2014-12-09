<?php
require_once dirname(__FILE__) . '/gjInterface.php';

class gjMultiPolygon extends gjGeometry
{
    public $type = "MultiPolygon";
	public $coordinates = array();
    
    public function addPolygon(gjPolygon $gjPolygon)
	{
		$this->coordinates[] = $gjPolygon->getCoordinates();
	}
}
?>