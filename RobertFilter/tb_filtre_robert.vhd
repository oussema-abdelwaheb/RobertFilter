

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_filtre_robert is
end entity;

architecture sim of tb_filtre_robert is

    constant IMG_W : integer := 128;
    constant IMG_H : integer := 128;

    signal clk       : std_logic := '0';
    signal rst       : std_logic := '1';

    signal pixel_in  : std_logic_vector(7 downto 0) := (others => '0');
    signal valid_in  : std_logic := '0';
    signal line_start: std_logic := '0';
    signal frame_start: std_logic := '0';

    signal pixel_out : std_logic_vector(7 downto 0);
    signal valid_out : std_logic;

    -- File I/O
    file infile    : text open read_mode is "lena.dat";   -- your MATLAB produced file (decimal)
    file outfile   : text open write_mode is "output.dat";
    file outfile_gx: text open write_mode is "gx.dat";
    file outfile_gy: text open write_mode is "gy.dat";

    -- helpers
    signal sim_done : boolean := false;

begin

    -- instantiate top-level
    uut: entity work.filtre_robert_top
        generic map ( IMG_WIDTH => IMG_W )
        port map (
            clk => clk,
            rst => rst,
            pixel_in => pixel_in,
            valid_in => valid_in,
            line_start => line_start,
            frame_start => frame_start,
            pixel_out => pixel_out,
            valid_out => valid_out
        );

    -- clock generation
    clk_proc : process
    begin
        while not sim_done loop
            clk <= '0';
            wait for 5 ns;
            clk <= '1';
            wait for 5 ns;
        end loop;
        wait;
    end process clk_proc;

    -- stimulus process: read input file and stream pixels
    stim_proc : process
        variable L : line;
        variable val_int : integer;
        variable col : integer := 0;
        variable row : integer := 0;
        variable out_line : line;
        variable out_line_gx : line;
        variable out_line_gy : line;
    begin
        -- reset
        rst <= '1';
        wait for 20 ns;
        rst <= '0';
        wait for 10 ns;

        -- initialize counters
        col := 0;
        row := 0;
        frame_start <= '0';

        -- Read entire image and stream
        while not endfile(infile) loop
            readline(infile, L);
            read(L, val_int); -- read decimal integer from file

            -- prepare pixel_in
            if val_int < 0 then
                val_int := 0;
            elsif val_int > 255 then
                val_int := 255;
            end if;
            pixel_in <= std_logic_vector(to_unsigned(val_int, 8));

            -- valid and line/frame markers
            valid_in <= '1';
            if row = 0 and col = 0 then
                frame_start <= '1';
            else
                frame_start <= '0';
            end if;
            if col = 0 then
                line_start <= '1';
            else
                line_start <= '0';
            end if;

            -- advance counters on next clock edge
            wait until rising_edge(clk);

                        if valid_out = '1' then
                -- write final magnitude to output.dat
                write(out_line, integer'image(to_integer(unsigned(pixel_out))));
                writeline(outfile, out_line);
                            end if;

            -- increment column/row
            if col = IMG_W - 1 then
                col := 0;
                row := row + 1;
            else
                col := col + 1;
            end if;

            -- Clear transient flags (kept asserted for only one cycle)
            valid_in <= '0';
            line_start <= '0';
            frame_start <= '0';

            wait for 0 ns; -- continue loop
        end loop;

        -- finished sending all pixels; wait a bit then finish
        wait for 200 ns;

        -- close files 
        -- end simulation
        sim_done <= true;
        wait;
    end process stim_proc;

end architecture sim;




