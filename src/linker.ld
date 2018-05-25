ENTRY(start)

SECTIONS {
  
  .boot 0x100000 : AT (0x100000)
  {
    __boot_st = .;
    /* multiboot header at the start */
    *(.header)
    . = ALIGN(4096);

    *mbheader.o(*);
    *boot.o(*);
    *lmstart.o(*);

    /* align start of .text section to 2M */
    . = ALIGN(2M);
    __boot_en = .;
  }

  __kern_st = .;

  /* this is at 0x100000 + (boot_en - boot_st) */
  .text 0xFFFFFFFF80000000 : AT (0x100000 + SIZEOF(.boot))
  {
    *(.text)
    . = ALIGN(4096);
  }

  .bss :
  {
    *(.bss)

     *(COMMON)
    . = ALIGN(4096);
  }
  
  __kern_en = (. - 0xFFFFFFFF80000000 + 0x100000 + SIZEOF(.boot));
}