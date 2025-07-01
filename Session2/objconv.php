#! /usr/bin/php
<?php

if (isset($argv[2]))
{
    $scale = intval($argv[2]);
    $nscale = $scale;
}
else
{
    $scale = 10000;
    $nscale = 1000;
}

if (isset($argv[3]))
{
    $nscale = intval($argv[3]);
}

if (!isset($argv[1])) die ("OBJ-filename missing.\nusage: $argv[0] <object filename> [<vertex scale>] [<normal scale>] \n");
$obj = file($argv[1]);

$tgt = pathinfo($argv[1]);
$tgt = $tgt["filename"].".inc";
echo "ultimate object conversion script by Proton/Complex.\n";

$vertices = [];
$normals = [];
$faces = [];
$lights = [];
$vertex = 0;
$normal = 0;
$face = 0;
$output = "";

foreach ($obj as $row)
{
    $data = explode(" ",$row);
    if ($data[0] == "v") {
        $vx = trim($data[1]);
        $vy = trim($data[2]);
        $vz = trim($data[3]);
        $v = [intval($vx*$scale),intval($vy*$scale),intval($vz*$scale)];
        $vertices[$vertex++] = $v;
    }
    if ($data[0] == "vn") {
        $nx = trim($data[1]);
        $ny = trim($data[2]);
        $nz = trim($data[3]);
        $n = [intval($nx*$nscale),intval($ny*$nscale),intval($nz*$nscale)];
        $normals[$normal++] = $n;
    }
    if ($data[0] == "f") {
        $data1 = explode("/",$data[1]);	//edge 1
        $vertex1 = $data1[0];
        $norm1 = $data1[2];
        $data2 = explode("/",$data[2]);	//edge 2
        $vertex2 = $data2[0];
        $norm2 = $data2[2];
        $data3 = explode("/",$data[3]); //edge 3
        $vertex3 = $data3[0];
        $norm3 = $data3[2];
        $fv1 = trim($vertex1)-1;
        $fv2 = trim($vertex2)-1;
        $fv3 = trim($vertex3)-1;
        $lv1 = trim($norm1)-1;	// one normal per point
        $lv2 = trim($norm2)-1;
        $lv3 = trim($norm3)-1;
        $f = [$fv1,$fv2,$fv3,$lv1,$lv2,$lv3];
        $faces[$face++] = $f;
    }
}

$output .= "; OBJ: $argv[1]\n";
$output .= "; Vertices: $vertex\n";
$output .= "; Normals: $normal\n";
$output .= "; Surfaces: $face\n";
 
$output .= "      dc.l    .obj_vertices\n";
$output .= "      dc.l    .obj_normals\n";
$output .= "      dc.l    .obj_faces\n";
$output .= "      dc.w    $vertex ; num vertices\n";
$output .= "      dc.w    $normal ; num normals\n";
$output .= "      dc.w    $face ; num surfaces\n";

$output .= ".obj_vertices:\n";
foreach ($vertices as $_) 
{
    $output .= "      dc.w $_[0],$_[1],$_[2] \n";
}
$output .= ".obj_normals:\n";
foreach ($normals as $_) 
{
    $output .= "      dc.w $_[0],$_[1],$_[2] \n";
}
$output .= ".obj_faces:\n";
$output .= "; vtx1,vtx2,vtx3,norm1,norm2,norm3\n";
foreach ($faces as $_) 
{
    $output .= "      dc.w 0,0,$_[0],$_[1],$_[2],$_[3],$_[4],$_[5] \n";
}

file_put_contents($tgt,$output);
echo "Wrote objectfile: $tgt\n";
