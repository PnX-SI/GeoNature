<?php
require_once dirname(__FILE__) . '/gjInterface.php';

class gjPoint extends gjGeometry
{
    public $type = "Point";
	public $coordinates = array();
	
	public function setXY($x,$y)
	{
		$this->coordinates[] = $x;
		$this->coordinates[] = $y;
	}
    
	public function setXYFromArray($a)
	{
		$this->coordinates[] = $a['lon'];
		$this->coordinates[] = $a['lat'];
	}    
    
    public function getCoordinates()
	{
		return $this->coordinates;
	}
}
?>