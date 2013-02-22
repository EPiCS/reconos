library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library hwt_huffman_enc_v1_00_a;
use hwt_huffman_enc_v1_00_a.Huffman_Pkg.all;

--library proc_common_v3_00_a;
--use proc_common_v3_00_a.proc_common_pkg.all;

library reconos_v3_00_a;
use reconos_v3_00_a.reconos_pkg.all;

entity huffman_enc is
	port (
		-- OSIF FSL
		OSFSL_Clk       : in  std_logic;                 -- Synchronous clock
		OSFSL_Rst       : in  std_logic;
		OSFSL_S_Clk     : out std_logic;                 -- Slave asynchronous clock
		OSFSL_S_Read    : out std_logic;                 -- Read signal, requiring next available input to be read
		OSFSL_S_Data    : in  std_logic_vector(0 to 31); -- Input data
		OSFSL_S_Control : in  std_logic;                 -- Control Bit, indicating the input data are control word
		OSFSL_S_Exists  : in  std_logic;                 -- Data Exist Bit, indicating data exist in the input FSL bus
		OSFSL_M_Clk     : out std_logic;                 -- Master asynchronous clock
		OSFSL_M_Write   : out std_logic;                 -- Write signal, enabling writing to output FSL bus
		OSFSL_M_Data    : out std_logic_vector(0 to 31); -- Output data
		OSFSL_M_Control : out std_logic;                 -- Control Bit, indicating the output data are contol word
		OSFSL_M_Full    : in  std_logic;                 -- Full Bit, indicating output FSL bus is full
		
		-- FIFO Interface
	--	FIFO32_S_Clk : out std_logic;
	--	FIFO32_M_Clk : out std_logic;
		FIFO32_S_Data : in std_logic_vector(31 downto 0);
		FIFO32_M_Data : out std_logic_vector(31 downto 0);
		FIFO32_S_Fill : in std_logic_vector(15 downto 0);
		FIFO32_M_Rem : in std_logic_vector(15 downto 0);
		FIFO32_S_Rd : out std_logic;
		FIFO32_M_Wr : out std_logic;
		
		rst       : in std_logic;
		osif_clk : out std_logic;	
---- Input Interface

		DataInxD     : in std_logic_vector(7 downto 0);
		ValidInxS    : in std_logic;
		SofInxS      : in std_logic;
		EofInxS      : in std_logic;
		ReadyOutxS   : out std_logic;
		
---- Output Interface

		FullInxS		 : in std_logic;
		DataOutxD  	 : out std_logic_vector(9 downto 0);
		ValidOutxS 	 : out std_logic
	);

end huffman_enc;

architecture implementation of huffman_enc is

---- State for ReconOS State Machine

	constant MBOX_RECV  : std_logic_vector(C_FSL_WIDTH-1 downto 0) := x"00000000";
	constant MBOX_SEND  : std_logic_vector(C_FSL_WIDTH-1 downto 0) := x"00000001";

	signal code_int : std_logic_vector(C_FSL_WIDTH-1 downto 0);

	signal state    : STATE_TYPE;
	signal i_osif   : i_osif_t;
	signal o_osif   : o_osif_t;
	signal i_memif  : i_memif_t;
	signal o_memif  : o_memif_t;
	signal i_ram    : i_ram_t;
	signal o_ram    : o_ram_t;


---- CE D-FF for codes and lengths

	signal ValidOutCxS 				: std_logic := '0';

	signal CodexDP, CodexDN 		: REG_BANK;
	signal CexC							: std_logic_vector(255 downto 0);

---- Keep track of which ASCII Codes were set	
		
	signal CodeSetxDP, CodeSetxDN	: std_logic_vector(255 downto 0);
	signal CodeSetxCE					: std_logic_vector(255 downto 0);


   signal StatexDP, StatexDN 		: FORWARD_TYPE; 

	
---- Internal Control Signals
	
	signal CodingxS 							: std_logic_vector(1 downto 0); 
	signal CounterxD 							: integer range 0 to 15 := 0;
	signal MoreDataxS 						: std_logic;
	signal MoreDataOldxS						: std_logic;
	signal MorexS								: std_logic;
	signal EthTypeLenxDP, EthTypeLenxDN : std_logic_vector(31 downto 0);
	signal LengthxDP, LengthxDN 			: integer range 0 to 1500;
	
---- Internal Data from Encoder

   signal EncodeDataxD 		: std_logic_vector(16 downto 0) := (others => '0');
   signal EncodeIsValidxS 	: std_logic := '0';
	signal EncodedLengthxS 	: integer range 0 to 17 := 0;
	
---- Output Data from Encoder
	
	signal DataOutEncxD 		: std_logic_vector(9 downto 0) := (others => '0');

-- Huffman Encode Record Data

	signal HuffEncxD, HuffEncInxD	: huffman_enc_type;
	
begin

	fsl_setup(
		i_osif,
		o_osif,
		OSFSL_Clk,
		OSFSL_Rst,
		OSFSL_S_Data,
		OSFSL_S_Exists,
		OSFSL_M_Full,
		OSFSL_M_Data,
		OSFSL_S_Read,
		OSFSL_M_Write,
		OSFSL_M_Control
	);
		
	memif_setup(
		i_memif,
		o_memif,
		OSFSL_Clk,
--		FIFO32_S_Clk,
		FIFO32_S_Data,
		FIFO32_S_Fill,
		FIFO32_S_Rd,
--		FIFO32_M_Clk,
		FIFO32_M_Data,
		FIFO32_M_Rem,
		FIFO32_M_Wr
	);
	

	osif_clk <= i_osif.clk;

	MoreDataxS <= MorexS and (not FullInxS);

	---- No further data during PRECODE stage, otherwise it depends on MoreDataxS
	----------------------------------------------------------------------------
	ReadyOutxS <= '0' when (CodingxS = "01" or CodingxS = "10") else MoreDataxS;
	
	---- Input data is forwarded except for coding packets
	----------------------------------------------------------------------------
	DataOutxD <= DataOutEncxD when (CodingxS = "11" or CodingxS = "10") else SofInxS & EofInxS & DataInxD; 
				
	---- ValidOutxS depends on the curren state
	-----------------------------------------------------------------------------
	validoutComb: process (CodingxS, ValidOutCxS, ValidInxS, MoreDataxS)
	begin
		case CodingxS is
			when "11" => ValidOutxS <= ValidOutCxS;
			when "10" => ValidOutxS <= ValidOutCxS;
			when "01" => ValidOutxS <= '0';
			when others => ValidOutxS <= ValidInxS and MoreDataxS;
		end case;
	end process;
	
	---- Encoding process: Returns the corresponding code to an ASCII code
	---- Should only be executed if we have at least 17 free bits in the buffer
	---- Should probably depend on MoreData and FullxS as well
	----------------------------------------------------------------------------
	encodeComb : process(DataInxD, CodingxS, ValidInxS, CodeSetxDP, CodexDP) is
		 variable len : natural range 0 to 17;
		 variable index : natural range 0 to 255;
		 begin
			if ValidInxS = '1' and (CodingxS = "11" or CodingxS = "10") then
				index := CONV_INTEGER(DataInxD);
				EncodeDataxD <= (others => '0');
				if CodeSetxDP(index) = '1' then
				  len := CONV_INTEGER(CodexDP(index)(4 downto 0));
				  EncodeDataxD(16 downto 16-len+1) <= CodexDP(index)(21 downto 21-len+1);
				else -- not set -> unknown code write 0x00
				  EncodeDataxD(16 downto 9) <= x"00";
				  len := 8;
				end if;
				EncodedLengthxS <= len;
				EncodeIsValidxS <= '1';
			else
				EncodeDataxD <= (others => '0');
				EncodeIsValidxS <= '0';
				EncodedLengthxS <= 0;
			end if;
		 end process;
 
 
 	---- controldataComb process: Keeps track of internal registers and data
	---- Reads the data from the encoder and prepares the output data
	---- Should probably depend on MoreData and FullxS as well
	----------------------------------------------------------------------------
   controldataComb: process (LengthxDP, FullInxS, MoreDataOldxS, EncodeIsValidxS, EncodeDataxD, HuffEncxD, EncodedLengthxS)
		variable v : huffman_enc_type;
		variable mask : std_logic_vector(7 downto 0);
   begin
      v := HuffEncxD;
		DataOutEncxD <= "00" & x"00";
		ValidOutCxS <= '0';
		MorexS <= '1'; -- waiting for more data (default)
		mask := (others => '0');
		
		if LengthxDP /= 0 then
			v.len := LengthxDP;
		end if;
		
		--if EofInxS = '1' then
		--	v.eof := '1';
		--end if;
		
		if EncodeIsValidxS = '1' and v.len > 0 then
		 ---- if MoreData = '0' still old EncodeDataxD
		 if MoreDataOldxS = '1' then
			v.bufferIn(v.posbufferIn-1 downto v.posbufferIn-EncodedLengthxS) := EncodeDataxD(16 downto 16-EncodedLengthxS+1);
			v.posbufferIn := v.posbufferIn - EncodedLengthxS;
			v.len := v.len - 1;
		 end if;
			
			if v.posbufferIn < 17 and FullInxS = '0' then -- at least 1 byte to write
				if v.len = 0 and v.posbufferIn = 16 then -- last byte to write set eof
					DataOutEncxD <= "01" & v.bufferIn(23 downto 16); -- write first byte
				else
					DataOutEncxD <= "00" & v.bufferIn(23 downto 16); -- write first byte
				end if;
				--DataOutEncxD <= "00" & v.bufferIn(23 downto 16); -- write first byte
				v.bufferIn(23 downto 0) := v.bufferIn(15 downto 0) & x"00"; -- shift one byte
				v.posbufferIn := v.posbufferIn + 8;
				ValidOutCxS <= '1';
			end if;
			
			if v.posbufferIn < 17 then -- > not enough space to fetch 17 bits 
				MorexS <= '0';
			end if;
			
		elsif v.len = 0 and FullInxS = '0' then -- write out remaining buffer
			if v.posbufferIn < 16 then -- more than one byte left
				DataOutEncxD <= "00" & v.bufferIn(23 downto 16); -- write first byte
				v.bufferIn(23 downto 0) := v.bufferIn(15 downto 0) & x"00"; -- shift one byte
				v.posbufferIn := v.posbufferIn + 8;
				ValidOutCxS <= '1';
			elsif v.posbufferIn = 24 then
				null;
			else -- one byte or less left set eof flag
				mask(7 downto 7-(23-v.posbufferIn)) := v.bufferIn(23 downto v.posbufferIn);
				DataOutEncxD <= "01" & mask;
				v.posbufferIn := 24;
				ValidOutCxS <= '1';
			end if;
		end if;
		HuffEncInxD <= v;
   end process;

   SYNC_PROC: process (OSFSL_Clk)
   begin
      if (OSFSL_Clk'event and OSFSL_Clk = '1') then
         if (rst = '1') then
				HuffEncxD <= ((others => '0'), 24, 0, '0');
            StatexDP <= NEUTRAL;
				LengthxDP <= 0;
				EthTypeLenxDP <= (others => '0');
				MoreDataOldxS <= '1';
         else
				MoreDataOldxS <= MoreDataxS;
				HuffEncxD <= HuffEncInxD;
				StatexDP <= StatexDN;
				LengthxDP <= LengthxDN;
				EthTypeLenxDP <= EthTypeLenxDN;
         end if;        
      end if;
   end process;
	
 	---- OUTPUT_DECODE process: Maps State to a CodingxS Value
	----------------------------------------------------------------------------
   OUTPUT_DECODE: process (StatexDP)
   begin
      if (StatexDP = CODE) then
         CodingxS <= "11";
		elsif StatexDP = POSTCODE then
			CodingxS <= "10";
		elsif StatexDP = PRECODE then
			CodingxS <= "01";
      else
         CodingxS <= "00";
      end if;
   end process;
	
	---- Counter process: Keeps track of the ETHERNET Header
	---- Should only be decremented if we know that the data has been read
	---- Should depend on MoreData and FullxS
	----------------------------------------------------------------------------
	Counter: process (OSFSL_Clk) 
	begin
		if OSFSL_Clk='1' and OSFSL_Clk'event then
			if rst='1' then 
				CounterxD <= 0;
			elsif MoreDataxS = '1' then
				if SofInxS = '1' and StatexDP = NEUTRAL then
					CounterxD <= 14;
				else
					if CounterxD > 0 then
						CounterxD <= CounterxD - 1;
					end if;
				end if;
			end if;
		end if;
	end process; 
	
 	---- NEXT_STATE_DECODE process: Determines the next state of the FSM
	----------------------------------------------------------------------------
   NEXT_STATE_DECODE: process (StatexDP, SofInxS, EofInxS, DataInxD, MoreDataxS, MoreDataOldxS, CounterxD, EthTypeLenxDP)
		variable v : std_logic_vector(31 downto 0);
	begin

      StatexDN <= StatexDP;  --default is to stay in current state
		v := EthTypeLenxDP;
		LengthxDN <= 0;
	
      case (StatexDP) is
         when NEUTRAL =>
            if SofInxS = '1' and MoreDataxS = '1' then
               StatexDN <= ANALYZE;
            end if;
				v := (others => '0');
         when ANALYZE =>
				if MoreDataOldxS = '1' then --MoreDataxS = '1' and means data to read
					if CounterxD = 0 then
						if EthTypeLenxDP(23 downto 8) = x"ACDC" then
							if MoreDataxS = '1' then
								v := EthTypeLenxDP(23 downto 0) & DataInxD;
								StatexDN <= PRECODE;
							else
								v := EthTypeLenxDP(23 downto 0) & DataInxD;
								StatexDN <= WAIT_PRECODE;
							end if;
						else
							StatexDN <= FORWARD;
						end if;
					else
						v := EthTypeLenxDP(23 downto 0) & DataInxD;
					end if;
				end if;
			when WAIT_PRECODE =>
				if MoreDataxS = '1' then
					LengthxDN <= CONV_INTEGER(EthTypeLenxDP(15 downto 0));
					StatexDN <= CODE;
				end if;
			when PRECODE =>
					LengthxDN <= CONV_INTEGER(EthTypeLenxDP(15 downto 0));
					StatexDN <= CODE;
         when CODE =>
				if EofInxS = '1' and MoreDataxS = '1' then
					StatexDN <= POSTCODE;
				end if;
			when POSTCODE =>
				if MoreDataxS = '1' then
					StatexDN <= NEUTRAL;
				end if;
			when FORWARD =>
				if EofInxS = '1' and MoreDataxS = '1' then
					StatexDN <= NEUTRAL;
				end if;
         when others =>
            StatexDN <= NEUTRAL;
      end case; 

	EthTypeLenxDN <= v;
		
   end process;

--
-- The following part consists of
-- 1.) Register bank for code and its length
-- 2.) Registers to keep track which ASCII Code was set or not
-- 3.) The FSM to store code and length into the register bank

	regbankGen: for i in 0 to REG_NR-1 generate	-- Alphabet size
		regGen: for j in 0 to REG_LEN-1 generate	-- 22 bits for each ASCII CHAR
			CodeReg:	process (OSFSL_Clk)
			begin
				if OSFSL_Clk'event and OSFSL_Clk='1' then  
					if rst='1' then   
						CodexDP(i)(j) <= '0';
					elsif CexC(i) ='1' then
						CodexDP(i)(j) <= CodexDN(i)(j);
					end if;
				end if;
			end process;
		end generate regGen;
	end generate regbankGen;
	
	CodeSetGen : for i in 0 to 255 generate
		CodeSetReg: process (OSFSL_Clk)
		begin
			if OSFSL_Clk'event and OSFSL_Clk='1' then  
				if rst='1' then   
					CodeSetxDP(i) <= '0';
				elsif CodeSetxCE(i) ='1' then
					CodeSetxDP(i) <= CodeSetxDN(i);
				end if;
			end if;
		end process;
	end generate CodeSetGen;
	
	
-- Data from Reconos (32 bit)
-- | Ascii Value (8bit)| Code (17bit) | Length (5bit) | 00 |
-- Data Stored (22 bit)
-- | Code (17bit) | Length (5bit) |
-- os and memory synchronisation state machine
	reconos_fsm: process (i_osif.clk,rst,o_osif,o_memif,o_ram) is
		variable done  : boolean;
      		variable index : natural range 0 to 255;
                
	begin
		if rst = '1' then
			osif_reset(o_osif);
			memif_reset(o_memif);
			state <= WAIT_FOR_CODE;
			CexC <= (others => '0');
			CodexDN <= (others => (others => '0'));
			CodeSetxCE <= (others => '0');
			CodeSetxDN <= (others => '0');
			done  := False;
			code_int <= (others => '0');
		elsif rising_edge(i_osif.clk) then
			CexC <= (others => '0');
			CodeSetxCE <= (others => '0');
			CodeSetxDN <= (others => '0');
			case state is
				when WAIT_FOR_CODE =>
					osif_mbox_get(i_osif, o_osif, MBOX_RECV, code_int, done);
					if done then
						if code_int = x"DEADBEEF" then
							state <= STATE_GET_CODE;
						end if;
					end if;
				-- get data words
				when STATE_GET_CODE =>
					osif_mbox_get(i_osif, o_osif, MBOX_RECV, code_int, done);
					if done then
						if code_int = x"DEADDA7A" then
							state <= WAIT_FOR_CODE;
						else
							index := CONV_INTEGER(code_int(31 downto 24)); -- ASCII Char
							CodexDN(index)(REG_LEN-1 downto REG_LEN-MAX_LEN)  <= code_int(23 downto 23-MAX_LEN+1); -- Code
							CodexDN(index)(REG_LEN-MAX_LEN-1 downto 0) <= code_int(6 downto 2); -- Length
							CexC(index) <= '1'; -- Set Clock enable to store
							CodeSetxDN(index) <= '1';
							CodeSetxCE(index) <= '1';
							state <= STATE_GET_CODE;
						end if;
					end if;
				when others =>
					null;
			end case;
		end if;
	end process;

	
end architecture;
