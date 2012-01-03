proc update_fifo32_depth {param_handle} {
	set retval 0;
	set mhsinst [xget_hw_parent_handle $param_handle]
	set busifs [xget_hw_connected_busifs_handle $mhsinst "SFIFO32" "INITIATOR"]

	puts "busifs $busifs"

	return $retval
}
