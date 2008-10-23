;/*
;	FreeRTOS.org V5.0.4 - Copyright (C) 2003-2008 Richard Barry.
;
;	This file is part of the FreeRTOS.org distribution.
;
;	FreeRTOS.org is free software; you can redistribute it and/or modify
;	it under the terms of the GNU General Public License as published by
;	the Free Software Foundation; either version 2 of the License, or
;	(at your option) any later version.
; 
;	FreeRTOS.org is distributed in the hope that it will be useful,
;	but WITHOUT ANY WARRANTY; without even the implied warranty of
;	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;	GNU General Public License for more details.
;
;	You should have received a copy of the GNU General Public License
;	along with FreeRTOS.org; if not, write to the Free Software
;	Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
;
;	A special exception to the GPL can be applied should you wish to distribute
;	a combined work that includes FreeRTOS.org, without being obliged to provide
;	the source code for any proprietary components.  See the licensing section 
;	of http://www.FreeRTOS.org for full details of how and when the exception
;	can be applied.
;
;   ***************************************************************************
;   ***************************************************************************
;   *                                                                         *
;   * SAVE TIME AND MONEY!  We can port FreeRTOS.org to your own hardware,    *
;   * and even write all or part of your application on your behalf.          *
;   * See http://www.OpenRTOS.com for details of the services we provide to   *
;   * expedite your project.                                                  *
;   *                                                                         *
;   ***************************************************************************
;   ***************************************************************************
;
;	Please ensure to read the configuration and relevant port sections of the
;	online documentation.
;
;	http://www.FreeRTOS.org - Documentation, latest information, license and 
;	contact details.
;
;	http://www.SafeRTOS.com - A version that is certified for use in safety 
;	critical systems.
;
;	http://www.OpenRTOS.com - Commercial support, development, porting, 
;	licensing and training services.
;*/

	INCLUDE portmacro.inc

	IMPORT	vTaskSwitchContext
	IMPORT	vTaskIncrementTick

	EXPORT	vPortYieldProcessor
	EXPORT	vPortStartFirstTask
	EXPORT	vPreemptiveTick
	EXPORT	vPortYield


VICVECTADDR	EQU	0xFFFFF030
T0IR		EQU	0xE0004000
T0MATCHBIT	EQU	0x00000001

	ARM
	AREA	PORT_ASM, CODE, READONLY



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Starting the first task is done by just restoring the context 
; setup by pxPortInitialiseStack
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
vPortStartFirstTask

	PRESERVE8

	portRESTORE_CONTEXT

vPortYield

	PRESERVE8

	SVC 0
	bx lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Interrupt service routine for the SWI interrupt.  The vector table is
; configured in the startup.s file.
;
; vPortYieldProcessor() is used to manually force a context switch.  The
; SWI interrupt is generated by a call to taskYIELD() or portYIELD().
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

vPortYieldProcessor

	PRESERVE8

	; Within an IRQ ISR the link register has an offset from the true return 
	; address, but an SWI ISR does not.  Add the offset manually so the same 
	; ISR return code can be used in both cases.
	ADD	LR, LR, #4

	; Perform the context switch.
	portSAVE_CONTEXT					; Save current task context				
	LDR R0, =vTaskSwitchContext			; Get the address of the context switch function
	MOV LR, PC							; Store the return address
	BX	R0								; Call the contedxt switch function
	portRESTORE_CONTEXT					; restore the context of the selected task	



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Interrupt service routine for preemptive scheduler tick timer
; Only used if portUSE_PREEMPTION is set to 1 in portmacro.h
;
; Uses timer 0 of LPC21XX Family
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	

vPreemptiveTick

	PRESERVE8

	portSAVE_CONTEXT					; Save the context of the current task.	

	LDR R0, =vTaskIncrementTick			; Increment the tick count.  
	MOV LR, PC							; This may make a delayed task ready
	BX R0								; to run.
	
	LDR R0, =vTaskSwitchContext			; Find the highest priority task that 
	MOV LR, PC							; is ready to run.
	BX R0
	
	MOV R0, #T0MATCHBIT					; Clear the timer event
	LDR R1, =T0IR
	STR R0, [R1] 

	LDR	R0, =VICVECTADDR				; Acknowledge the interrupt	
	STR	R0,[R0]

	portRESTORE_CONTEXT					; Restore the context of the highest 
										; priority task that is ready to run.
	END

