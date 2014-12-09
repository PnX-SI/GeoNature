<?php
/**
 * Use Services_GeoJson to export an array of db values with a geometry column to GeoJson
 * ... and throw away when asGeoJson is implemented in PostGis ;-) 
 *
 * The geometry column can either be a simple WKB or an extended WKB
 * Dump an EWKB if you wish to include the CRS in GeoJson (use asHexEWKB(the_geom)) -- still on the TODO list
 * Dump a simple, standards compliant, WKB if you don't care (use encode(asbinary(the_geom), 'hex'))
 *
 * Here are some hexadecimal string samples for point WKB:
 *
 * Hex EWKB for POINT(1 1) with 4326 SRID: (spaces have been added for clarity)
 * Little endian: 01 01000020 E6100000 000000000000F03F 000000000000F03F 
 * Big endian   : 01 20000001 000010E6 3FF0000000000000 3FF0000000000000
 *
 * Little endian Hex EWKB for a 3D point with another SRID : 
 * 01 010000A0 31BF0D00 2492200FF85A2741 62D1234609F15541 0038F8FFFF91AF40
 *
 * Little endian Hex WKB for POINT(0 -3):
 * 01 01000000 0000000000000000 00000000000008c0
 *
 * The GeoJson part of this package was greatly inspired from the exportGge CartoWeb plugin (GPL)
 * @author Loïc Devaux (loicdevaux at hotmail com)
 *
 * Services_GeoJson class was written from scratch 
 * (and still has to be thoroughly tested, especially on big endian machines).
 * @author François Van Der Biest (francois.vanderbiest at camptocamp com)
 */
 
require_once dirname(__FILE__) . '/geojson/gjInterface.php';

class Services_GeoJson
{
	const wkbXDR = '00'; // big endian
	const wkbNDR = '01'; // little endian

    // WKB Geometry Types:
	const wkbPoint = 1;
	const wkbLineString = 2;
	const wkbPolygon = 3;
	const wkbMultiPoint = 4;
	const wkbMultiLineString = 5;
	const wkbMultiPolygon = 6;
	const wkbGeometryCollection = 7;
    
    // by default, we expect a standard hex WKB:
    protected $extended = false; 
    protected $decode_string = 'dlon/dlat';
    protected $dimension = 2;
    // this boolean qualifies the machine on which the code runs:
    protected $little_endian_machine; 
    // this boolean qualifies the parsed data:
    protected $little_endian_data; 

    public function __construct()
    {
        // we detect the current machine endianness 
        // because unpacking doubles with PHP depends on machine type
        $array = unpack('ddouble', pack('H*', '000000000000F03F'));
        $this->little_endian_machine = ($array['double'] == 1);
    }

    /**
     * Encodes an array of inputs (representing a db query result set) into GeoJson, 
     * @param  array   $inputs such as array(array('id'=>1,'name'=>'one'),array('id'=>2,'name'=>'two'))
     * @param  string  $geom_column identifies the hexadecimal representation of a (E)WKB
     * @param  string  $id_column identifies (if needed) the key to indice features.
     * @param  boolean $extended whether we should expect an extended WKB or not (defaults to false)
     * @return string  GeoJson feature collection
     *
     * TODO: add the ability to return one feature
     */
    public function encode($inputs, $geom_column, $id_column = null, $extended = false)
    {
        if (!count($inputs)) return '{}';
        
        $this->extended = $extended;
        $collection = new gjFeatureCollection();
    
        foreach ($inputs as $input)
        {
            $start = 0;
            
            if (empty($id_column))
            {
                $feature = new gjFeature();
            }
            else
            {
                $feature = new gjFeature($input[$id_column]);
                //unset($input[$id_column]);
            }
            
            // compute geometry object from hexadecimal WKB value
            if (empty($input[$geom_column])) continue;
            $geometry = $this->computeGeometry($input[$geom_column], $start);
            $feature->setGeometry($geometry); 
            unset($input[$geom_column]);
            
            // compute properties (attributes)
            $stdClass = new stdClass();
            foreach ($input as $key => $value) $stdClass->$key=$value; 
            $feature->setProperties($stdClass);
            
            // add feature to collection
            $collection->addFeature($feature);
        }
        
        return json_encode($collection);
    }
    
    protected function computeGeometry($hwkb, $start)
    {
        switch (substr($hwkb, $start, 2))
        {
            case self::wkbNDR :
                $this->little_endian_data = true; 
                break;
            case self::wkbXDR :
                $this->little_endian_data = false; 
                break;
            default :
                // TODO: throw exception
                return;
        }
        $start += 2;
        
        $hexIntString = substr($hwkb, $start, 8);
        $start += 8;
        
        if ($this->extended)
        {
            $result = abs($this->applyLongIntMask($hexIntString, '000000FF'));
            $hasSRID = ($result == 536870912); // 0x20000000
            $hasM = ($result == 1073741824);   // 0x40000000
            $hasZ = ($result == 2147483648);   // 0x80000000
            
            $srid = ($hasSRID) ? $this->readLongInt($hwkb, $start) : 0;
            
            if ($hasZ)
            {
                $this->decode_string .= '/dele';
                $this->dimension += 1;
            }
            if ($hasM)
            {
                $this->decode_string .= '/dmsr';
                $this->dimension += 1;
            }
        }
        
        // TODO: if hasSRID, add a crs member to GeoJSON object.
        // see http://wiki.geojson.org/GeoJSON_draft_version_5#Specification
        
        $type = $this->applyLongIntMask($hexIntString, 'FF000000');
        
        switch ($type)
        {
            case self::wkbPoint :
                return $this->readPoint($hwkb, $start);
            
            case self::wkbLineString :
                return $this->readLineString($hwkb, $start);
            
            case self::wkbPolygon :
                return $this->readPolygon($hwkb, $start);
            
            case self::wkbMultiPoint : 
                $numPoints = $this->readLongInt($hwkb, $start);
                $geometry = new gjMultiPoint();
                
                for ($i = 0; $i < $numPoints; $i++)
                {
                    $start += 10; // to skip byteOrder + wkbType for each point
                    $gjPoint = $this->readPoint($hwkb, $start);
                    $geometry->addPoint($gjPoint);
                }
                
                return $geometry;
            
            case self::wkbMultiLineString :
                $numLineStrings = $this->readLongInt($hwkb, $start);
                $geometry = new gjMultiLineString();
                
                for ($i = 0; $i < $numLineStrings; $i++)
                {
                    $start += 10; 
                    $gjLineString = $this->readLineString($hwkb, $start);
                    $geometry->addLineString($gjLineString);
                }
                
                return $geometry;
            
            case self::wkbMultiPolygon :
                $numPolygons = $this->readLongInt($hwkb, $start);
                $geometry = new gjMultiPolygon();
                
                for ($i = 0; $i < $numPolygons; $i++)
                {
                    $start += 10;
                    $pg_geometry = $this->readPolygon($hwkb, $start);
                    $geometry->addPolygon($pg_geometry);
                }
                return $geometry;
            
            case self::wkbGeometryCollection :
                $numGeometries = $this->readLongInt($hwkb, $start);
                $geometry = new gjGeometryCollection();
                
                for ($i = 0; $i < $numGeometries; $i++)
                {
                    // TODO: check this works ... (recursion)
                    $tmp_geometry = $this->computeGeometry($hwkb, $start);
                    $geometry->addGeometry($tmp_geometry);
                }
                return $geometry;
        }
    }
    
    protected function switchEndianness($str)
    {
        return implode('', array_reverse(str_split($str, 2)));
        // TODO: throw error if mod(strlen($str), 2) != 0
    }
    
    // Data $hexIntString is expected in same endianness as input $hwkb
    // Mask $hexMaskString is expected in little endian style
    // Output data is an integer, result of mask application
    protected function applyLongIntMask($hexIntString, $hexMaskString) 
    {
        $binaryLongInt = pack('H*', $hexIntString);
        $format = 'V'; // unsigned long int (32 bits, little endian)
        if (!$this->little_endian_data)
        {
            $hexMaskString = $this->switchEndianness($hexMaskString);
            $format = 'N'; // unsigned long int (32 bits, big endian)
        }
        $binaryMask = pack('H*', $hexMaskString); 
        
        $array = unpack($format.'LongInt', $binaryLongInt & $binaryMask); 
        return $array['LongInt'];
    }
    
    protected function readLongInt($hwkb, $start)
    {
        $hexIntString = substr($hwkb, $start, 8);
        // format reader for unsigned long int: N if big endian - V if little endian
        $format = ($this->little_endian_data) ? 'V' : 'N'; 
        $array = unpack($format.'LongInt', pack('H*', $hexIntString)); 
        $start += 8;
        return $array['LongInt'];
    }
    
    protected function readLonLat($hwkb, $start)
    {
        $lon_hwkb = substr($hwkb, $start, 16);
        $lat_hwkb = substr($hwkb, $start + 16, 16);
        // we do not read anything else than lon and lat:
        $start += 16 * $this->dimension;
        
        if ($this->little_endian_machine != $this->little_endian_data) 
        {
            $lon_hwkb = $this->switchEndianness($lon_hwkb);
            $lat_hwkb = $this->switchEndianness($lat_hwkb);
        }
        $point_hwkb = $lon_hwkb . $lat_hwkb;
        
        return unpack($this->decode_string, pack('H*', $point_hwkb));
    }
    
    protected function readPoint($hwkb, $start)
    {
        $geometry = new gjPoint();
        $geometry->setXYFromArray($this->readLonLat($hwkb, $start));
        return $geometry;
    }    
    
    protected function readLineString($hwkb, $start)
    {
        $numPoints = $this->readLongInt($hwkb, $start);
        
        $geometry = new gjLineString();
        for ($i = 0; $i < $numPoints; $i++)
        {
            $geometry->addPointXYFromArray($this->readLonLat($hwkb, $start));
        }
        return $geometry;
    }
    
    protected function readPolygon($hwkb, $start)
    {
        $numRings = $this->readLongInt($hwkb, $start);
        
        // read first ring (exterior)
        $gjLineString = $this->readLineString($hwkb, $start);
        
        // add it to geojson object
        $geometry = new gjPolygon();
        $geometry->setExteriorRing($gjLineString);
        
        for ($j = 1; $j < $numRings; $j++)
        {
            // read each following internal LinearRing
            $gjLineString = $this->readLineString($hwkb, $start);
            $geometry->addHole($gjLineString);
        }
        return $geometry;
    }
    
}
?>
