#-----------------------------------------------------------------------------
#  Nazik Ormanlar - Basys3 Refleks Oyunu
#  Vivado projesini SIFIRDAN olusturur. Herkes kendi bilgisayarinda calistirir.
#
#  KULLANIM
#    1) Bu klasorun tamamini Drive'dan indir (kaynak/, testbench/, bu dosya)
#    2) Klasoru KISA ve TURKCE KARAKTERSIZ bir yola koy, ornek:  C:\fpga\nazik
#    3) Vivado -> Tools -> Run Tcl Script...  ve bu dosyayi sec
#       (veya Tcl Console'a:  cd C:/fpga/nazik ; source proje_olustur.tcl )
#
#  Proje klasoru bu dosyanin yaninda olusur. Drive'a SADECE kaynak/ ve
#  testbench/ klasorlerini geri yukleyin - olusan proje klasorunu ASLA.
#-----------------------------------------------------------------------------

set proje_adi "Nazik_Ormanlar_Proje"
set part_no   "xc7a35tcpg236-1"
set kok [file normalize [file dirname [info script]]]

create_project $proje_adi "$kok/$proje_adi" -part $part_no -force

add_files -fileset sources_1 [glob -nocomplain "$kok/kaynak/*.v"]
add_files -fileset sim_1     [glob -nocomplain "$kok/testbench/*.v"]
add_files -fileset constrs_1 [glob -nocomplain "$kok/kaynak/*.xdc"]

set_property top top    [get_filesets sources_1]
set_property top top_tb [get_filesets sim_1]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# Simulasyon bastan sona koşsun. Vivado'nun varsayilani 1000 ns; testbench'ler
# 1 ms oyun zamanini 100 ns'ye sikistirsa bile 1000 ns ilk kontrole bile
# yetmiyor ve "hicbir sey olmadi" gibi gorunuyor. Testbench'lerde $finish var,
# "all" verince kendi kendilerine duruyorlar.
set_property -name {xsim.simulate.runtime} -value {all} -objects [get_filesets sim_1]

puts ""
puts "==============================================="
puts " Proje olusturuldu: $kok/$proje_adi"
puts " Sentez top   : top"
puts " Simulasyon   : top_tb  (baska bir tb calistirmak icin"
puts "                sag tik -> Set as Top)"
puts " Sim suresi   : all  (Run Behavioral Simulation yeter,"
puts "                'run all' yazmaya gerek yok)"
puts "==============================================="
