


-fI -o "$(OutputFileName).hex"
-m "$(OutputFileName).map"
-l "$(OutputFileName).lss"
-S "$(OutputFileName).tmp"
-W+ie
-I"C:\Program Files (x86)\Atmel\Studio\7.0\Packs\atmel\ATmega_DFP\1.2.209\avrasm\inc" 
-im328PBdef.inc
-d "$(OutputDir)/$(OutputFileName).obj"
"$(EntryFile)" 