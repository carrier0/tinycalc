bits 32
base equ 0x400000

;IMAGE_DOS_HEADER
dos:
	dw "MZ"       	; e_magic
	dw 0		; e_cblp

;IMAGE_NT_HEADERS
ntsig:
	dd "PE"

;IMAGE_FILE_HEADERS
filehdr:
	dw 0x014C            ; Machine
	dw 1                 ; NumberOfSections
	
	init:
	xor esi, esi	     ; PointerToSymbolTable 
	mov eax, [fs:30h+esi]; NumberOfSymbols
	mov eax, [eax+10h]   ; NumberOfSymbols
	jmp init_2
	db 0 

	dw opthdrsize        ; SizeOfOptionalHeader
	dw 0x103             ; Characteristics

;IMAGE_OPTIONAL_HEADER
opthdr:
	dw 0x10b                    ; Magic

	init_2:			    
	mov esi, [eax+44h]          ; OVERWRITTEN: MajorLinkerVersion
	add esi, 20                 ; MinorLinkerVersion,
	cld                         ; SizeOfCode,
	xor ecx, ecx                ; SizeOfInitializedData,
	jmp precalc                    ; SizeOfUninitializedData
	format: db "%d", 0
	

	; Storing address of UNICODE_STRING PEB struct into
	; esi, which is equivalent to GetCommandLineW

	dd init                     ; AddressOfEntryPoint
	
precalc:
	xor edx, edx
	xor eax, eax
	jmp calc_1

	dw 0		    ; BaseOfCode
	;dd 0                        ; BaseOfData
	
	; more required sections
	dd base                     ; ImageBase
	dd 4			    ; e_lfanew  ; SectionAlignment
	dd 4                        ; FileAlignment

calc_1:
	lodsw                       ; MajorOperatingSystemVersion
	test eax, eax               ; MinorOperatingSystemVersion
	je finish                   ; MajorImageVersion
	jmp calc_2               ; MinorImageVersion
	

	dw 4                        ; MajorSubsystemVersion

	opset:
	mov ebx, eax                ; MinorSubsystemVersion
	mov ecx, edx                ; Win32VersionValue
	jmp precalc

	dd 1024                     ; SizeOfImage
	dd 1			    ; SizeOfHeaders          nonzero for Windows XP
	dd 0			    ; CheckSum
	dw 3                        ; Subsystem (Console)
	dw 0                        ; DllCharacteristics
	dd 0                        ; SizeOfStackReserve
	dd 0                        ; SizeOfStackCommit
	dd 0                        ; SizeOfHeapReserve
	
	addnum:
	sub eax, 0x30
	add edx, eax
	jmp calc_1
	db 0        		    ; SizeOfHeapCommit

	dd 2                        ; NumberOfRvaAndSizes

; Data directories (part of optional header)
calc_2:
	cmp eax, 0x3A
	jge badexit
	jmp calc_3
	db 0
				    ; EXPORT
	dd idata, 0                 ; IMPORT

opthdrsize equ $ - opthdr

; IMAGE_SECTION_HEADER
calc_3:
	cmp eax, 0x30
	jl opset
	jmp calc_4
	db 0			    ; Name

	dd codesize                 ; VirtualSize
	dd init                     ; VirtualAddress
	dd codesize                 ; SizeOfRawData
	dd init                     ; PointerToRawData

	; Jumping over required headers

	calc_4:
	imul edx, 0x0A
	jmp addnum

finish:
	cmp ebx, '+'
	je addop
	jmp fin2

	dd 0

	fin2:
	cmp ebx, '-'
	je subop
	cmp ebx, '*'
	je mulop
	cmp ebx, '/'
	jne badexit

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
	db "crtdll", 0x00

; Import Address Table
iat:
printf:	dd 0x800001b8
exit:	dd 0x80000167
        dd 0x00

; Import table (array of IMAGE_IMPORT_DESCRIPTOR structures)
idata:
	print:
	call [base + printf]	; OriginalFirstThunk UNUSED
	badexit:		; TimeDateStamp and ForwarderChain UNUSED
	call [base + exit]
	dd crt                      ; Name
	dd iat                      ; FirstThunk

codesize equ $ - init

times 268 - ($-$$) db 0
