#######################################################
#                                                     
#  Innovus Command Logging File                     
#  Created on Sat May 20 16:58:26 2023                
#                                                     
#######################################################

#@(#)CDS: Innovus v20.15-s105_1 (64bit) 07/27/2021 14:15 (Linux 2.6.32-431.11.2.el6.x86_64)
#@(#)CDS: NanoRoute 20.15-s105_1 NR210726-1341/20_15-UB (database version 18.20.554) {superthreading v2.14}
#@(#)CDS: AAE 20.15-s020 (64bit) 07/27/2021 (Linux 2.6.32-431.11.2.el6.x86_64)
#@(#)CDS: CTE 20.15-s024_1 () Jul 23 2021 04:46:45 ( )
#@(#)CDS: SYNTECH 20.15-s012_1 () Jul 12 2021 23:29:38 ( )
#@(#)CDS: CPE v20.15-s071
#@(#)CDS: IQuantus/TQuantus 20.1.1-s460 (64bit) Fri Mar 5 18:46:16 PST 2021 (Linux 2.6.32-431.11.2.el6.x86_64)

set_global _enable_mmmc_by_default_flow      $CTE::mmmc_default
suppressMessage ENCEXT-2799
getVersion
win
set init_design_uniquify 1
setDesignMode -process 180
suppressMessage TECHLIB 1318
save_global CHIP.globals
set init_gnd_net GND
set init_lef_file {LEF/umc18_6lm.lef LEF/umc18_6lm_antenna.lef LEF/umc18io3v5v_6lm.lef ../04_MEM/RA1SH.vclef ../04_MEM/RA2SH.vclef}
set init_verilog CHIP_SYN.v
set init_mmmc_file CHIP_mmmc.view
set init_io_file CHIP.io
set init_top_cell CHIP
set init_pwr_net VDD
init_design
getIoFlowFlag
setIoFlowFlag 0
floorPlan -site umc6site -r 0.8 0.694776 250 250 250 250
uiSetTool select
getIoFlowFlag
fit
setDrawView fplan
uiSetTool move
selectInst CORE/inst_RA2SH7
setObjFPlanBox Instance CORE/inst_RA2SH7 546.618 756.609 811.038 954.459
deselectAll
selectInst CORE/inst_RA2SH6
setObjFPlanBox Instance CORE/inst_RA2SH6 910.524 761.846 1174.944 959.696
deselectAll
selectInst CORE/inst_RA2SH5
setObjFPlanBox Instance CORE/inst_RA2SH5 1237.777 772.318 1502.197 970.168
deselectAll
selectInst CORE/inst_RA2SH4
setObjFPlanBox Instance CORE/inst_RA2SH4 1622.625 717.339 1887.045 915.189
zoomBox -2441.98900 -444.38600 3584.00300 2584.91600
zoomBox -3325.07400 -663.71900 3764.32900 2900.16600
pan 1862.94000 2725.30100
deselectAll
selectInst CORE/inst_RA1SH0
setObjFPlanBox Instance CORE/inst_RA1SH0 479.713 1155.279 1792.453 1353.129
deselectAll
selectInst CORE/inst_RA2SH4
setObjFPlanBox Instance CORE/inst_RA2SH4 1528.834 781.285 1793.254 979.135
getIoFlowFlag
setIoFlowFlag 0
floorPlan -site umc6site -r 0.796901518778 0.65 250.6 250.86 250.14 250.32
uiSetTool select
getIoFlowFlag
fit
zoomBox -1497.40700 -249.90000 3716.94700 2371.38700
zoomBox -2015.87300 -424.75100 4118.66100 2659.11600
getIoFlowFlag
setIoFlowFlag 0
floorPlan -site umc6site -r 0.794351279788 0.8 251.26 251.42 250.14 250.32
uiSetTool select
getIoFlowFlag
fit
zoomBox -2125.40400 -408.92600 4009.13000 2674.94100
deselectAll
getIoFlowFlag
setIoFlowFlag 0
floorPlan -site umc6site -r 0.83 0.6 250 250 250 250
uiSetTool select
getIoFlowFlag
fit
zoomBox -1611.37000 -314.00700 3783.18700 2397.86900
getIoFlowFlag
setIoFlowFlag 0
floorPlan -site umc6site -r 0.8 0.7 250.6 250.86 250.14 250.32
uiSetTool select
getIoFlowFlag
fit
getIoFlowFlag
zoomBox 49.29000 484.00800 2316.87400 1623.93600
zoomBox 354.26700 659.95600 1992.59900 1483.55500
zoomBox 572.42600 796.92000 1756.12200 1391.97100
zoomBox 889.61400 996.14500 1414.82800 1260.17300
zoomBox 789.23100 934.03800 1516.17100 1299.47500
zoomBox 561.53700 793.41100 1745.23900 1388.46500
zoomBox 457.40700 729.09900 1849.99700 1429.16200
zoomBox 334.90100 653.43700 1973.24200 1477.04100
zoomBox 190.77500 564.42400 2118.23600 1533.37000
zoomBox 21.21600 459.70200 2288.81700 1599.63900
zoomBox -178.26700 336.50000 2489.50100 1677.60300
zoomBox -412.95100 191.55700 2725.60000 1769.32500
zoomBox -1013.87200 -179.57900 3330.14500 2004.18400
zoomBox -1013.87200 -179.57900 3330.14500 2004.18400
zoomBox -1396.01500 -415.59500 3714.59300 2153.53800
selectObject Module CORE
uiSetTool move
setObjFPlanBox Module CORE -1426.223 -3.073 -61.463 1192.939
undo
getIoFlowFlag
uiSetTool select
getIoFlowFlag
deselectAll
getIoFlowFlag
getIoFlowFlag
setIoFlowFlag 0
floorPlan -site umc6site -r 0.795913020697 0.8 251.26 251.42 250.14 250.32
uiSetTool select
getIoFlowFlag
fit
getIoFlowFlag
setIoFlowFlag 0
floorPlan -site umc6site -r 0.83 0.694767 251.26 251.42 250.14 250.32
uiSetTool select
getIoFlowFlag
fit
getIoFlowFlag
setIoFlowFlag 0
floorPlan -site umc6site -r 0.78 0.75 251.92 251.98 250.14 250.32
uiSetTool select
getIoFlowFlag
fit
getIoFlowFlag
gui_select -rect {752.94900 834.23200 750.34200 862.90800}
uiSetTool move
selectInst CORE/inst_RA2SH7
setObjFPlanBox Instance CORE/inst_RA2SH7 527.458 852.925 791.878 1050.775
deselectAll
selectInst CORE/inst_RA2SH3
setObjFPlanBox Instance CORE/inst_RA2SH3 533.497 544.858 797.917 742.708
deselectAll
selectInst CORE/inst_RA2SH2
setObjFPlanBox Instance CORE/inst_RA2SH2 902.196 537.037 1166.616 734.887
deselectAll
selectInst CORE/inst_RA2SH1
setObjFPlanBox Instance CORE/inst_RA2SH1 1197.9 537.037 1462.32 734.887
deselectAll
selectInst CORE/inst_RA2SH0
setObjFPlanBox Instance CORE/inst_RA2SH0 1522.28 531.823 1786.7 729.673
uiSetTool select
deselectAll
selectInst CORE/inst_RA1SH0
deselectAll
selectInst CORE/inst_RA2SH7
selectInst CORE/inst_RA2SH6
selectInst CORE/inst_RA2SH5
selectInst CORE/inst_RA2SH4
alignObject -side top
alignObject -side middle
spaceObject -fixSide center -space 20
spaceObject -fixSide center -space 50
spaceObject -fixSide center -space 70
spaceObject -fixSide top -space 70
undo
spaceObject -fixSide distHorizontal
spaceObject -fixSide distVertical
spaceObject -fixSide middle -space 70
undo
spaceObject -fixSide left -space 70
spaceObject -fixSide center -space 60
deselectAll
selectInst CORE/inst_RA2SH3
deselectAll
selectInst CORE/inst_RA2SH7
selectInst CORE/inst_RA2SH3
undo
alignObject -side left
deselectAll
selectInst CORE/inst_RA2SH2
selectInst CORE/inst_RA2SH6
alignObject -side left
deselectAll
selectInst CORE/inst_RA2SH1
selectInst CORE/inst_RA2SH5
alignObject -side left
deselectAll
selectInst CORE/inst_RA2SH0
selectInst CORE/inst_RA2SH4
alignObject -side left
deselectAll
selectInst CORE/inst_RA2SH3
selectInst CORE/inst_RA2SH2
selectInst CORE/inst_RA2SH1
selectInst CORE/inst_RA2SH0
alignObject -side top
deselectAll
zoomBox 474.64300 124.16500 4975.62000 2386.83300
pan -1412.81400 -688.79600
zoomBox -505.39600 3.85900 3320.43500 1927.12700
getIoFlowFlag
zoomBox -402.21700 200.55700 2849.74000 1835.33500
uiSetTool ruler
zoomBox 12.79200 699.69000 1710.33400 1553.05400
zoomBox -68.08900 605.29900 1929.01900 1609.25700
zoomBox -561.83500 29.07800 3264.00200 1952.34900
uiSetTool ruler
zoomBox 551.01500 622.89100 2548.12700 1626.85100
zoomBox 1019.97600 873.12800 2246.45300 1489.68500
undo
zoomBox 904.53400 802.06700 2347.44800 1527.42800
zoomBox 414.75300 507.33700 2764.29700 1688.46700
uiSetTool ruler
undo
undo
redo
redo
redo
uiSetTool select
setDrawView ameba
setDrawView fplan
uiSetTool ruler
zoomBox 129.02800 393.89500 2893.19700 1783.45900
uiSetTool select
selectInst CORE/inst_RA2SH7
selectInst CORE/inst_RA2SH6
selectInst CORE/inst_RA2SH5
selectInst CORE/inst_RA2SH4
zoomBox -10.00700 236.38000 2815.66300 1871.16200
deselectAll
selectInst CORE/inst_RA1SH0
selectInst CORE/inst_RA2SH7
selectInst CORE/inst_RA2SH6
selectInst CORE/inst_RA2SH5
selectInst CORE/inst_RA2SH4
selectInst CORE/inst_RA2SH0
selectInst CORE/inst_RA2SH1
selectInst CORE/inst_RA2SH2
selectInst CORE/inst_RA2SH3
deselectInst CORE/inst_RA1SH0
zoomBox 526.71300 468.44200 2568.26000 1649.57200
zoomBox 732.06900 551.09200 2467.38400 1555.05300
zoomBox 905.54000 620.62500 2380.55800 1473.99200
zoomBox 5.41500 252.34900 2831.08800 1887.13300
deselectAll