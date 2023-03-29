# tinycalc
Console-based calculator program that fits into the minimum Windows 10 Portable Executable size of 268 bytes. Tested from Windows XP SP2 to Windows 10.

# Use and caveats
The four basic operations (addition, subtraction, multiplication, division) are supported. There is no real argument parsing that I could fit into the program, so it relies on jumping 10 characters forward from the start of the command line input to get to the argument. For example:
- **(64-bit Windows)** tinycalc 25*10: outputs 250
- **(32-bit Windows)** tinycalc  25*10 (two spaces): outputs 250
- **(32-bit Windows)** tinycalc 25*10 (one space): outputs 50

Numerous parts of the PE header are overwritten and jumped over in order to fit the code. An ordinal import of `printf` is used for output, along with another ordinal import of the `exit` to avoid a crash message on XP.