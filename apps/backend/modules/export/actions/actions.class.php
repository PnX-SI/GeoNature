<?php
class exportActions extends sfGeonatureActions
{
    public function preExecute()
    {
        sfContext::getInstance()->getConfiguration()->loadHelpers('Partial');
        ini_set("memory_limit",'512M');
    }
    public function executeIndexExport(sfRequest $request)
    {
        if($this->getUser()->isAuthenticated()){
            $unserializeviewparams = unserialize($request->getParameter('exportparams'));
            $this->title = $unserializeviewparams['exportname'].' - '.sfGeonatureConfig::$appname_export;
            slot('title', $this->title);
            $this->lienscsv = '';
            $views = $unserializeviewparams['views'];
            foreach($views as $view)
            {
                $pgview = $view['pgschema'].'.'.$view['pgview'];
                $rows = SyntheseffTable::exportsCountRowsView($pgview);
                $nb = $rows[0]['nb'];
                $this->lienscsv .= '<p class="ligne_lien"><a href="../export/exportview?pgschema='.$view['pgschema'].'&pgview='.$view['pgview'].'&fileformat='.$view['fileformat'].'" class="btn btn-default"><img src="../images/exporter.png">'.$view['buttonviewtitle'].' ('.$nb.')</a> '.$view['viewdesc'].'</p>';
            }
        }
        else{
           $this->redirect('@login');
        }
    }
    public function executeExportView(sfRequest $request)
    {
        $pgview =$request->getParameter('pgschema').'.'.$request->getParameter('pgview');
        $rows = SyntheseffTable::exportsView($pgview);
        if ($request->getParameter('fileformat')=="csv" || $request->getParameter('fileformat') == "xls"){
            $file_format = $request->getParameter('fileformat');
            if ($request->getParameter('fileformat') == "xls"){$file_separator = "\t";}
            else{$file_separator = ";";}
        }
        else{
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
