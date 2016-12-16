-- TestBench Template 

  LIBRARY ieee;
  USE ieee.std_logic_1164.ALL;
  USE ieee.numeric_std.ALL;

  library work;
  use work.pck_packets.all;
  use work.pck_string.all;

  ENTITY tb_packets IS
  END entity;

  ARCHITECTURE behavior OF tb_packets IS 

        signal packet : data_vector(0 to 6);
          

  BEGIN
     tb : PROCESS is
            variable p : packet_ptr;
     BEGIN
       for caller in 0 to 1 loop
        for packet_nr in 0 to 20 loop
            p := packet_generate(caller,packet_nr);
            packet <= p(0 to 6);
            wait for 10 ns;
        end loop;   
        end loop;

        wait; -- will wait forever
     END PROCESS tb;
  END;
