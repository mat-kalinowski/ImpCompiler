# Simple Imperative Language Compiler (Academic Project)

Compiler project made as a final project for academic course - Formal Languages and Techniques of Translation. 

## Simple usage scenario


## Used technologies

- <b>Flex</b> version 2.6.4,
- <b>Bison</b> version 3.0.4,
- <b>g++</b> version 8.2.0,
- <b>GNU Make</b> version 4.2.1.

Compiler has been written in C++ language with parser and lexer made from Bison and Flex tools.

## Compilation

Build process is simplified by GNU make

- `make` to compile source code. Output ready in `bin` directory.
- `make clean` to remove `bin` directory with whole content.

## Uruchamianie kompilatora
To run the compiler you have to type `./compiler filename.imp filename.mr`, gdzie:

- `filename.imp` - filename with input code,
- `filename.mr` - filename with output code.

If compilation is carried out successfully the output code is produced. In other case warnings and errors are printed. 

## Interpreter
Interpreter of the output assembly is responsible for executing the code, it was written by our academic teacher - phd. Maciej Gębala. You can find the source code in the interpreter path.

## Language grammar
High level language for which compiler was desgined can be described with following grammar: 

    program      -> DECLARE declarations IN commands END

    declarations -> declarations pidentifier;
                | declarations pidentifier(num:num);
                | 

    commands     -> commands command
                | command

    command      -> identifier := expression;
                | IF condition THEN commands ELSE commands ENDIF
                | IF condition THEN commands ENDIF
                | WHILE condition DO commands ENDWHILE
                | DO commands WHILE condition ENDDO
                | FOR pidentifier FROM value TO value DO commands ENDFOR
                | FOR pidentifier FROM value DOWNTO value DO commands ENDFOR
                | READ identifier;
                | WRITE value;

    expression   -> value
                | value + value
                | value - value
                | value * value
                | value / value
                | value % value

    condition    -> value = value
                | value != value
                | value < value
                | value > value
                | value <= value
                | value >= value

    value        -> num
                | identifier

    identifier   -> pidentifier
                | pidentifier(pidentifier)
                | pidentifier(num)

Sample test programme for specified language:

    [ Factorization of a number into prime factors ]
    
    DECLARE
        n; m; reszta; potega; dzielnik;
    IN
        READ n;
        dzielnik := 2;
        m := dzielnik * dzielnik;
        WHILE n >= m DO
            potega := 0;
            reszta := n % dzielnik;
            WHILE reszta = 0 DO
                n := n / dzielnik;
                potega := potega + 1;
                reszta := n % dzielnik;
            ENDWHILE
            IF potega > 0 THEN [ czy znaleziono dzielnik ]
                WRITE dzielnik;
                WRITE potega;
            ELSE
                dzielnik := dzielnik + 1;
                m := dzielnik * dzielnik;
            ENDIF
        ENDWHILE
        IF n != 1 THEN [ ostatni dzielnik ]
            WRITE n;
            WRITE 1;
        ENDIF
    END

