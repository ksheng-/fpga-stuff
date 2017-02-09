@echo off
set xv_path=D:\\Xilinx\\Vivado\\2016.4\\bin
call %xv_path%/xelab  -wto b720a45f70fd4a45814052a1fdcb7d19 -m64 --debug typical --relax --mt 2 -L xil_defaultlib -L secureip --snapshot fpmultiplier_tb_behav xil_defaultlib.fpmultiplier_tb -log elaborate.log
if "%errorlevel%"=="0" goto SUCCESS
if "%errorlevel%"=="1" goto END
:END
exit 1
:SUCCESS
exit 0
