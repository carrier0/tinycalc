bits 32
base equ 0x400000

;IMAGE_DOS_HEADER
dos:
	dw "MZ"       			; e_magic
	dw 0				; e_cblp

;IMAGE_NT_HEADERS
ntsig:
	dd "PE"				; Signature

;IMAGE_FILE_HEADER
filehdr:
	dw 0x014C            		; Machine
	dw 1                 		; NumberOfSections
	
	init:
	xor esi, esi	     		; OVERWRITTEN:
	mov eax, [fs:30h+esi]		; PointerToSymbolTable, 
	mov eax, [eax+10h]   		; NumberOfSymbols,
	jmp init_2                      ; NumberOfSymbols
	db 0 

	dw opthdrsize        		; SizeOfOptionalHeader
	dw 0x103             		; Characteristics


;IMAGE_OPTIONAL_HEADER
opthdr:
	dw 0x10b                    	; Magic

	init_2:			    
	mov esi, [eax+44h]          	; OVERWRITTEN: MajorLinkerVersion,
	add esi, 20                 	; MinorLinkerVersion,
	cld                         	; SizeOfCode,
	xor ecx, ecx                	; SizeOfInitializedData,
	jmp precalc                 	; SizeOfUninitializedData
	format: db "%d", 0

	; Storing the address of UNICODE_STRING from PEB
	; into esi - equivalent to GetCommandLineW
	; No real argument parsing

	dd init                     	; AddressOfEntryPoint
	
precalc:
	xor edx, edx			; OVERWRITTEN:
	xor eax, eax			; 
	jmp calc_1			; BaseOfCode,
	dw 0		    		; BaseOfData
	
	; More required sections
	dd base                     	; ImageBase
	dd 4			    	; e_lfanew  ; SectionAlignment
	dd 4                        	; FileAlignment

calc_1:
	lodsw                       	; OVERWRITTEN:
	test eax, eax               	; MajorOperatingSystemVersion,
	je finish                   	; MinorOperatingSystemVersion,
	jmp calc_2               	; MajorImageVersion, MinorImageVersion
	
	; Next character loaded into eax and tested for null

	dw 4                        	; MajorSubsystemVersion

	opset:
	mov ebx, eax                	; OVERWRITTEN:
	mov ecx, edx                	; MinorSubsystemVersion,
	jmp precalc                     ; Win32VersionValue

	; Possible operation character stored into ebx and then
	; skipped over

	; Difficult to overwrite sections
	dd 1024                     	; SizeOfImage
	dd 1			    	; SizeOfHeaders
	dd 0			    	; CheckSum
	dw 3                        	; Subsystem (Console)
	dw 0                        	; DllCharacteristics
	dd 0                        	; SizeOfStackReserve
	dd 0                        	; SizeOfStackCommit
	dd 0                        	; SizeOfHeapReserve
	
	addnum:				; OVERWRITTEN:
	sub eax, 0x30			; SizeOfHeapCommit,
	add edx, eax			; LoaderFlags
	jmp calc_1
	db 0

	dd 2                        	; NumberOfRvaAndSizes

; IMAGE_DIRECTORY_ENTRIES
calc_2:
	cmp eax, 0x3A
	jge fail			; OVERWRITTEN:
	jmp calc_3			; EXPORT
	db 0

	dd idata, 0			; IMPORT

opthdrsize equ $ - opthdr

; IMAGE_SECTION_HEADER
calc_3:
	cmp eax, 0x30
	jl opset			; OVERWRITTEN:
	jmp calc_4			; Name
	db 0

	dd codesize                 	; VirtualSize
	dd init                     	; VirtualAddress
	dd codesize                 	; SizeOfRawData
	dd init                     	; PointerToRawData

	calc_4:
	imul edx, 0x0A			; OVERWRITTEN:
	jmp addnum			; PointerToRelocations,
					; PointerToLineNumbers,
finish:					; NumberOfRelocations,
	cmp ebx, '+'			; NumberOfLineNumbers
	je addop
	jmp fin2

	dd 0				; Characteristics
					; Must remain 0 for XP compatibility
	fin2:
	cmp ebx, '-'
	je subop
	cmp ebx, '*'
	je mulop
	cmp ebx, '/'
	jne fail

	divop:
	mov eax, ecx
        mov ebx, edx
	xor edx, edx
	idiv ebx
	mov ecx, eax
	jmp printnum
	mulop:
	imul ecx, edx
	jmp printnum
	subop:
	sub ecx, edx
	jmp printnum
	addop:
	add ecx, edx

printnum:
	push ecx
	push base + format
	jmp idata

crt:
	db "crtdll", 0x00		; Importing by ordinal using the shortest
					; named C Runtime dll
; Import Address Table
iat:
printf:	dd 0x800001b8
exit:	dd 0x80000167
        dd 0x00

; Import Table
idata:					; OVERWRITTEN:
print:	call [base + printf]		; OriginalFirstThunk,
fail:	call [base + exit]		; TimeDateStamp, ForwarderChain

	dd crt                      	; Name
	dd iat                      	; FirstThunk

codesize equ $ - init
times 268 - ($-$$) db 0
