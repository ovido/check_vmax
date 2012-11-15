<?php
#
# Plugin: check_vmax
# Author: Rene Koch <r.koch@ovido.at>
# Date: 2012/11/15
#

$opt[1] = "--vertical-label \"Thin pool utilization\" -l 0 --title \"Thin pool utilization for $hostname\" --slope-mode -N -u 100";
$def[1] = "";

# process thin pool usage statistics
foreach ($this->DS as $key=>$val){
  $ds = $val['DS'];
  $def[1] .= "DEF:var$key=$RRDFILE[$ds]:$ds:AVERAGE ";
  $def[1] .= "LINE1:var$key#" . color() . ":\"" . $LABEL[$ds] ."      \" ";
  $def[1] .= "GPRINT:var$key:LAST:\"last\: %3.4lg%% \" ";
  $def[1] .= "GPRINT:var$key:MAX:\"max\: %3.4lg%% \" ";
  $def[1] .= "GPRINT:var$key:AVERAGE:\"average\: %3.4lg%% \"\\n ";
}

# generate html color code
function color(){
  $color = dechex(rand(0,10000000));
  while (strlen($color) < 6){
    $color = dechex(rand(0,10000000));
  }
  return $color;
}

?>
