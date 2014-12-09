<?php 

/**
 * Geometry base class
 *
 */
interface mfGeometry
{
	const GEOMETRY = 0;
	const FEATURE = 1;
	const FEATURECOLLECTION = 2;
	
	/**
	 * Returns current geometry type
	 * 
	 * @return constant
	 */
	abstract public function getGeometryType() ;
	
}