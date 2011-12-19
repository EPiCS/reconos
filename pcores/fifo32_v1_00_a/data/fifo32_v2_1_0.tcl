proc update_awidth {param_handle} {
	set mhsinst [xget_hw_parent_handle $param_handle] 
	set depth [xget_hw_parameter_value $mhsinst "C_FIFO32_DEPTH"] 
	set lndepth [expr {log($depth)}]
	set ln2 [expr log(2)]
	#puts "depth $depth"
	#puts "lndepth $lndepth"
	#puts "ln2 $ln2"
	set log2depth [expr {$lndepth/$ln2}]
	#puts "log2depth $log2depth"
	set retval [expr {ceil($log2depth)}]
	#puts "retval $retval"
	return $retval
}
