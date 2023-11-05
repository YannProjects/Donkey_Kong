import sys

input_file_name = sys.argv[1]
binary_file_1 = input_file_name + ".0a"
binary_file_2 = input_file_name + ".0b"
binary_file_3 = input_file_name + ".0c"
binary_file_4 = input_file_name + ".0d"
output_file_name = input_file_name + ".coe"

bin_rom_file = open(binary_file_1, "rb")
binary_data_1 = bin_rom_file.read()
bin_rom_file.close()

bin_rom_file = open(binary_file_2, "rb")
binary_data_2 = bin_rom_file.read()
bin_rom_file.close()

bin_rom_file = open(binary_file_3, "rb")
binary_data_3 = bin_rom_file.read()
bin_rom_file.close()

bin_rom_file = open(binary_file_4, "rb")
binary_data_4 = bin_rom_file.read()
bin_rom_file.close()

coe_file = open(output_file_name, "w+")
coe_file.write("memory_initialization_radix=16;\n")
coe_file.write("memory_initialization_vector=")
for i in binary_data_1:
    coe_file.write(f"{i:02x}" + " ")
for i in binary_data_2:
    coe_file.write(f"{i:02x}" + " ")
for i in binary_data_3:
    coe_file.write(f"{i:02x}" + " ")
for i in binary_data_4:
    coe_file.write(f"{i:02x}" + " ")

coe_file.write(";")
coe_file.close()
         
