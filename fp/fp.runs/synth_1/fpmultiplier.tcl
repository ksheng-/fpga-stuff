# 
# Synthesis run script generated by Vivado
# 

set_msg_config -id {Common 17-41} -limit 10000000
set_msg_config -id {HDL 9-1061} -limit 100000
set_msg_config -id {HDL 9-1654} -limit 100000
create_project -in_memory -part xc7z020clg484-1

set_param project.singleFileAddWarning.threshold 0
set_param project.compositeFile.enableAutoGeneration 0
set_param synth.vivado.isSynthRun true
set_property webtalk.parent_dir D:/Users/Kevin/Documents/VHDL/fp/fp.cache/wt [current_project]
set_property parent.project_path D:/Users/Kevin/Documents/VHDL/fp/fp.xpr [current_project]
set_property default_lib xil_defaultlib [current_project]
set_property target_language VHDL [current_project]
set_property board_part em.avnet.com:zed:part0:1.3 [current_project]
set_property ip_output_repo d:/Users/Kevin/Documents/VHDL/fp/fp.cache/ip [current_project]
set_property ip_cache_permissions {read write} [current_project]
read_vhdl -library xil_defaultlib D:/Users/Kevin/Documents/VHDL/fp/fp.srcs/sources_1/new/fpmultiplier.vhd
foreach dcp [get_files -quiet -all *.dcp] {
  set_property used_in_implementation false $dcp
}

synth_design -top fpmultiplier -part xc7z020clg484-1


write_checkpoint -force -noxdef fpmultiplier.dcp

catch { report_utilization -file fpmultiplier_utilization_synth.rpt -pb fpmultiplier_utilization_synth.pb }
