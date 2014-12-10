<?php
/**
 * Search class has been greatly inspired from search.py module
 */

class Search
{
    const EPSG = 4326;
    const UNITS = 'degrees';
    
    public function __construct($idColumn, $geomColumn, $extended = false, $epsg = self::EPSG, $units = self::UNITS)
    {
        $this->idColumn = $idColumn;
        $this->geomColumn = $geomColumn;
        $this->extended = $extended; // do we have to fetch an Extended WKB or a standard WKB ?
        $this->epsg = $epsg; // this is the epsg code for the data in db
        $this->units = $units;
        $this->limit = null;
    }
    
    public function buildQuery($paramHolder, $model) 
    {
        // default epsg for i/o communication is 4326.
        $epsg = self::EPSG;
        // can be overriden by epsg GET param:
        if ($paramHolder->has('epsg')) 
            $epsg = $paramHolder->get('epsg');
        
        $m = new $model();
        $table_name = $m->getTable();
        
        // max features requested
        if ($paramHolder->has('maxfeatures'))
            $this->limit = $paramHolder->get('maxfeatures');
        
        // if requested i/o epsg code ($epsg) and data in db ($this->epsg) match
        $geom_field = ($epsg == $this->epsg) ? 
                            'm.' . $this->geomColumn : 
                            'st_transform(m.' . $this->geomColumn . ', '.$epsg.')';

        $select_string = ($this->extended) ? 
                            "st_ashexewkb($geom_field) " . $this->geomColumn:
                            "encode(st_asbinary($geom_field), 'hex') " . $this->geomColumn;
        
        $q = new Doctrine_Query();
        Doctrine_Manager::getInstance()->getCurrentConnection()
                                       ->setAttribute(Doctrine::ATTR_PORTABILITY, 
                                            Doctrine::PORTABILITY_ALL ^ Doctrine::PORTABILITY_EXPR);
                                            
        if ($paramHolder->has('lon') && $paramHolder->has('lat') && $paramHolder->has('radius'))
        {
            // deal with lonlat query
            $lon = floatval($paramHolder->get('lon'));
            $lat = floatval($paramHolder->get('lat'));
            $radius = floatval($paramHolder->get('radius'));
            
            $point = ($epsg == $this->epsg) ? 
                            " (st_GeometryFromText('POINT($lon $lat)', $epsg ))" :
                            " (st_Transform(st_GeometryFromText('POINT($lon $lat)', $epsg ), " . $this->epsg . '))';
                            
            $sql = 'SELECT ' . $this->idColumn . ' FROM ' . $table_name;
            if ($radius > 0)
            {
                if ($this->units == 'degrees') 
                    $sql .= " WHERE st_distance_sphere( $point, " . $this->geomColumn . " ) < $radius";
                else
                    $sql .= " WHERE st_distance( $point, " . $this->geomColumn . " ) < $radius";
            }
            else
            {
                $sql .= " WHERE st_within( $point, " . $this->geomColumn . ' )';
            }
            
            $results = Doctrine_Manager::connection()->standaloneQuery($sql)->fetchAll();
            if (!empty($results))
            {
                $_ids = array();
                foreach ($results as $result) $_ids[] = $result[$this->idColumn];
                $q->addWhere($this->idColumn . ' IN ( '.implode(', ', $_ids).' )');
            }
        }
        elseif ($paramHolder->has('box')) 
        {
            // because we lack the ability to build queries based on geometries with this ORM,
            // we build a standalone query which returns the ids of the geometrically matching features
            // ... based on box and optional epsg parameters in request
            // this performs far less, but it works ...
            $coords = explode(',', urldecode($paramHolder->get('box')));
            $pointA = (floatval($coords[0]) . ' ' . floatval($coords[1]));
            $pointB = (floatval($coords[0]) . ' ' . floatval($coords[3]));
            $pointC = (floatval($coords[2]) . ' ' . floatval($coords[3]));
            $pointD = (floatval($coords[2]) . ' ' . floatval($coords[1]));
            $polygon = "POLYGON((".$pointA.', '.$pointB.', '.$pointC.', '.$pointD.', '.$pointA."))";
            
            $sql = 'SELECT ' . $this->idColumn . ' FROM ' . $table_name . ' WHERE '. $this->geomColumn;
            $sql .= ($epsg == $this->epsg) ? 
                            " && (st_GeometryFromText('$polygon', $epsg ))" :
                            " && (st_Transform(st_GeometryFromText('$polygon', $epsg ), " . $this->epsg . '))';
                         
            $results = Doctrine_Manager::connection()
                        ->standaloneQuery($sql)
                        ->fetchAll();
                        
            if (!empty($results))
            {
                $_ids = array();
                foreach ($results as $result) $_ids[] = $result[$this->idColumn];
                $q->addWhere($this->idColumn . ' IN ( '.implode(', ', $_ids).' )');
            }
            else
            {
                $q->addWhere($this->idColumn . ' IN ( null )');
            }
        }
        
        $q->select($select_string);
        
        return $q;
    }
    
    public function query($model, $fields, Doctrine_Query $query)
    {        
        $select_string = 'm.' . implode(', m.', $fields);
        
        $query->from("$model m")->addSelect($select_string);
        
        if (!empty($this->limit)) 
            $query->limit($this->limit);

        $results = $query->execute(array(), Doctrine::HYDRATE_ARRAY);
        
        if (in_array($this->geomColumn, $fields) || ($fields == array('*')))
            unset($results[$this->geomColumn]);
        
        return $results;
    }
    
}
