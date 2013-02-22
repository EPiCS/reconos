package utilPkg is
	
	function toLog2Ceil (x: integer) return integer;
	
	function toPow2(x: integer) return integer;
		
end package utilPkg;

package body utilPkg is

	function toLog2Ceil (x: integer) return integer is
	  variable y,z: integer;
	begin
	  y := 1;
	  z := 2;
	  while x > z loop
	  	y := y + 1;
	  	z := z * 2;
	  end loop;
	  return y;
	end toLog2Ceil;
	
	function toPow2(x: integer) return integer is
		variable result : integer;
	begin
		result := 1;
		for i in 0 to x-1 loop
			result := result*2;
		end loop;
		return result;
	end toPow2;
	
end package body utilPkg;
