/*
 *  Outils de test pour debugger le DMA 8257
 */

#include <stdio.h>
#include <games.h>
#include <stdlib.h>
#include <graphics.h>
#include <string.h>

#include <sound.h>

#define DMA_TEST_LENGTH_1 5
#define DMA_TEST_LENGTH_2 700
#define DMA_TEST_LENGTH_3 20

#define RAM1_BASE 0x4800
#define RAM2_BASE 0x4000

unsigned char ram1_test_data[700];
unsigned char error_code, test_step;

#define CH0_DMA_ADDR 0x8000
#define CH0_DMA_TC 0x8001
#define CH1_DMA_ADDR 0x8002
#define CH1_DMA_TC 0x8003
#define CH2_DMA_ADDR 0x8004
#define CH2_DMA_TC 0x8005
#define CH3_DMA_ADDR 0x8006
#define CH3_DMA_TC 0x8007

#define DMA_WR_MODE 0x40
#define DMA_RD_MODE 0x80

#define DMA_STATUS_REG 0x8008
#define DMA_CONFIG_REG DMA_STATUS_REG

// DMA modes
#define AUTOLOAD 0x80
#define TC_STOP 0x40
#define EXTENDED_WRITE 0x20
#define ROTATING_PRIO 0x10
#define EN_CH3 0x08
#define EN_CH2 0x04
#define EN_CH1 0x02
#define EN_CH0 0x01

#define TC_STATUS_CH3 0x08
#define TC_STATUS_CH2 0x04
#define TC_STATUS_CH1 0x02
#define TC_STATUS_CH0 0x01

// DMA request toggle (1st WR => DMA request on / 2nd WR => DMA request off)
#define TRIGGER_DMA_CH0 0x7000
#define TRIGGER_DMA_CH1 0x7001
#define TRIGGER_DMA_CH2 0x7002
#define TRIGGER_DMA_CH3 0x7003
#define CANCEL_DMA_CH0 0x7004
#define CANCEL_DMA_CH1 0x7005
#define CANCEL_DMA_CH2 0x7006
#define CANCEL_DMA_CH3 0x7007

#define SET_CH0_MODE_TO_NORMAL 0x7008
#define SET_CH0_MODE_TO_AUTORELOAD 0x700C
#define SET_CH1_MODE_TO_NORMAL 0x7009
#define SET_CH1_MODE_TO_AUTORELOAD 0x700D
#define SET_CH2_MODE_TO_NORMAL 0x700A
#define SET_CH2_MODE_TO_AUTORELOAD 0x700E
#define SET_CH3_MODE_TO_NORMAL 0x700B
#define SET_CH3_MODE_TO_AUTORELOAD 0x700F


// Configuration et accès aux registres DMA
void Test_1()
{
	test_step = 1;
	
	// Tests pour la configuration du DMA
	// DMA configuration pour transferer la RAM1 vers la RAM2
	*(unsigned char *)CH0_DMA_ADDR = (unsigned char)ram1_test_data;
	*(unsigned char *)CH0_DMA_ADDR = (unsigned char)((unsigned int)ram1_test_data >> 8);
	*(unsigned char *)CH0_DMA_TC = (unsigned char)(DMA_TEST_LENGTH_1 - 1);
	*(unsigned char *)CH0_DMA_TC = (unsigned char)((((unsigned int)(DMA_TEST_LENGTH_1 - 1)) >> 8) | DMA_WR_MODE);
	
	// Read back DMA configuration
	if (*(unsigned char *)CH0_DMA_ADDR != (unsigned char)ram1_test_data) {
		error_code = 1;
	}	
	if (*(unsigned char *)CH0_DMA_ADDR != (unsigned char)((unsigned int)ram1_test_data >> 8)) {
		error_code = 2;
	}

	if (*(unsigned char *)CH0_DMA_TC != (unsigned char)(DMA_TEST_LENGTH_1 - 1)) {
		error_code = 3;
	}
	if (*(unsigned char *)CH0_DMA_TC != (unsigned char)(((DMA_TEST_LENGTH_1 - 1) >> 8) | DMA_WR_MODE)) {
		error_code = 4;
	}

	// DMA configuration. Write status register
	*(unsigned char *)DMA_CONFIG_REG = EN_CH0 | TC_STOP;
	
	// Read status register
	if (*(unsigned char *)DMA_STATUS_REG != 0) {
		error_code = 5;
	}
}

// RAM1  = I/O device
// RAM2  = memory device
// Transfert de 3 octets de RAM1 vers RAM2 et relecture
// Seul CH0 est autorisé, TC_STOP = 1, RP=0, DMA_WR (de RAM1 (I/O RD) vers RAM2 (WR)), RP=0
// A vérifier manuellement:
// TC est bien setté au bon moment
// MARK n'est pas setté
// Le nombre de transferts exacts faits par le DMA
// Que le flag d'erreur en memoire n'est pas positionne
void Test_2()
{
	unsigned int i, ram2_offset;
	unsigned char dma_status_reg_value;	
	
	test_step = 2;
	
	ram2_offset = ram1_test_data - RAM1_BASE;	
	
	// Remplissage RAM1
	for (i=0; i < DMA_TEST_LENGTH_1; i++)
		ram1_test_data[i] = 2;
	
	// Effacement RAM2
	for (i = 0; i < DMA_TEST_LENGTH_1; i++) {
		*(unsigned char *)(RAM2_BASE + ram2_offset + i) = 0;
	}	

	// DMA configuration pour transferer la RAM1 vers la RAM2
	*(unsigned char *)CH0_DMA_ADDR = (unsigned char)ram1_test_data;
	*(unsigned char *)CH0_DMA_ADDR = (unsigned char)((unsigned int)ram1_test_data >> 8);
	*(unsigned char *)CH0_DMA_TC = (unsigned char)(DMA_TEST_LENGTH_1 - 1);
	*(unsigned char *)CH0_DMA_TC = (unsigned char)((((unsigned int)(DMA_TEST_LENGTH_1 - 1)) >> 8) | DMA_WR_MODE);
	
	// DMA configuration. Write status register
	*(unsigned char *)DMA_CONFIG_REG = EN_CH0 | TC_STOP;
	
	// Transfert de 3 octets avec TC_STOP
	// Start DMA request. La valeur ecrite n'a pas de signification
	*(unsigned char *)TRIGGER_DMA_CH0 = 0;
	
	// Pool DMA status jusqu'à ce que TC=1
	while ((dma_status_reg_value & TC_STATUS_CH0) == 0) {
		dma_status_reg_value = *(volatile unsigned char *)DMA_STATUS_REG;
	}
	
	// Stop DMA request. La valeur ecrite n'a pas de signification
	*(unsigned char *)CANCEL_DMA_CH0 = 0;
	
	// Verification que le bit de status est bien resette après lecture
	dma_status_reg_value = *(unsigned char *)DMA_STATUS_REG;
	if (dma_status_reg_value & TC_STATUS_CH0 != 0) {
		error_code = 6;
	}
		
	// Relecture RAM 2 après le transfert DMA
	for (i = 0; i < DMA_TEST_LENGTH_1; i++) {
		if (*(unsigned char *)(RAM2_BASE + ram2_offset + i) != ram1_test_data[i]) {
			error_code = 7;
		}
	}
}


// RAM1  = I/O device
// RAM2  = memory device
// Transfert de 20 octets de RAM1 vers RAM2 avec 2 cycles DMA successifs pour verifier que l'on arrive
// bien à relancer un cycle DMA sur le même canal.
// Seul CH0 est autorisé, TC_STOP = 1, RP=0, DMA_WR (de RAM1 (I/O RD) vers RAM2 (WR)), RP=0
// A vérifier manuellement:
// TC est bien setté au bon moment
// MARK n'est pas setté
// Le nombre de transferts exacts faits par le DMA
// Que le second cycle DMA est bien exécuté
// Que le flag d'erreur en memoire n'est pas positionne
void Test_2_1()
{
	unsigned int i, ram2_offset;
	unsigned char dma_status_reg_value;	
	
	test_step = 21;
	
	ram2_offset = ram1_test_data - RAM1_BASE;	
	
	// Remplissage RAM1
	for (i=0; i < DMA_TEST_LENGTH_3; i++)
		ram1_test_data[i] = 2;
	
	// Effacement RAM2
	for (i = 0; i < DMA_TEST_LENGTH_3; i++) {
		*(unsigned char *)(RAM2_BASE + ram2_offset + i) = 0;
	}	

	// DMA configuration pour transferer la RAM1 vers la RAM2
	*(unsigned char *)CH0_DMA_ADDR = (unsigned char)ram1_test_data;
	*(unsigned char *)CH0_DMA_ADDR = (unsigned char)((unsigned int)ram1_test_data >> 8);
	*(unsigned char *)CH0_DMA_TC = (unsigned char)(DMA_TEST_LENGTH_3 - 1);
	*(unsigned char *)CH0_DMA_TC = (unsigned char)((((unsigned int)(DMA_TEST_LENGTH_3 - 1)) >> 8) | DMA_WR_MODE);
	
	// DMA configuration. Write status register
	*(unsigned char *)DMA_CONFIG_REG = EN_CH0 | TC_STOP;
	
	// Transfert de 3 octets avec TC_STOP
	// Start DMA request. La valeur ecrite n'a pas de signification
	*(unsigned char *)TRIGGER_DMA_CH0 = 0;
	
	dma_status_reg_value = *(volatile unsigned char *)DMA_STATUS_REG;
	// Pool DMA status jusqu'à ce que TC=1
	while ((dma_status_reg_value & TC_STATUS_CH0) == 0) {
		dma_status_reg_value = *(volatile unsigned char *)DMA_STATUS_REG;
	}

	// Stop DMA request. La valeur ecrite n'a pas de signification
	*(unsigned char *)CANCEL_DMA_CH0 = 0;
	
	// Verification que le bit de status est bien resette après lecture
	dma_status_reg_value = *(unsigned char *)DMA_STATUS_REG;
	if (dma_status_reg_value & TC_STATUS_CH0 != 0) {
		error_code = 6;
	}

	// Relecture RAM 2 après le transfert DMA
	for (i = 0; i < DMA_TEST_LENGTH_1; i++) {
		if (*(unsigned char *)(RAM2_BASE + ram2_offset + i) != ram1_test_data[i]) {
			error_code = 7;
		}
	}
	
	//
	// Second cycle DMA
	//
		
	// Effacement RAM2
	for (i = 0; i < DMA_TEST_LENGTH_3; i++) {
		*(unsigned char *)(RAM2_BASE + ram2_offset + i) = 0;
	}	

	// DMA configuration pour transferer la RAM1 vers la RAM2
	*(unsigned char *)CH0_DMA_ADDR = (unsigned char)ram1_test_data;
	*(unsigned char *)CH0_DMA_ADDR = (unsigned char)((unsigned int)ram1_test_data >> 8);
	*(unsigned char *)CH0_DMA_TC = (unsigned char)(DMA_TEST_LENGTH_3 - 1);
	*(unsigned char *)CH0_DMA_TC = (unsigned char)((((unsigned int)(DMA_TEST_LENGTH_3 - 1)) >> 8) | DMA_WR_MODE);
	
	// DMA configuration. Write status register
	*(unsigned char *)DMA_CONFIG_REG = EN_CH0 | TC_STOP;
	
	// Transfert de 3 octets avec TC_STOP
	// Start DMA request. La valeur ecrite n'a pas de signification
	*(unsigned char *)TRIGGER_DMA_CH0 = 0;
	
	// Pool DMA status jusqu'à ce que TC=1
	dma_status_reg_value = *(volatile unsigned char *)DMA_STATUS_REG;	
	while ((dma_status_reg_value & TC_STATUS_CH0) == 0) {
		dma_status_reg_value = *(volatile unsigned char *)DMA_STATUS_REG;
	}
	
	// Stop DMA request. La valeur ecrite n'a pas de signification
	*(unsigned char *)CANCEL_DMA_CH0 = 0;
		
	// Verification que le bit de status est bien resette après lecture
	dma_status_reg_value = *(unsigned char *)DMA_STATUS_REG;
	if (dma_status_reg_value & TC_STATUS_CH0 != 0) {
		error_code = 8;
	}

	// Relecture RAM 2 après le transfert DMA
	for (i = 0; i < DMA_TEST_LENGTH_1; i++) {
		if (*(unsigned char *)(RAM2_BASE + ram2_offset + i) != ram1_test_data[i]) {
			error_code = 9;
		}
	}
}


// RAM1  = I/O device
// RAM2  = memory device
// Transfert de 5 octets de memory device (RAM2) vers I/O device (RAM1) et relecture
// Seul CH0 est autorisé, TC_STOP = 1, RP=0, DMA_RD)
// A vérifier manuellement:
// TC est bien setté au bon moment (dernier cycle DMA avec DACKn = 0
// MARK n'est pas setté
// Le nombre de transferts exacts faits par le DMA
// Que le flag d'erreur en memoire n'est pas positionne
void Test_3()
{
	unsigned int i, ram2_offset;
	unsigned char dma_status_reg_value;	
	
	test_step = 3;
	
	ram2_offset = ram1_test_data - RAM1_BASE;	
	
	// Effacement RAM1 (I/O)
	for (i=0; i < DMA_TEST_LENGTH_1; i++)
		ram1_test_data[i] = 0;
	
	// Remplissage RAM2
	for (i = 0; i < DMA_TEST_LENGTH_1; i++) {
		*(unsigned char *)(RAM2_BASE + ram2_offset + i) = 3;
	}	

	// DMA configuration pour transferer la RAM1 vers la RAM2
	// L'adresse ram1_test_data est la meme que (RAM2_BASE + ram2_offset)
	*(unsigned char *)CH0_DMA_ADDR = (unsigned char)ram1_test_data;
	*(unsigned char *)CH0_DMA_ADDR = (unsigned char)((unsigned int)ram1_test_data >> 8);
	*(unsigned char *)CH0_DMA_TC = (unsigned char)(DMA_TEST_LENGTH_1 - 1);
	*(unsigned char *)CH0_DMA_TC = (unsigned char)((((unsigned int)(DMA_TEST_LENGTH_1 - 1)) >> 8) | DMA_RD_MODE);
	
	// DMA configuration. Write status register
	*(unsigned char *)DMA_CONFIG_REG = EN_CH0 | TC_STOP;
	
	// Transfert de 3 octets avec TC_STOP
	// Start DMA request. La valeur ecrite n'a pas de signification
	*(unsigned char *)TRIGGER_DMA_CH0 = 0;
	
	// Pool DMA status jusqu'à ce que TC=1
	while ((dma_status_reg_value & TC_STATUS_CH0) == 0) {
		dma_status_reg_value = *(volatile unsigned char *)DMA_STATUS_REG;
	}

	// Arret requete DMA.
	*(unsigned char *)CANCEL_DMA_CH0 = 0;	
		
	// Verification que le bit de status est bien resette après lecture
	dma_status_reg_value = *(unsigned char *)DMA_STATUS_REG;
	if (dma_status_reg_value & TC_STATUS_CH0 != 0) {
		error_code = 8;
	}
		
	// Relecture RAM 2 après le transfert DMA
	for (i = 0; i < DMA_TEST_LENGTH_1; i++) {
		if (ram1_test_data[i] != (*(unsigned char *)(RAM2_BASE + ram2_offset + i))) {
			error_code = 9;
		}
	}
}

// RAM1  = I/O device
// RAM2  = memory device
// Transfert de 700 octets de RAM1 vers RAM2 et interruption puis reprise et relecture
// A verifier manuelle que MARK passe à 1 tous les 128 octets de transfert
// Seul CH0 est autorisé, TC_STOP = 1, RP=0, DMA_WR (de RAM1 (I/O RD) vers RAM2 (WR)), RP=0
void Test_4()
{
	unsigned int i, j, ram2_offset;
	unsigned int msb_addr_during_dma, lsb_addr_during_dma, msb_tc_during_dma, lsb_tc_during_dma;
	unsigned char dma_status_reg_value;	
	
	test_step = 4;
	
	ram2_offset = ram1_test_data - RAM1_BASE;	
	
	// Remplissage RAM1
	for (i=0; i < DMA_TEST_LENGTH_2; i++)
		ram1_test_data[i] = 4;
	
	// Effacement RAM2
	for (i = 0; i < DMA_TEST_LENGTH_2; i++) {
		*(unsigned char *)(RAM2_BASE + ram2_offset + i) = 0;
	}	

	// DMA configuration pour transferer la RAM1 vers la RAM2
	*(unsigned char *)CH0_DMA_ADDR = (unsigned char)ram1_test_data;
	*(unsigned char *)CH0_DMA_ADDR = (unsigned char)((unsigned int)ram1_test_data >> 8);
	*(unsigned char *)CH0_DMA_TC = (unsigned char)(DMA_TEST_LENGTH_2 - 1);
	*(unsigned char *)CH0_DMA_TC = (unsigned char)((((unsigned int)(DMA_TEST_LENGTH_2 - 1)) >> 8) | DMA_WR_MODE);
	
	// DMA configuration. Write status register
	*(unsigned char *)DMA_CONFIG_REG = EN_CH0 | TC_STOP;
	
	// Start DMA request. La valeur ecrite n'a pas de signification
	*(unsigned char *)TRIGGER_DMA_CH0 = 0;
	
	for (j=0; j < 5; j++) {}

	// Arret DMA request. La valeur ecrite n'a pas de signification
	*(unsigned char *)CANCEL_DMA_CH0 = 0;
	
	// Re-lecture registres DMA
	lsb_addr_during_dma = *(unsigned char *)CH0_DMA_ADDR;
	msb_addr_during_dma = *(unsigned char *)CH0_DMA_ADDR;
	lsb_tc_during_dma = *(unsigned char *)CH0_DMA_TC;
	msb_tc_during_dma = *(unsigned char *)CH0_DMA_TC;
	
	// Verifie que les registres d'adresse et de nombre de bytes sont bien mis à jour
	// Addr = 0x4A33
	// TC = 0x40F8 (nb octets + DMA mode)
	if (msb_addr_during_dma != 0x49 || lsb_addr_during_dma != 0x38 || 
		msb_tc_during_dma != 0x41 || lsb_tc_during_dma != 0xF3) {
		error_code = 10;
	}
	
	for (j=0; j < 5; j++) {}

	// Redemarrage DMA request . La valeur ecrite n'a pas de signification
	*(unsigned char *)TRIGGER_DMA_CH0 = 0;
	
	// Pool DMA status jusqu'à ce que TC=1
	dma_status_reg_value = *(volatile unsigned char *)DMA_STATUS_REG;
	while ((dma_status_reg_value & TC_STATUS_CH0) == 0) {
		dma_status_reg_value = *(volatile unsigned char *)DMA_STATUS_REG;
	}
	
	// Arret requete DMA.
	*(unsigned char *)CANCEL_DMA_CH0 = 0;	
		
	// Verification que le bit de status est bien resette après lecture
	dma_status_reg_value = *(unsigned char *)DMA_STATUS_REG;
	if (dma_status_reg_value & TC_STATUS_CH0 != 0) {
		error_code = 11;
	}
		
	// Relecture RAM 2 après le transfert DMA
	for (i = 0; i < DMA_TEST_LENGTH_2; i++) {
		if (*(unsigned char *)(RAM2_BASE + ram2_offset + i) != ram1_test_data[i]) {
			error_code = 12;
		}
	}
}

// RAM1  = I/O device
// RAM2  = memory device
// Transfert de 20 octets de RAM1 vers RAM2
// Seul CH1 est autorisé, TC_STOP = 1, RP=0, DMA_WR (de RAM1 (I/O RD) vers RAM2 (WR)), RP=0
void Test_5()
{
	unsigned int i, ram2_offset;
	unsigned char dma_status_reg_value;	
	
	test_step = 5;
	
	ram2_offset = ram1_test_data - RAM1_BASE;	
	
	// Remplissage RAM1
	for (i=0; i < DMA_TEST_LENGTH_3; i++)
		ram1_test_data[i] = 5;
	
	// Effacement RAM2
	for (i = 0; i < DMA_TEST_LENGTH_3; i++) {
		*(unsigned char *)(RAM2_BASE + ram2_offset + i) = 0;
	}	

	// DMA configuration pour transferer la RAM1 vers la RAM2
	*(unsigned char *)CH1_DMA_ADDR = (unsigned char)ram1_test_data;
	*(unsigned char *)CH1_DMA_ADDR = (unsigned char)((unsigned int)ram1_test_data >> 8);
	*(unsigned char *)CH1_DMA_TC = (unsigned char)(DMA_TEST_LENGTH_3 - 1);
	*(unsigned char *)CH1_DMA_TC = (unsigned char)((((unsigned int)(DMA_TEST_LENGTH_3 - 1)) >> 8) | DMA_WR_MODE);
	
	// DMA configuration. Write status register
	*(unsigned char *)DMA_CONFIG_REG = EN_CH1 | TC_STOP;
	
	// Transfert de 3 octets avec TC_STOP
	// Start DMA request. La valeur ecrite n'a pas de signification
	*(unsigned char *)TRIGGER_DMA_CH1 = 0;
		
	// Pool DMA status jusqu'à ce que TC=1
	while ((dma_status_reg_value & TC_STATUS_CH1) == 0) {
		dma_status_reg_value = *(volatile unsigned char *)DMA_STATUS_REG;
	}
	
	// Arret requete DMA.
	*(unsigned char *)CANCEL_DMA_CH1 = 0;	
		
	// Verification que le bit de status est bien resette après lecture
	dma_status_reg_value = *(unsigned char *)DMA_STATUS_REG;
	if (dma_status_reg_value & TC_STATUS_CH1 != 0) {
		error_code = 13;
	}
		
	// Relecture RAM 2 après le transfert DMA
	for (i = 0; i < DMA_TEST_LENGTH_2; i++) {
		if (*(unsigned char *)(RAM2_BASE + ram2_offset + i) != ram1_test_data[i]) {
			error_code = 14;
		}
	}
}

// RAM1  = I/O device
// RAM2  = memory device
// Transfert de 20 octets de RAM1 vers RAM2 en utilisant CH1
// Seul CH0 et CH1 sont autorisés, TC_STOP = 1, RP=0, DMA_WR (de RAM1 (I/O RD) vers RAM2 (WR)), RP=0
void Test_6()
{
	unsigned int i, ram2_offset;
	unsigned char dma_status_reg_value;	
	
	test_step = 6;
	
	ram2_offset = ram1_test_data - RAM1_BASE;	
	
	// Remplissage RAM1
	for (i=0; i < DMA_TEST_LENGTH_3; i++)
		ram1_test_data[i] = 6;
	
	// Effacement RAM2
	for (i = 0; i < DMA_TEST_LENGTH_3; i++) {
		*(unsigned char *)(RAM2_BASE + ram2_offset + i) = 0;
	}	

	// DMA configuration pour transferer la RAM1 vers la RAM2
	*(unsigned char *)CH1_DMA_ADDR = (unsigned char)ram1_test_data;
	*(unsigned char *)CH1_DMA_ADDR = (unsigned char)((unsigned int)ram1_test_data >> 8);
	*(unsigned char *)CH1_DMA_TC = (unsigned char)(DMA_TEST_LENGTH_3 - 1);
	*(unsigned char *)CH1_DMA_TC = (unsigned char)((((unsigned int)(DMA_TEST_LENGTH_3 - 1)) >> 8) | DMA_WR_MODE);
	
	// DMA configuration. Write status register
	*(unsigned char *)DMA_CONFIG_REG = EN_CH0 | EN_CH1 | TC_STOP;
	
	// Transfert de 3 octets avec TC_STOP
	// Start DMA request. La valeur ecrite n'a pas de signification
	*(unsigned char *)TRIGGER_DMA_CH1 = 0;
		
	// Pool DMA status jusqu'à ce que TC=1
	while ((dma_status_reg_value & TC_STATUS_CH1) == 0) {
		dma_status_reg_value = *(volatile unsigned char *)DMA_STATUS_REG;
	}
	
	// Arret requete DMA.
	*(unsigned char *)CANCEL_DMA_CH1 = 0;	
		
	// Verification que le bit de status est bien resette après lecture
	dma_status_reg_value = *(unsigned char *)DMA_STATUS_REG;
	if (dma_status_reg_value & TC_STATUS_CH1 != 0) {
		error_code = 13;
	}
		
	// Relecture RAM 2 après le transfert DMA
	for (i = 0; i < DMA_TEST_LENGTH_2; i++) {
		if (*(unsigned char *)(RAM2_BASE + ram2_offset + i) != ram1_test_data[i]) {
			error_code = 14;
		}
	}
}

// RAM1  = I/O device
// RAM2  = memory device
// Transfert de 2*20 octets de RAM1 vers RAM2 en utilisant CH0 puis CH1 par ordre de priorite
// CH0 et CH1 sont autorises, TC_STOP = 1, RP=0, DMA_WR (de RAM1 (I/O RD) vers RAM2 (WR)), RP=0
void Test_7()
{
	unsigned int i, ram2_offset;
	unsigned char dma_status_reg_value;	
	
	test_step = 7;
	
	ram2_offset = ram1_test_data - RAM1_BASE;	
	
	// Remplissage RAM1
	for (i=0; i < DMA_TEST_LENGTH_3; i++) {
		ram1_test_data[i] = 7;
		ram1_test_data[i + DMA_TEST_LENGTH_3] = 8;
	}

	// Effacement RAM2
	for (i = 0; i < DMA_TEST_LENGTH_3; i++) {
		*(unsigned char *)(RAM2_BASE + ram2_offset + i) = 0;
		*(unsigned char *)(RAM2_BASE + ram2_offset + i + DMA_TEST_LENGTH_3) = 0;
	}	

	// Desactivation requetes DMA
	*(unsigned char *)DMA_CONFIG_REG = 0;

	// DMA configuration pour transferer la RAM1 vers la RAM2 en utilisant CH0 et CH1
	*(unsigned char *)CH0_DMA_ADDR = (unsigned char)(ram1_test_data);
	*(unsigned char *)CH0_DMA_ADDR = (unsigned char)((unsigned int)ram1_test_data >> 8);
	*(unsigned char *)CH0_DMA_TC = (unsigned char)(DMA_TEST_LENGTH_3 - 1);
	*(unsigned char *)CH0_DMA_TC = (unsigned char)((((unsigned int)(DMA_TEST_LENGTH_3 - 1)) >> 8) | DMA_WR_MODE);

	*(unsigned char *)CH1_DMA_ADDR = (unsigned char)(ram1_test_data + DMA_TEST_LENGTH_3);
	*(unsigned char *)CH1_DMA_ADDR = (unsigned char)((unsigned int)(ram1_test_data + DMA_TEST_LENGTH_3) >> 8);
	*(unsigned char *)CH1_DMA_TC = (unsigned char)(DMA_TEST_LENGTH_3 - 1);
	*(unsigned char *)CH1_DMA_TC = (unsigned char)((((unsigned int)(DMA_TEST_LENGTH_3 - 1)) >> 8) | DMA_WR_MODE);
	
	// Transfert avec TC_STOP
	// Start DMA request. La valeur ecrite n'a pas de signification
	*(unsigned char *)TRIGGER_DMA_CH0 = 0;
	*(unsigned char *)TRIGGER_DMA_CH1 = 0;
	
	// activation CH0 et CH1 et TC stop
	*(unsigned char *)DMA_CONFIG_REG = EN_CH0 | EN_CH1 | TC_STOP;

		
	// Pool DMA status jusqu'à ce que TC=1
	while ((dma_status_reg_value & (TC_STATUS_CH0 | TC_STATUS_CH1)) != (TC_STATUS_CH0 | TC_STATUS_CH1)) {
		dma_status_reg_value = *(volatile unsigned char *)DMA_STATUS_REG;
	}
	
	// Arret requete DMA.
	*(unsigned char *)CANCEL_DMA_CH0 = 0;
	*(unsigned char *)CANCEL_DMA_CH1 = 0;
		
	// Verification que le bit de status est bien resette après lecture
	dma_status_reg_value = *(unsigned char *)DMA_STATUS_REG;
	if (dma_status_reg_value & (TC_STATUS_CH0 | TC_STATUS_CH1) != 0) {
		error_code = 15;
	}

	// Relecture RAM 2 après les transferts DMA
	for (i = 0; i < DMA_TEST_LENGTH_3*2; i++) {
		if (*(unsigned char *)(RAM2_BASE + ram2_offset + i) != ram1_test_data[i]) {
			error_code = 16;
		}
	}
}

// RAM1  = I/O device
// RAM2  = memory device
// Transfert de 2*20 octets de RAM1 vers RAM2 en utilisant CH0 puis CH1 par ordre de priorite
// CH0 desactivé / CH1 activé autorises, TC_STOP = 1, RP=0, DMA_WR (de RAM1 (I/O RD) vers RAM2 (WR)), RP=0
// puis CH0 est activé
// => On doit faire le transfert DM1 de CH1 en premier malgré que CH0 est une plus grande priorité
void Test_8()
{
	unsigned int i, ram2_offset;
	unsigned char dma_status_reg_value;	
	
	test_step = 8;
	
	ram2_offset = ram1_test_data - RAM1_BASE;	
	
	// Remplissage RAM1
	for (i=0; i < DMA_TEST_LENGTH_3; i++) {
		ram1_test_data[i] = 9;
		ram1_test_data[i + DMA_TEST_LENGTH_3] = 10;
	}

	// Effacement RAM2
	for (i = 0; i < DMA_TEST_LENGTH_3; i++) {
		*(unsigned char *)(RAM2_BASE + ram2_offset + i) = 0;
		*(unsigned char *)(RAM2_BASE + ram2_offset + i + DMA_TEST_LENGTH_3) = 0;
	}
	
	// Desactivation requetes DMA
	*(unsigned char *)DMA_CONFIG_REG = 0;	

	// DMA configuration pour transferer la RAM1 vers la RAM2 en utilisant CH0 et CH1
	*(unsigned char *)CH0_DMA_ADDR = (unsigned char)(ram1_test_data);
	*(unsigned char *)CH0_DMA_ADDR = (unsigned char)((unsigned int)ram1_test_data >> 8);
	*(unsigned char *)CH0_DMA_TC = (unsigned char)(DMA_TEST_LENGTH_3 - 1);
	*(unsigned char *)CH0_DMA_TC = (unsigned char)((((unsigned int)(DMA_TEST_LENGTH_3 - 1)) >> 8) | DMA_WR_MODE);

	*(unsigned char *)CH1_DMA_ADDR = (unsigned char)(ram1_test_data + DMA_TEST_LENGTH_3);
	*(unsigned char *)CH1_DMA_ADDR = (unsigned char)((unsigned int)(ram1_test_data + DMA_TEST_LENGTH_3) >> 8);
	*(unsigned char *)CH1_DMA_TC = (unsigned char)(DMA_TEST_LENGTH_3 - 1);
	*(unsigned char *)CH1_DMA_TC = (unsigned char)((((unsigned int)(DMA_TEST_LENGTH_3 - 1)) >> 8) | DMA_WR_MODE);
	
	// Transfert avec TC_STOP
	// Start DMA request. La valeur ecrite n'a pas de signification
	*(unsigned char *)TRIGGER_DMA_CH0 = 0;
	*(unsigned char *)TRIGGER_DMA_CH1 = 0;
	
	// activation CH1 et TC stop
	*(unsigned char *)DMA_CONFIG_REG = EN_CH1 | TC_STOP;

	// Pool DMA status jusqu'à ce que TC=1
	while ((dma_status_reg_value & TC_STATUS_CH1) != TC_STATUS_CH1) {
		dma_status_reg_value = *(volatile unsigned char *)DMA_STATUS_REG;
	}

	// activation CH0 et TC stop
	*(unsigned char *)DMA_CONFIG_REG = EN_CH0 | TC_STOP;

	// Pool DMA status jusqu'à ce que TC=1
	while ((dma_status_reg_value & TC_STATUS_CH0) != TC_STATUS_CH0) {
		dma_status_reg_value = *(volatile unsigned char *)DMA_STATUS_REG;
	}

	// Arret requete DMA.
	*(unsigned char *)CANCEL_DMA_CH0 = 0;
	*(unsigned char *)CANCEL_DMA_CH1 = 0;
		
	// Relecture RAM 2 après les transferts DMA
	for (i = 0; i < DMA_TEST_LENGTH_3*2; i++) {
		if (*(unsigned char *)(RAM2_BASE + ram2_offset + i) != ram1_test_data[i]) {
			error_code = 16;
		}
	}
}

// RAM1  = I/O device
// RAM2  = memory device
// Rotating priority cas 1
// Transfert de 2*20 octets de RAM1 vers RAM2 en utilisant CH0 puis CH1 avec rotation de priorité
// CH0 / CH1 activés et autorises, TC_STOP = 1, RP=1, DMA_WR (de RAM1 (I/O RD) vers RAM2 (WR)), RP=0
// => On doit faire le transfert alterne entre CH0 et CH1 à chaque cycle DMA
void Test_9()
{
	unsigned int i, ram2_offset;
	unsigned char dma_status_reg_value;	
	
	test_step = 9;
	
	ram2_offset = ram1_test_data - RAM1_BASE;	
	
	// Remplissage RAM1
	for (i=0; i < DMA_TEST_LENGTH_3; i++) {
		ram1_test_data[i] = 9;
		ram1_test_data[i + DMA_TEST_LENGTH_3] = 10;
	}

	// Effacement RAM2
	for (i = 0; i < DMA_TEST_LENGTH_3; i++) {
		*(unsigned char *)(RAM2_BASE + ram2_offset + i) = 0;
		*(unsigned char *)(RAM2_BASE + ram2_offset + i + DMA_TEST_LENGTH_3) = 0;
	}	

	// Desactivation requetes DMA
	*(unsigned char *)DMA_CONFIG_REG = 0;

	// DMA configuration pour transferer la RAM1 vers la RAM2 en utilisant CH0 et CH1
	*(unsigned char *)CH0_DMA_ADDR = (unsigned char)(ram1_test_data);
	*(unsigned char *)CH0_DMA_ADDR = (unsigned char)((unsigned int)ram1_test_data >> 8);
	*(unsigned char *)CH0_DMA_TC = (unsigned char)(DMA_TEST_LENGTH_3 - 1);
	*(unsigned char *)CH0_DMA_TC = (unsigned char)((((unsigned int)(DMA_TEST_LENGTH_3 - 1)) >> 8) | DMA_WR_MODE);

	*(unsigned char *)CH1_DMA_ADDR = (unsigned char)(ram1_test_data + DMA_TEST_LENGTH_3);
	*(unsigned char *)CH1_DMA_ADDR = (unsigned char)((unsigned int)(ram1_test_data + DMA_TEST_LENGTH_3) >> 8);
	*(unsigned char *)CH1_DMA_TC = (unsigned char)(DMA_TEST_LENGTH_3 - 1);
	*(unsigned char *)CH1_DMA_TC = (unsigned char)((((unsigned int)(DMA_TEST_LENGTH_3 - 1)) >> 8) | DMA_WR_MODE);
	
	// Transfert avec TC_STOP
	// Start DMA request. La valeur ecrite n'a pas de signification
	*(unsigned char *)TRIGGER_DMA_CH0 = 0;
	*(unsigned char *)TRIGGER_DMA_CH1 = 0;
	
	// activation CH0/CH1, RP et TC stop
	*(unsigned char *)DMA_CONFIG_REG = ROTATING_PRIO | EN_CH0 | EN_CH1 | TC_STOP;

	// Pool DMA status jusqu'à ce que TC=1
	while ((dma_status_reg_value & (TC_STATUS_CH0 | TC_STATUS_CH1)) != (TC_STATUS_CH0 | TC_STATUS_CH1)) {
		dma_status_reg_value = *(volatile unsigned char *)DMA_STATUS_REG;
	}

	// Arret requete DMA.
	*(unsigned char *)CANCEL_DMA_CH0 = 0;
	*(unsigned char *)CANCEL_DMA_CH1 = 0;
		
	// Relecture RAM 2 après les transferts DMA
	for (i = 0; i < DMA_TEST_LENGTH_3*2; i++) {
		if (*(unsigned char *)(RAM2_BASE + ram2_offset + i) != ram1_test_data[i]) {
			error_code = 16;
		}
	}
}

// RAM1  = I/O device
// RAM2  = memory device
// Rotating priority avec CH0..3
// Transfert de 4*20 octets de RAM1 vers RAM2 en utilisant CH0 à CH3 avec rotation de priorité
// CH0..3 activés et autorises, TC_STOP = 1, RP=1, DMA_WR (de RAM1 (I/O RD) vers RAM2 (WR)), RP=0
// => On doit faire le transfert alterne entre CH0..3 à chaque cycle DMA
void Test_10()
{
	unsigned int i, ram2_offset;
	unsigned char dma_status_reg_value;	
	
	test_step = 10;
	
	ram2_offset = ram1_test_data - RAM1_BASE;	
	
	// Remplissage RAM1
	for (i=0; i < DMA_TEST_LENGTH_3; i++) {
		ram1_test_data[i] = 11;
		ram1_test_data[i + DMA_TEST_LENGTH_3] = 12;
		ram1_test_data[i + 2*DMA_TEST_LENGTH_3] = 13;
		ram1_test_data[i + 3*DMA_TEST_LENGTH_3] = 14;
	}

	// Effacement RAM2
	for (i = 0; i < 4*DMA_TEST_LENGTH_3; i++) {
		*(unsigned char *)(RAM2_BASE + ram2_offset + i) = 0;
	}	

	// Desactivation requetes DMA
	*(unsigned char *)DMA_CONFIG_REG = 0;

	// DMA configuration pour transferer la RAM1 vers la RAM2 en utilisant CH0 et CH1
	*(unsigned char *)CH0_DMA_ADDR = (unsigned char)(ram1_test_data);
	*(unsigned char *)CH0_DMA_ADDR = (unsigned char)((unsigned int)ram1_test_data >> 8);
	*(unsigned char *)CH0_DMA_TC = (unsigned char)(DMA_TEST_LENGTH_3 - 1);
	*(unsigned char *)CH0_DMA_TC = (unsigned char)((((unsigned int)(DMA_TEST_LENGTH_3 - 1)) >> 8) | DMA_WR_MODE);

	*(unsigned char *)CH1_DMA_ADDR = (unsigned char)(ram1_test_data + DMA_TEST_LENGTH_3);
	*(unsigned char *)CH1_DMA_ADDR = (unsigned char)((unsigned int)(ram1_test_data + DMA_TEST_LENGTH_3) >> 8);
	*(unsigned char *)CH1_DMA_TC = (unsigned char)(DMA_TEST_LENGTH_3 - 1);
	*(unsigned char *)CH1_DMA_TC = (unsigned char)((((unsigned int)(DMA_TEST_LENGTH_3 - 1)) >> 8) | DMA_WR_MODE);
	
	*(unsigned char *)CH2_DMA_ADDR = (unsigned char)(ram1_test_data + 2*DMA_TEST_LENGTH_3);
	*(unsigned char *)CH2_DMA_ADDR = (unsigned char)((unsigned int)(ram1_test_data + 2*DMA_TEST_LENGTH_3) >> 8);
	*(unsigned char *)CH2_DMA_TC = (unsigned char)(DMA_TEST_LENGTH_3 - 1);
	*(unsigned char *)CH2_DMA_TC = (unsigned char)((((unsigned int)(DMA_TEST_LENGTH_3 - 1)) >> 8) | DMA_WR_MODE);

	*(unsigned char *)CH3_DMA_ADDR = (unsigned char)(ram1_test_data + 3*DMA_TEST_LENGTH_3);
	*(unsigned char *)CH3_DMA_ADDR = (unsigned char)((unsigned int)(ram1_test_data + 3*DMA_TEST_LENGTH_3) >> 8);
	*(unsigned char *)CH3_DMA_TC = (unsigned char)(DMA_TEST_LENGTH_3 - 1);
	*(unsigned char *)CH3_DMA_TC = (unsigned char)((((unsigned int)(DMA_TEST_LENGTH_3 - 1)) >> 8) | DMA_WR_MODE);	
	
	// Transfert avec TC_STOP
	// Start DMA request. La valeur ecrite n'a pas de signification
	*(unsigned char *)TRIGGER_DMA_CH0 = 0;
	*(unsigned char *)TRIGGER_DMA_CH1 = 0;
	*(unsigned char *)TRIGGER_DMA_CH2 = 0;
	*(unsigned char *)TRIGGER_DMA_CH3 = 0;
	
	// activation CH0/CH1, RP et TC stop
	*(unsigned char *)DMA_CONFIG_REG = ROTATING_PRIO | EN_CH0 | EN_CH1 | EN_CH2 | EN_CH3 | TC_STOP;

	// Pool DMA status jusqu'à ce que TC=1
	dma_status_reg_value = *(volatile unsigned char *)DMA_STATUS_REG;
	while ((dma_status_reg_value & (TC_STATUS_CH0 | TC_STATUS_CH1 | TC_STATUS_CH2 | TC_STATUS_CH3)) != 
		(TC_STATUS_CH0 | TC_STATUS_CH1 | TC_STATUS_CH2 | TC_STATUS_CH3)) {
		dma_status_reg_value = *(volatile unsigned char *)DMA_STATUS_REG;
	}

	// Arret requete DMA.
	*(unsigned char *)CANCEL_DMA_CH0 = 0;
	*(unsigned char *)CANCEL_DMA_CH1 = 0;
	*(unsigned char *)CANCEL_DMA_CH2 = 0;
	*(unsigned char *)CANCEL_DMA_CH3 = 0;
		
	// Relecture RAM 2 après les transferts DMA
	for (i = 0; i < DMA_TEST_LENGTH_3*4; i++) {
		if (*(unsigned char *)(RAM2_BASE + ram2_offset + i) != ram1_test_data[i]) {
			error_code = 17;
		}
	}
}

// RAM1  = I/O device
// RAM2  = memory device
// Rotating priority avec CH1..3
// Transfert de 3*20 octets de RAM1 vers RAM2 en utilisant CH1 à CH3 avec rotation de priorité
// CH1..3 activés et autorises, CH0 desactive, TC_STOP = 1, RP=1, DMA_WR (de RAM1 (I/O RD) vers RAM2 (WR)), RP=1
// => On doit faire le transfert alterne entre CH1..3 à chaque cycle DMA
// Verifier que TC remonte bien sur le canal DMA qui correspond au DACKn
void Test_11()
{
	unsigned int i, ram2_offset;
	unsigned char dma_status_reg_value;	
	
	test_step = 11;
	
	ram2_offset = ram1_test_data - RAM1_BASE;	
	
	// Remplissage RAM1
	for (i=0; i < DMA_TEST_LENGTH_3; i++) {
		ram1_test_data[i] = 11;
		ram1_test_data[i + DMA_TEST_LENGTH_3] = 12;
		ram1_test_data[i + 2*DMA_TEST_LENGTH_3] = 13;
		ram1_test_data[i + 3*DMA_TEST_LENGTH_3] = 14;
	}

	// Effacement RAM2
	for (i = 0; i < 4*DMA_TEST_LENGTH_3; i++) {
		*(unsigned char *)(RAM2_BASE + ram2_offset + i) = 0;
	}	

	// Desactivation requetes DMA
	*(unsigned char *)DMA_CONFIG_REG = 0;

	// DMA configuration pour transferer la RAM1 vers la RAM2 en utilisant CH0 et CH1
	*(unsigned char *)CH1_DMA_ADDR = (unsigned char)(ram1_test_data + DMA_TEST_LENGTH_3);
	*(unsigned char *)CH1_DMA_ADDR = (unsigned char)((unsigned int)(ram1_test_data + DMA_TEST_LENGTH_3) >> 8);
	*(unsigned char *)CH1_DMA_TC = (unsigned char)(DMA_TEST_LENGTH_3 - 1);
	*(unsigned char *)CH1_DMA_TC = (unsigned char)((((unsigned int)(DMA_TEST_LENGTH_3 - 1)) >> 8) | DMA_WR_MODE);
	
	*(unsigned char *)CH2_DMA_ADDR = (unsigned char)(ram1_test_data + 2*DMA_TEST_LENGTH_3);
	*(unsigned char *)CH2_DMA_ADDR = (unsigned char)((unsigned int)(ram1_test_data + 2*DMA_TEST_LENGTH_3) >> 8);
	*(unsigned char *)CH2_DMA_TC = (unsigned char)(DMA_TEST_LENGTH_3 - 1);
	*(unsigned char *)CH2_DMA_TC = (unsigned char)((((unsigned int)(DMA_TEST_LENGTH_3 - 1)) >> 8) | DMA_WR_MODE);

	*(unsigned char *)CH3_DMA_ADDR = (unsigned char)(ram1_test_data + 3*DMA_TEST_LENGTH_3);
	*(unsigned char *)CH3_DMA_ADDR = (unsigned char)((unsigned int)(ram1_test_data + 3*DMA_TEST_LENGTH_3) >> 8);
	*(unsigned char *)CH3_DMA_TC = (unsigned char)(DMA_TEST_LENGTH_3 - 1);
	*(unsigned char *)CH3_DMA_TC = (unsigned char)((((unsigned int)(DMA_TEST_LENGTH_3 - 1)) >> 8) | DMA_WR_MODE);	
	
	// Transfert avec TC_STOP
	// Start DMA request. La valeur ecrite n'a pas de signification
	*(unsigned char *)TRIGGER_DMA_CH1 = 0;
	*(unsigned char *)TRIGGER_DMA_CH2 = 0;
	*(unsigned char *)TRIGGER_DMA_CH3 = 0;
	
	// activation CH0/CH1, RP et TC stop
	*(unsigned char *)DMA_CONFIG_REG = ROTATING_PRIO | EN_CH1 | EN_CH2 | EN_CH3 | TC_STOP;

	// Pool DMA status jusqu'à ce que TC=1
	while ((dma_status_reg_value & (TC_STATUS_CH1 | TC_STATUS_CH2 | TC_STATUS_CH3)) != 
		(TC_STATUS_CH1 | TC_STATUS_CH2 | TC_STATUS_CH3)) {
		dma_status_reg_value = *(volatile unsigned char *)DMA_STATUS_REG;
	}

	// Arret requete DMA.
	*(unsigned char *)CANCEL_DMA_CH1 = 0;
	*(unsigned char *)CANCEL_DMA_CH2 = 0;
	*(unsigned char *)CANCEL_DMA_CH3 = 0;
		
	// Relecture RAM 2 après les transferts DMA
	for (i = DMA_TEST_LENGTH_3; i < DMA_TEST_LENGTH_3*3; i++) {
		if (*(unsigned char *)(RAM2_BASE + ram2_offset + i) != ram1_test_data[i]) {
			error_code = 18;
		}
	}
}

// RAM1  = I/O device
// RAM2  = memory device
// Test du mode AUTOLOAD
// Transfert de 20 octets de RAM1 vers RAM2 en utilisant CH2 et AUTOLOAD
// => On doit refaire le transfert en utilisant CH2
// A vérifier que:
// l'update flag est positionné en fin de dernier cycle avant autoreload (en même temps que le TC)
// et qu'il est resetté à la fin du premier cycle après l'autoreload.
// Le flag TC est positionné à la fin de chaque transfert
void Test_12()
{
	unsigned int i, j, ram2_offset;
	unsigned char dma_status_reg_value;	
	
	test_step = 12;
	
	ram2_offset = ram1_test_data - RAM1_BASE;	
	
	// Remplissage RAM1
	for (i=0; i < DMA_TEST_LENGTH_3; i++) {
		ram1_test_data[i] = 15;
	}

	// Effacement RAM2
	for (i = 0; i < DMA_TEST_LENGTH_3; i++) {
		*(unsigned char *)(RAM2_BASE + ram2_offset + i) = 0;
	}	

	// Desactivation requetes DMA
	*(unsigned char *)DMA_CONFIG_REG = 0;

	// DMA configuration pour transferer la RAM1 vers la RAM2 en utilisant CH0 et CH1
	*(unsigned char *)CH2_DMA_ADDR = (unsigned char)(ram1_test_data);
	*(unsigned char *)CH2_DMA_ADDR = (unsigned char)((unsigned int)(ram1_test_data) >> 8);
	*(unsigned char *)CH2_DMA_TC = (unsigned char)(DMA_TEST_LENGTH_3 - 1);
	*(unsigned char *)CH2_DMA_TC = (unsigned char)((((unsigned int)(DMA_TEST_LENGTH_3 - 1)) >> 8) | DMA_WR_MODE);

	*(unsigned char *)CH3_DMA_ADDR = (unsigned char)(ram1_test_data);
	*(unsigned char *)CH3_DMA_ADDR = (unsigned char)((unsigned int)(ram1_test_data) >> 8);
	*(unsigned char *)CH3_DMA_TC = (unsigned char)(DMA_TEST_LENGTH_3 - 1);
	*(unsigned char *)CH3_DMA_TC = (unsigned char)((((unsigned int)(DMA_TEST_LENGTH_3 - 1)) >> 8) | DMA_WR_MODE);	
	
	// Configuration AUTORELOAD pour la simulation des bursts. La valeur ecrite n'a pas de signification
	*(unsigned char *)SET_CH2_MODE_TO_AUTORELOAD = 0;
	
	// Transfert avec TC_STOP
	// Start DMA request. La valeur ecrite n'a pas de signification
	*(unsigned char *)TRIGGER_DMA_CH2 = 0;
	
	// activation CH0/CH1, RP et TC stop
	*(unsigned char *)DMA_CONFIG_REG = AUTOLOAD | EN_CH2 | TC_STOP;
	
	for (j=0; j < 100; j++) {}
	
	// Desactivation auto reload
	*(unsigned char *)DMA_CONFIG_REG = EN_CH2 | TC_STOP;
	
	// Arret requete DMA.
	*(unsigned char *)CANCEL_DMA_CH2 = 0;
	
	for (i = DMA_TEST_LENGTH_3; i < DMA_TEST_LENGTH_3; i++) {
		if (*(unsigned char *)(RAM2_BASE + ram2_offset + i) != ram1_test_data[i]) {
			error_code = 19;
		}
	}
}


void main()
{
	unsigned int i, j, dma_addr_low, dma_addr_high, ram2_offset;
	
	// Premiere instruction pour pouvoir repérer facilement l'adresse de error_code
	error_code = 0;
	test_step = 0;
	
	//Test_1();
	
	//Test_2();
	
	//Test_2_1();
	
	//Test_3();
	
	//Test_4();
	
	//Test_5();
	
	//Test_6();
	
	//Test_7();
	
	//Test_8();
	
	//Test_9();
	
	//Test_10();
	
	//Test_11();
	
	Test_12();
	
}
