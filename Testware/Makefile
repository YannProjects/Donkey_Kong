CC=zcc 
MV=mv
TEST_DIR=/cygdrive/c/Users/yannv/Documents/Projets_HW/Donkey_Kong_init/Tools/Testware

C_FILES=Test_DMA.c
OBJECT_FILES=Test_DMA.o

all: $(C_FILES) $(OBJECT_FILES) dma_hw_test.bin
	python ./bin_to_coe_converter.py dma_hw_test
	cat dma_hw_test.0a dma_hw_test.0b > dma_hw_test.bin	

clean:
	rm -f dma_hw_test.bin Test_DMA.o

dma_hw_test.bin: $(C_FILES) $(OBJECT_FILES)
	$(CC) +pacman -vn -lm $(OBJECT_FILES) -o $@

%.o: %.asm
	$(CC) +pacman -vn --list -c $<

%.o: %.c
	$(CC) +pacman -vn --list -c $<
