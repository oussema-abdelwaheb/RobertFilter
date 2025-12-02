
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity filtre_robert_top is
    generic (
        IMG_WIDTH  : integer := 128
    );
    port (
        clk         : in  std_logic;
        rst         : in  std_logic;

        pixel_in    : in  std_logic_vector(7 downto 0);
        valid_in    : in  std_logic;
        line_start  : in  std_logic;
        frame_start : in  std_logic;

        pixel_out   : out std_logic_vector(7 downto 0); -- final magnitude (clamped)
        valid_out   : out std_logic
    );
end entity filtre_robert_top;

architecture rtl of filtre_robert_top is

    -- Component declarations (matching files above)
    component filtre_robert_gx
        generic ( IMG_WIDTH : integer := 128 );
        port (
            clk         : in  std_logic;
            rst         : in  std_logic;
            pixel_in    : in  std_logic_vector(7 downto 0);
            valid_in    : in  std_logic;
            line_start  : in  std_logic;
            frame_start : in  std_logic;
            gx_out      : out signed(8 downto 0);
            valid_out   : out std_logic
        );
    end component;

    component filtre_robert_gy
        generic ( IMG_WIDTH : integer := 128 );
        port (
            clk         : in  std_logic;
            rst         : in  std_logic;
            pixel_in    : in  std_logic_vector(7 downto 0);
            valid_in    : in  std_logic;
            line_start  : in  std_logic;
            frame_start : in  std_logic;
            gy_out      : out signed(8 downto 0);
            valid_out   : out std_logic
        );
    end component;

    -- Signals to connect to children
    signal gx_sig    : signed(8 downto 0);
    signal gy_sig    : signed(8 downto 0);
    signal v_gx      : std_logic;
    signal v_gy      : std_logic;

    -- magnitude internal
    signal mag_int   : unsigned(9 downto 0); -- enough to hold |Gx|+|Gy| up to 510

begin

    -- instantiate filtre1 (Gx)
    filtre1 : filtre_robert_gx
        generic map ( IMG_WIDTH => IMG_WIDTH )
        port map (
            clk => clk,
            rst => rst,
            pixel_in => pixel_in,
            valid_in => valid_in,
            line_start => line_start,
            frame_start => frame_start,
            gx_out => gx_sig,
            valid_out => v_gx
        );

    -- instantiate filtre2 (Gy)
    filtre2 : filtre_robert_gy
        generic map ( IMG_WIDTH => IMG_WIDTH )
        port map (
            clk => clk,
            rst => rst,
            pixel_in => pixel_in,
            valid_in => valid_in,
            line_start => line_start,
            frame_start => frame_start,
            gy_out => gy_sig,
            valid_out => v_gy
        );

    -- combine Gx and Gy when both valid (they are synchronized in these designs)
    process(gx_sig, gy_sig, v_gx, v_gy)
        variable abs_gx : unsigned(8 downto 0);
        variable abs_gy : unsigned(8 downto 0);
        variable sum    : unsigned(9 downto 0);
    begin
        if v_gx = '1' and v_gy = '1' then
            -- absolute values
            if gx_sig < 0 then
                abs_gx := unsigned(-gx_sig);
            else
                abs_gx := unsigned(gx_sig);
            end if;

            if gy_sig < 0 then
                abs_gy := unsigned(-gy_sig);
            else
                abs_gy := unsigned(gy_sig);
            end if;

            sum := ("0" & abs_gx) + ("0" & abs_gy); -- extend to 10 bits
            mag_int <= sum;
            valid_out <= '1';
        else
            mag_int <= (others => '0');
            valid_out <= '0';
        end if;

        -- clamp to 8 bits and drive pixel_out
        if mag_int > to_unsigned(255, 10) then
            pixel_out <= std_logic_vector(to_unsigned(255, 8));
        else
            pixel_out <= std_logic_vector(resize(mag_int, 8));
        end if;
    end process;

end architecture rtl;
