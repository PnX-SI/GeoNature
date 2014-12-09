<?php
require_once dirname(__FILE__) . '/gjInterface.php';

class gjLineString extends gjGeometry
{
    public $type = "LineString";
	public $coordinates = array();
	
	public function addPointXY($x, $y)
	{
		$this->coordinates[] = array($x, $y);
	}
    
	public function addPointXYFromArray($a)
	{
		$this->coordinates[] = array($a['lon'], $a['lat']);
	}
	
	public function getCoordinates()
	{
		return $this->coordinates;
	}
	
}
?>