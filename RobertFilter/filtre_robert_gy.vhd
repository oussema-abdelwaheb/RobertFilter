

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity filtre_robert_gy is
    generic (
        IMG_WIDTH  : integer := 128   -- image width (pixels per line)
    );
    port (
        clk         : in  std_logic;
        rst         : in  std_logic;

        -- Streaming input (one pixel per clock when valid_in='1')
        pixel_in    : in  std_logic_vector(7 downto 0); -- 8-bit grayscale
        valid_in    : in  std_logic;
        line_start  : in  std_logic; -- asserted '1' on first pixel of each line
        frame_start : in  std_logic; -- asserted '1' on first pixel of frame

        -- Output
        gy_out      : out signed(8 downto 0);  -- signed gradient [-255..+255]
        valid_out   : out std_logic            -- valid when gy_out is meaningful
    );
end entity filtre_robert_gy;

architecture rtl of filtre_robert_gy is

    -- Single-row line buffer type (previous row storage)
    type row_t is array (0 to IMG_WIDTH-1) of std_logic_vector(7 downto 0);
    signal line_buf      : row_t := (others => (others => '0'));

    -- Column counter to index into the line buffer
    signal col_cnt       : integer range 0 to IMG_WIDTH-1 := 0;
    signal have_prev_row : std_logic := '0';

    -- Shift register for current row previous pixel
    signal prev_cur_pixel : std_logic_vector(7 downto 0) := (others => '0');

    -- Window registers (2x2 pixels)
    signal p00, p01, p10, p11 : unsigned(7 downto 0);

    -- internal valid that ensures we have a full 2x2 window
    signal internal_valid : std_logic := '0';

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                col_cnt <= 0;
                have_prev_row <= '0';
                prev_cur_pixel <= (others => '0');
                line_buf <= (others => (others => '0'));
                gy_out <= (others => '0');
                valid_out <= '0';
                internal_valid <= '0';
            else
                -- handle line start and column counting
                if valid_in = '1' then
                    if line_start = '1' then
                        col_cnt <= 0;
                    else
                        if col_cnt = IMG_WIDTH-1 then
                            col_cnt <= 0;
                        else
                            col_cnt <= col_cnt + 1;
                        end if;
                    end if;

                    -- update window pixels
                    p01 <= unsigned(line_buf(col_cnt));   -- previous row, same column
                    if col_cnt = 0 then
                        p00 <= (others => '0');           -- pad first column
                    else
                        p00 <= unsigned(line_buf(col_cnt - 1));
                    end if;

                    p10 <= unsigned(prev_cur_pixel);      -- current row, previous pixel
                    p11 <= unsigned(pixel_in);            -- current pixel

                    -- update line buffer and shift register
                    line_buf(col_cnt) <= pixel_in;
                    prev_cur_pixel <= pixel_in;

                    -- mark first row completed
                    if col_cnt = IMG_WIDTH-1 then
                        have_prev_row <= '1';
                    end if;

                    -- internal_valid true only when previous row exists and col>0
                    if have_prev_row = '1' and col_cnt /= 0 then
                        internal_valid <= '1';
                    else
                        internal_valid <= '0';
                    end if;

                    -- Compute Gy only when 2x2 window is ready
                    if internal_valid = '1' then
                        gy_out <= signed('0' & p01) - signed('0' & p10); -- extend to 9 bits
                        valid_out <= '1';
                    else
                        gy_out <= (others => '0');
                        valid_out <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process;

end architecture rtl;
