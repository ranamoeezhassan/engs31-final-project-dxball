# Author: Rana Moeez Hassan
# This script reads a 24-bit BMP image and converts its pixel data into a VHDL ROM file
# that maps (row, col) addresses to 12-bit RGB values (4 bits per channel).

import imageio.v2 as imageio
import math

# Return 12-bit color string from BMP image pixel (y, x)
def get_color_bits(im, y, x):
    r_byte = format(im[y][x][0], '08b')
    g_byte = format(im[y][x][1], '08b')
    b_byte = format(im[y][x][2], '08b')
    r_bits = r_byte[0:4]
    g_bits = g_byte[0:4]
    b_bits = b_byte[0:4]
    return r_bits + g_bits + b_bits

def rom_12_bit_vhdl(name, im, mask=False, rem_x=-1, rem_y=-1):
    file_name = name.split('.')[0] + "_rom.vhd"
    f = open(file_name, 'w')
    
    y_max, x_max, _ = im.shape
    row_width = math.ceil(math.log2(y_max))
    col_width = math.ceil(math.log2(x_max))
    addr_width = row_width + col_width
    
    # VHDL file header
    f.write("library IEEE;\n")
    f.write("use IEEE.STD_LOGIC_1164.ALL;\n")
    f.write("use IEEE.NUMERIC_STD.ALL;\n\n")
    
    f.write(f"entity {name.split('.')[0]}_rom is\n")
    f.write(f"  Port (\n")
    f.write(f"    clk        : in  std_logic;\n")
    f.write(f"    row        : in  std_logic_vector({row_width - 1} downto 0);\n")
    f.write(f"    col        : in  std_logic_vector({col_width - 1} downto 0);\n")
    f.write(f"    color_data : out std_logic_vector(11 downto 0)\n")
    f.write(f"  );\n")
    f.write(f"end entity;\n\n")
    
    f.write(f"architecture Behavioral of {name.split('.')[0]}_rom is\n")
    f.write(f"  signal addr : std_logic_vector({addr_width - 1} downto 0);\n")
    f.write(f"  signal row_reg : std_logic_vector({row_width -1} downto 0);\n")
    f.write(f"  signal col_reg : std_logic_vector({col_width -1} downto 0);\n")
    f.write(f"begin\n\n")
    
    # Registering row and col addresses on clock
    f.write(f"  process(clk)\n")
    f.write(f"  begin\n")
    f.write(f"    if rising_edge(clk) then\n")
    f.write(f"      row_reg <= row;\n")
    f.write(f"      col_reg <= col;\n")
    f.write(f"    end if;\n")
    f.write(f"  end process;\n\n")
    
    # Combine row and col_reg into addr
    f.write(f"  addr <= row_reg & col_reg;\n\n")
    
    f.write(f"  process(addr)\n")
    f.write(f"  begin\n")
    f.write(f"    case addr is\n")
    
    for y in range(y_max):
        for x in range(x_max):
            addr_val = format(y, f'0{row_width}b') + format(x, f'0{col_width}b')
            color_value = get_color_bits(im, y, x)
            f.write(f"      when \"{addr_val}\" => color_data <= \"{color_value}\";\n")
    
    f.write(f"      when others => color_data <= (others => '0');\n")
    f.write(f"    end case;\n")
    f.write(f"  end process;\n")
    f.write(f"end Behavioral;\n")
    
    f.close()

def generate(name):
    im = imageio.imread(name)
    print(f"Image loaded: width={im.shape[1]}, height={im.shape[0]}")
    rom_12_bit_vhdl(name, im)

# Generate the ROM VHDL for game_over.bmp, change filename as appropriate
generate("brick.bmp")