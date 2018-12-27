make
echo "----------"
cd bin
./compiler $1 > asm
./maszyna-rejestrowa asm
echo "----------"
cd ..
