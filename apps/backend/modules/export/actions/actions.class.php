<?php
class exportActions extends sfGeonatureActions
{
    private static function zipemesfichiers($zip,$filename)
    {
        $fp = fopen ($filename, 'r');
        $content = fread($fp, filesize($filename));
        fclose($fp);
        $zip->addfile($content, $filename);
        return $zip;
    }
    public function executeExportView(sfRequest $request)
    {
        $pgview =$request->getParameter('pgschema').'.'.$request->getParameter('pgview');
        $rows = SyntheseffTable::exportsView($pgview);
        if ($request->getParameter('fileformat')=="csv" || $request->getParameter('fileformat') == "xls"){
            $file_format = $request->getParameter('fileformat');
            $file_separator = "\t";
        }else{
            $file_format = "csv";
            $file_separator = ";";
        }
        $output_content = '';
        //ligne d'entête csv
        $keys = array_keys($rows[0]); 
        foreach ($keys as $key)
        {
            $output_content .= $key.$file_separator;
        }
        $output_content .= "\n";
        //une ligne par enregistrement
        foreach ($rows as $row)
        {
            $values = array_values($row);
            foreach ($values as $value)
            {
                $output_content .= str_replace( array( CHR(10), CHR(13), "\n", "\r" ), array( ' - ',' - ',' - ',' - '), $value).$file_separator;
            }
            $output_content .= "\n";
        }
        //create csv file
        $csv_name = "uploads/exports/".$request->getParameter('pgview')."_".date("Y-m-d_His").'.'.$file_format;
        $filename = fopen($csv_name, 'w');
        if($file_format == "xls"){$output_file = utf8_decode($output_content);}
        else{$output_file = $output_content;}
        fwrite($filename, $output_file);
        fclose($filename);
        //create zipfile
        $zip = new ZipArchive();
        $zip_name="uploads/exports/".$request->getParameter('pgview')."_".date("Y-m-d_His").".zip"; // path of the file.
        $zip->open($zip_name, ZIPARCHIVE::CREATE);
        $zip->addFile($csv_name,basename($csv_name));
        $zip->close();
        // push to download the zip
        // output data to the browser
        header('Content-Type: application/x-zip');      
		header('Content-Disposition: inline; filename='.$zip_name);
        readfile($zip_name);
        // remove zip and csv files
        unlink($zip_name);
        unlink($csv_name);
        exit;
    }
}
