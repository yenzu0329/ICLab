#######################################################
#                                                     
#  Innovus Command Logging File                     
#  Created on Sat May 20 22:28:55 2023                
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
addHaloToBlock {15 15 15 15} -allMacro
saveDesign CHIP_floorplane.inn
setDrawView ameba
setDrawView fplan
selectInst CORE/inst_RA1SH0
selectInst CORE/inst_RA2SH7
selectInst CORE/inst_RA2SH6
selectInst CORE/inst_RA2SH5
selectInst CORE/inst_RA2SH4
selectInst CORE/inst_RA2SH0
selectInst CORE/inst_RA2SH1
selectInst CORE/inst_RA2SH2
selectInst CORE/inst_RA2SH3
saveDesign CHIP_floorplane.inn
clearGlobalNets
globalNetConnect VDD -type pgpin -pin VDD -instanceBasename *
globalNetConnect VDD -type net -net VDD
globalNetConnect VDD -type tiehi -pin VDD -instanceBasename *
globalNetConnect GND -type pgpin -pin GND -instanceBasename *
globalNetConnect GND -type net -net GND
globalNetConnect GND -type tielo -pin GND -instanceBasename *
globalNetConnect GND -type pgpin -pin VSS -instanceBasename *
set sprCreateIeRingOffset 1.0
set sprCreateIeRingThreshold 1.0
set sprCreateIeRingJogDistance 1.0
set sprCreateIeRingLayers {}
set sprCreateIeRingOffset 1.0
set sprCreateIeRingThreshold 1.0
set sprCreateIeRingJogDistance 1.0
set sprCreateIeRingLayers {}
set sprCreateIeStripeWidth 10.0
set sprCreateIeStripeThreshold 1.0
set sprCreateIeStripeWidth 10.0
set sprCreateIeStripeThreshold 1.0
set sprCreateIeRingOffset 1.0
set sprCreateIeRingThreshold 1.0
set sprCreateIeRingJogDistance 1.0
set sprCreateIeRingLayers {}
set sprCreateIeStripeWidth 10.0
set sprCreateIeStripeThreshold 1.0
setAddRingMode -ring_target default -extend_over_row 0 -ignore_rows 0 -avoid_short 0 -skip_crossing_trunks none -stacked_via_top_layer met6 -stacked_via_bottom_layer met1 -via_using_exact_crossover_size 1 -orthogonal_only true -skip_via_on_pin {  standardcell } -skip_via_on_wire_shape {  noshape }
addRing -nets {GND VDD} -type core_rings -follow core -layer {top met3 bottom met3 left met2 right met2} -width {top 9 bottom 9 left 9 right 9} -spacing {top 0.28 bottom 0.28 left 0.28 right 0.28} -offset {top 1.8 bottom 1.8 left 1.8 right 1.8} -center 1 -threshold 0 -jog_distance 0 -snap_wire_center_to_grid None -use_wire_group 1 -use_wire_group_bits 10 -use_interleaving_wire_group 1
setAddRingMode -ring_target default -extend_over_row 0 -ignore_rows 0 -avoid_short 0 -skip_crossing_trunks none -stacked_via_top_layer met6 -stacked_via_bottom_layer met1 -via_using_exact_crossover_size 1 -orthogonal_only true -skip_via_on_pin {  standardcell } -skip_via_on_wire_shape {  noshape }
addRing -nets {GND VDD} -type block_rings -around each_block -layer {top met3 bottom met3 left met2 right met2} -width {top 2 bottom 2 left 2 right 2} -spacing {top 0.28 bottom 0.28 left 0.28 right 0.28} -offset {top 1.8 bottom 1.8 left 1.8 right 1.8} -center 0 -threshold 0 -jog_distance 0 -snap_wire_center_to_grid None
setSrouteMode -viaConnectToShape { ring }
sroute -connect { padPin } -layerChangeRange { met1(1) met6(6) } -blockPinTarget { nearestTarget } -padPinPortConnect { allPort oneGeom } -padPinTarget { nearestTarget } -allowJogging 1 -crossoverViaLayerRange { met1(1) met6(6) } -nets { GND VDD } -allowLayerChange 1 -targetViaLayerRange { met1(1) met6(6) }
saveDesign CHIP_powerplan.inn
setDrawView fplan
encMessage warning 1
encMessage debug 0
encMessage info 1
pan -1613.44600 -308.01000
set sprCreateIeRingOffset 1.0
set sprCreateIeRingThreshold 1.0
set sprCreateIeRingJogDistance 1.0
set sprCreateIeRingLayers {}
set sprCreateIeRingOffset 1.0
set sprCreateIeRingThreshold 1.0
set sprCreateIeRingJogDistance 1.0
set sprCreateIeRingLayers {}
set sprCreateIeStripeWidth 10.0
set sprCreateIeStripeThreshold 1.0
set sprCreateIeStripeWidth 10.0
set sprCreateIeStripeThreshold 1.0
set sprCreateIeRingOffset 1.0
set sprCreateIeRingThreshold 1.0
set sprCreateIeRingJogDistance 1.0
set sprCreateIeRingLayers {}
set sprCreateIeStripeWidth 10.0
set sprCreateIeStripeThreshold 1.0
setAddStripeMode -ignore_block_check false -break_at none -route_over_rows_only false -rows_without_stripes_only false -extend_to_closest_target none -stop_at_last_wire_for_area false -partial_set_thru_domain false -ignore_nondefault_domains false -trim_antenna_back_to_shape none -spacing_type edge_to_edge -spacing_from_block 0 -stripe_min_length stripe_width -stacked_via_top_layer met6 -stacked_via_bottom_layer met1 -via_using_exact_crossover_size false -split_vias false -orthogonal_only true -allow_jog { padcore_ring  block_ring } -skip_via_on_pin {  standardcell } -skip_via_on_wire_shape {  noshape   }
addStripe -nets {GND VDD} -layer met2 -direction vertical -width 4 -spacing 0.28 -set_to_set_distance 200 -start_from left -start_offset 50 -switch_layer_over_obs false -max_same_layer_jog_length 2 -padcore_ring_top_layer_limit met6 -padcore_ring_bottom_layer_limit met1 -block_ring_top_layer_limit met6 -block_ring_bottom_layer_limit met1 -use_wire_group 0 -snap_wire_center_to_grid None
setAddStripeMode -ignore_block_check false -break_at none -route_over_rows_only false -rows_without_stripes_only false -extend_to_closest_target none -stop_at_last_wire_for_area false -partial_set_thru_domain false -ignore_nondefault_domains false -trim_antenna_back_to_shape none -spacing_type edge_to_edge -spacing_from_block 0 -stripe_min_length stripe_width -stacked_via_top_layer met6 -stacked_via_bottom_layer met1 -via_using_exact_crossover_size false -split_vias false -orthogonal_only true -allow_jog { padcore_ring  block_ring } -skip_via_on_pin {  standardcell } -skip_via_on_wire_shape {  noshape   }
addStripe -nets {GND VDD} -layer met3 -direction horizontal -width 4 -spacing 0.28 -set_to_set_distance 200 -start_from bottom -start_offset 50 -switch_layer_over_obs false -max_same_layer_jog_length 2 -padcore_ring_top_layer_limit met6 -padcore_ring_bottom_layer_limit met1 -block_ring_top_layer_limit met6 -block_ring_bottom_layer_limit met1 -use_wire_group 0 -snap_wire_center_to_grid None
setSrouteMode -viaConnectToShape { ring stripe }
sroute -connect { corePin } -layerChangeRange { met1(1) met6(6) } -blockPinTarget { nearestTarget } -corePinTarget { firstAfterRowEnd } -allowJogging 1 -crossoverViaLayerRange { met1(1) met6(6) } -nets { GND VDD } -allowLayerChange 1 -targetViaLayerRange { met1(1) met6(6) }
getMultiCpuUsage -localCpu
get_verify_drc_mode -disable_rules -quiet
get_verify_drc_mode -quiet -area
get_verify_drc_mode -quiet -layer_range
get_verify_drc_mode -check_ndr_spacing -quiet
get_verify_drc_mode -check_only -quiet
get_verify_drc_mode -check_same_via_cell -quiet
get_verify_drc_mode -exclude_pg_net -quiet
get_verify_drc_mode -ignore_trial_route -quiet
get_verify_drc_mode -max_wrong_way_halo -quiet
get_verify_drc_mode -use_min_spacing_on_block_obs -quiet
get_verify_drc_mode -limit -quiet
set_verify_drc_mode -disable_rules {} -check_ndr_spacing auto -check_only default -check_same_via_cell false -exclude_pg_net false -ignore_trial_route false -ignore_cell_blockage false -use_min_spacing_on_block_obs auto -report CHIP.drc.rpt -limit 1000
verify_drc
set_verify_drc_mode -area {0 0 0 0}
setLayerPreference violation -isVisible 1
violationBrowser -all -no_display_false -displayByLayer
violationBrowserClose
verifyConnectivity -net {GND VDD} -type special -error 1000 -warning 50
zoomBox -134.47000 592.82200 2232.39500 1782.65900
zoomBox 467.59900 981.95500 1703.11800 1603.05800
zoomBox 645.52100 1094.10900 1538.18500 1542.85700
zoomBox 715.00500 1137.91000 1473.77100 1519.34600
selectWire 1101.7600 1378.7000 1105.7600 1753.9000 2 VDD
editTrim
deselectAll
selectWire 1301.7600 1378.7000 1305.7600 1753.9000 2 VDD
editTrim
deselectAll
selectWire 1301.7600 1083.5100 1305.7600 1195.3700 2 VDD
editTrim
deselectAll
selectWire 1101.7600 1094.8500 1105.7600 1210.2400 2 VDD
editTrim
deselectAll
selectWire 1097.4800 237.7900 1101.4800 1210.2400 2 GND
editTrim
zoomBox 664.92300 1124.62400 1557.58900 1573.37300
zoomBox 591.60400 1087.58600 1641.80000 1615.52600
zoomBox 504.45600 1044.01200 1739.98100 1665.11800
zoomBox 401.92900 992.74800 1855.48800 1723.46100
zoomBox 606.85100 1036.66900 1842.37800 1657.77600
zoomBox 934.03500 1100.51400 1826.70400 1549.26400
zoomBox 1062.38000 1124.10600 1821.14800 1505.54300
zoomBox 1166.47700 1147.23800 1811.43000 1471.46000
deselectAll
selectWire 1501.7600 1088.7700 1505.7600 1195.3700 2 VDD
editTrim
deselectAll
selectWire 1501.7600 1378.7000 1505.7600 1753.9000 2 VDD
editTrim
deselectAll
selectWire 1701.7600 1378.7000 1705.7600 1753.9000 2 VDD
editTrim
deselectAll
selectWire 1701.7600 1083.5100 1705.7600 1195.3700 2 VDD
editTrim
zoomBox 694.33700 1028.46900 1929.86900 1649.57800
zoomBox 783.60300 1033.37200 1833.80500 1561.31500
zoomBox 1025.38900 1046.65200 1573.60400 1322.24300
zoomBox 773.97300 1011.35600 1824.18300 1539.30300
zoomBox 675.79100 989.17900 1911.33200 1610.29300
zoomBox 419.82400 927.82700 2129.91700 1787.50100
zoomBox 467.79500 951.27300 1921.37400 1681.99600
zoomBox 563.09800 1043.17200 1208.06000 1367.39800
zoomBox 592.43000 1071.60600 988.51700 1270.72100
deselectAll
selectWire 701.7600 1083.5100 705.7600 1190.1100 2 VDD
editTrim
deselectAll
selectWire 697.4800 1083.5100 701.4800 1194.1100 2 GND
editTrim
zoomBox 567.12700 1067.31900 1033.11200 1301.57200
zoomBox 457.70700 1037.34400 1216.48500 1418.78600
zoomBox 335.91000 990.72700 1386.12400 1518.67600
zoomBox 255.00000 958.96500 1490.54700 1580.08200
zoomBox 587.56100 1027.77000 1346.34300 1409.21400
zoomBox 791.79600 1070.02600 1257.78200 1304.28000
zoomBox 594.60300 1003.82500 1353.38500 1385.26900
zoomBox 504.50200 973.55000 1397.18700 1422.30800
zoomBox 273.79400 896.02900 1509.34500 1517.14800
zoomBox -487.48700 640.22800 1879.44000 1830.09600
zoomBox -141.89500 663.53100 1568.21000 1523.21100
zoomBox 285.37300 692.73800 1178.05700 1141.49600
zoomBox 403.19800 707.78300 1048.16400 1032.01100
deselectAll
selectWire 701.7600 795.4500 705.7600 900.1800 2 VDD
editTrim
zoomBox 270.62300 671.73400 1163.31000 1120.49300
zoomBox 87.12900 621.84000 1322.68200 1242.96000
zoomBox -29.56000 590.11100 1424.03100 1320.84000
zoomBox 361.68300 658.02700 1411.90300 1185.97900
zoomBox 754.75200 726.25900 1399.71900 1050.48800
deselectAll
selectWire 1301.7600 795.4500 1305.7600 915.0500 2 VDD
editTrim
deselectAll
selectWire 1297.4800 795.4500 1301.4800 915.0500 2 GND
editTrim
zoomBox 557.85000 670.18200 1450.53900 1118.94200
zoomBox 287.76800 593.31300 1523.32400 1214.43400
zoomBox 116.79800 544.67000 1570.39300 1275.40100
zoomBox -596.79500 343.89000 1770.14400 1533.76400
zoomBox 507.77900 585.15300 1743.33600 1206.27500
zoomBox 1087.35600 704.83400 1732.32600 1029.06400
zoomBox 1262.99800 741.10300 1728.99000 975.36000
deselectAll
selectWire 1701.7600 795.4500 1705.7600 900.1800 2 VDD
editTrim
deselectAll
selectWire 1697.4800 795.4500 1701.4800 900.1800 2 GND
editTrim
zoomBox 1112.43000 688.36600 1757.40300 1012.59800
zoomBox 771.50600 568.95700 1821.73800 1096.91500
zoomBox 615.59300 514.34800 1851.16000 1135.47500
zoomBox 216.36700 374.51900 1926.49600 1234.21100
zoomBox -36.96700 286.32400 1974.94900 1297.72600
zoomBox 805.01100 404.87000 1855.24600 932.82900
zoomBox 1159.82500 454.58200 1804.80200 778.81600
deselectAll
selectWire 447.4800 593.2000 1809.0600 594.0000 1 GND
deselectAll
selectWire 1701.7600 228.5100 1705.7600 612.1200 2 VDD
editTrim
deselectAll
selectWire 1301.7600 228.5100 1305.7600 626.9900 2 VDD
editTrim
deselectAll
selectWire 1297.4800 237.7900 1301.4800 626.9900 2 GND
editTrim
zoomBox 983.61500 344.26200 2033.85400 872.22300
zoomBox 884.98400 291.88200 2120.56000 913.01300
zoomBox 769.47200 230.78200 2223.09100 961.52500
zoomBox 633.57600 158.90000 2343.71600 1018.59800
zoomBox 473.69700 74.33300 2485.62800 1085.74300
zoomBox 566.21900 318.36900 1616.46300 846.33300
zoomBox 619.26600 469.08500 1085.26600 703.34600
deselectAll
selectWire 701.7600 228.5100 705.7600 612.1200 2 VDD
editTrim
zoomBox 581.05000 415.92600 1226.03300 740.16300
zoomBox 493.56300 296.27200 1543.81100 824.23800
zoomBox 406.48100 177.17300 1860.11400 907.92300
zoomBox 351.10300 101.43400 2061.26000 961.14000