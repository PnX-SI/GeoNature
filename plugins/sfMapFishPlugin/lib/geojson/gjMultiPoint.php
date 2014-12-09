<?php
require_once dirname(__FILE__) . '/gjInterface.php';

class gjMultiPoint extends gjGeometry
{
    public $type = "MultiPoint";
	public $coordinates = array();
    
    public function addPointXYFromArray($a)
	{
        $_a[] = $a['lon'];
        $_a[] = $a['lat'];
		$this->coordinates[] = $_a;
	}
    
    public function addPointXY($x, $y)
	{
        $_a[] = $x;
        $_a[] = $y;
		$this->coordinates[] = $_a;
	}
    
    public function addPoint(gjPoint $gjPoint)
	{
		$this->coordinates[] = $gjPoint->getCoordinates();
	}
}
?>