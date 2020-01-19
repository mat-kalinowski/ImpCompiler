# Simple Imperative Language Compiler (Academic Project)

Compiler project made as a final project for academic course - Formal Languages and Techniques of Translation. 

## Simple usage scenario



## Used technologies

- <b>Flex</b> version 2.6.4,
- <b>Bison</b> version 3.0.4,
- <b>g++</b> version 8.2.0,
- <b>GNU Make</b> version 4.2.1.

Compiler has been written in C++ language with parser and lexer made from Bison and Flex ools.

## Compilation

Build process is simplified by GNU make

- `make` to compile source code. Output ready in `bin` directory.
- `make clean` to remove `bin` directory with whole content.

## Uruchamianie kompilatora
Aby uruchomić kompilator należy użyć polecania `./kompilator filename.imp filename.mr`, gdzie:

- `filename.imp` - nazwa pliku z kodem wejściowym,
- `filename.mr` - nazwa pliku z kodem wynikowym.

Jeżeli kompilacja przebiegnie pomyślnie zostanie zwrócony plik z kodem na maszynę rejestrową. W razie wystąpienia błędów w kodzie wejściowym, zostaną wypisane komunikaty o rodzaju znalezionych błędów oraz miejscu ich występowania. W takim przypadku kompilator nie zwraca pliku z kodem wynikowym.

## Interpreter
Do dyspozycji studentów został oddany interpreter prostego kodu maszynowego autorstwa <b>dra Macieja Gębali</b>. Jest on dostępny do pobrania pod tym [linkiem](https://cs.pwr.edu.pl/gebala/dyd/jftt2018/labor4.zip). Interpreter znajduje się również w niniejszym repozytorium w folderze `maszyna_rejestrowa` wraz z plikiem README opisującym sposób kompilacji i uruchomienia.

## Specyfikacja języka
Język przeznaczony dla kompilatora jest opisany następują gramatyką: 

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

Poniżej znajduje się przykładowy program napisany w tym języku:

    [ Rozklad liczby na czynniki pierwsze ]
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

Powyższe gramatyka oraz przykładowy program są autorstwa <b>dra Macieja Gębali</b>. Szczegółowe informacje odnośnie zadania można znaleźć w pliku `labor4.pdf` znajdujacym się w repozytorium.

