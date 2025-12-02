
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity filtre_robert_gx is
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
        gx_out      : out signed(8 downto 0);  -- signed gradient [-255..+255]
        valid_out   : out std_logic            -- valid when gx_out is meaningful
    );
end entity filtre_robert_gx;

architecture rtl of filtre_robert_gx is

    -- Single-row line buffer type (previous row storage)
    type row_t is array (0 to IMG_WIDTH-1) of std_logic_vector(7 downto 0);
    signal line_buf      : row_t;

    -- Column counter to index into the line buffer
    signal col_cnt       : integer range 0 to IMG_WIDTH-1 := 0;
    signal have_prev_row : std_logic := '0';  -- becomes '1' after first row was stored

    -- Shift register for current row previous pixel
    signal prev_cur_pixel : std_logic_vector(7 downto 0) := (others => '0');

    -- Local registers for the 2x2 window:
    -- p00 = previous_row, previous_column
    -- p01 = previous_row, current_column
    -- p10 = current_row, previous_column
    -- p11 = current_row, current_column (== pixel_in)
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
                gx_out <= (others => '0');
                valid_out <= '0';
                internal_valid <= '0';
            else
                -- handle line start and column counting
                if valid_in = '1' then
                    if line_start = '1' then
                        col_cnt <= 0;
                    else
                        -- increment column with wrap guard
                        if col_cnt = IMG_WIDTH-1 then
                            col_cnt <= 0;
                        else
                            col_cnt <= col_cnt + 1;
                        end if;
                    end if;
                end if;

                -- When receiving a pixel, form 2x2 window using line buffer
                if valid_in = '1' then
                    -- read previous row data at this column
                    p01 <= unsigned(line_buf(col_cnt));   -- previous row, same column
                    -- previous row, previous column:
                    if col_cnt = 0 then
                        p00 <= (others => '0');  -- no previous column -> treat as zero (padding)
                    else
                        p00 <= unsigned(line_buf(col_cnt - 1));
                    end if;

                    -- current row previous pixel
                    p10 <= unsigned(prev_cur_pixel);
                    -- current row current pixel
                    p11 <= unsigned(pixel_in);

                    -- update line buffer: store current pixel for next row
                    line_buf(col_cnt) <= pixel_in;

                    -- update prev_cur_pixel shift register
                    prev_cur_pixel <= pixel_in;

                    -- Indicate that we have previous row AFTER the first full row was written.
                                        if frame_start = '1' and line_start = '1' then
                                                null;
                    end if;

                end if;

                                if valid_in = '1' and col_cnt = IMG_WIDTH-1 then
                    have_prev_row <= '1';
                end if;

                -- Internal valid is true only when 2x2 window is fully available
if valid_in = '1' and have_prev_row = '1' then
    if col_cnt /= 0 then
        internal_valid <= '1';
    else
        internal_valid <= '0';  -- first column: pad zeros
    end if;
else
    internal_valid <= '0';
end if;

-- Compute Gx when internal_valid is asserted
if internal_valid = '1' then
    -- Gx = p00 - p11
        gx_out <= signed('0' & p00) - signed('0' & p11);  -- extend to 9 bits
    valid_out <= '1';
else
    gx_out <= (others => '0');
    valid_out <= '0';
end if;
            end if;
        end if;
    end process;

end architecture rtl;
