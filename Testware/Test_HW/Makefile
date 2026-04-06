CC=zcc
INCLUDES=-Iuart_stub -Iuartns550_lite\common -Iuartns550_lite

C_FILES=main.c util.c uartns550_lite/xuartns550.c uartns550_lite/xuartns550_sinit.c
ASM_FILES=interrupts.asm
OBJECT_FILES=$(C_FILES:%.c=%.o) $(ASM_FILES:%.asm=%.o)

%.o: %.asm
	$(CC) +z80 --list -c $<

%.o: %.c
	$(CC) +z80 -clib=classic $(INCLUDES) --list -c $<

clean:
	rm -f DKong_Hw_test.bin $(OBJECT_FILES)

DKong_Hw_test.bin: $(ASM_FILES) $(C_FILES) $(OBJECT_FILES)
	$(CC) +z80 -m -s -clib=classic -pragma-define:CRT_ORG_BSS=0x6000 -pragma-define:REGISTER_SP=0x6C00 -pragma-define:CRT_ENABLE_NMI=0x02 -lm $(OBJECT_FILES) -o $@
	python ../../../Tools/bin_to_coe_converter.py $@
	# Conversion en .mem pour l'initialisation de la memoire flash s29wsal008j
	python ../../../Tools/bin_to_s29al008j.py $@
