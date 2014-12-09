<?php
require_once dirname(__FILE__) . '/gjInterface.php';

class gjPolygon extends gjGeometry
{
    public $type = "Polygon";
	public $coordinates = array();
	
	public function setExteriorRing(gjLineString $gjLineString)
	{
		$this->coordinates[0] = $gjLineString->getCoordinates();
	}
    
	public function addHole(gjLineString $gjLineString)
	{
		if (count($this->coordinates) > 0)
		{
			$this->coordinates[] = $gjLineString->getCoordinates();
		}
		else
		{
			$this->coordinates[0] = null;
			$this->coordinates[1] = $gjLineString->getCoordinates();
		}
	}
    
    public function getCoordinates()
	{
		return $this->coordinates;
	}
}
?>