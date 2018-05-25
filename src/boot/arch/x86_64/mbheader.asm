section .header
header_start:
  dd 0xe85250d6                ; multiboot magic value
  dd 0                         ; arch 0, protected i386
  dd header_end - header_start ; header length
  ; header checksum
  dd 0x100000000 - (0xe85250d6 + 0 + (header_end - header_start)) 

  ; header end tags
  dw 0 ; type
  dw 0 ; flags
  dd 8 ; size
header_end:
