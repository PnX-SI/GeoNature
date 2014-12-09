<?php
require_once dirname(__FILE__) . '/gjInterface.php';

class gjMultiLineString extends gjGeometry
{
    public $type = "MultiLineString";
	public $coordinates = array();
    
    public function addLineString(gjLineString $gjLinestring)
	{
		$this->coordinates[] = $gjLinestring->getCoordinates();
	}
}
?>