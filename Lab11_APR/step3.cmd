#######################################################
#                                                     
#  Innovus Command Logging File                     
#  Created on Sat May 20 20:30:12 2023                
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
zoomBox -115.75800 -90.12900 2251.24200 1099.77600
verifyConnectivity -net {GND VDD} -type special -error 1000 -warning 50
zoomBox -439.73200 -338.43900 2836.39400 1308.48900
zoomBox -663.27000 -470.89300 3190.99600 1466.66900
zoomBox -926.25600 -626.72200 3608.17500 1652.76300
zoomBox -1235.65100 -810.53100 4098.97300 1871.21600
pan -356.06900 899.87900
setPlaceMode -prerouteAsObs {2 3}
setPlaceMode -fp false
place_design -noPrePlaceOpt
setDrawView place
zoomBox -826.17100 249.96200 3028.09500 2187.52400
zoomBox -526.49800 475.23800 2749.62800 2122.16600
zoomBox -272.95800 666.72300 2511.74900 2066.61200
zoomBox 275.62100 1093.82800 1985.78200 1953.53600
zoomBox 517.32900 1282.45800 1752.92100 1903.59700
zoomBox 691.96100 1418.74200 1584.67800 1867.51600
zoomBox 909.03600 1589.37500 1375.04200 1823.63900
zoomBox 1000.51300 1661.28100 1286.70000 1805.14900
selectWire 1145.5400 1192.8600 1145.9800 1786.3400 6 C_in_valid2
zoomBox 818.19400 1517.15300 1463.19100 1841.39700
zoomBox 407.29500 1192.32600 1860.95800 1923.09100
zoomBox -56.81400 825.43300 2310.23600 2015.36300
zoomBox -269.06300 657.64400 2515.70200 2057.56200
zoomBox -518.76700 460.24500 2757.42700 2107.20700
zoomBox -812.53600 228.01000 3041.81000 2165.61300
zoomBox -1159.37500 -44.79800 3375.15100 2234.73500
zoomBox -8.51700 820.62800 2358.53500 2010.55900
zoomBox 475.91300 1187.52100 1929.57800 1918.28700
zoomBox 591.29700 1275.10800 1826.91200 1896.25900
zoomBox 833.10100 1468.20500 1591.92400 1849.67000
deselectAll
zoomBox 940.09700 1553.67400 1488.34700 1829.28300
zoomBox 1047.59000 1639.54300 1384.28600 1808.80200
selectWire 1217.8100 1054.5400 1218.2500 1787.1200 6 C_in_valid
zoomBox 891.48800 1513.84500 1536.49300 1838.09300
zoomBox 482.04400 1184.15000 1935.72500 1914.92400
zoomBox -191.91900 640.65800 2592.87800 2040.59200
zoomBox -1077.85700 -73.77400 3456.72100 2205.78500
zoomBox 248.71900 451.23200 2615.79700 1641.17600
zoomBox 444.29100 530.87000 2456.30700 1542.32200
zoomBox 751.49300 655.76500 2205.17400 1386.53900
zoomBox 610.34700 598.38100 2320.55900 1458.11500
zoomBox 248.93200 451.44500 2616.00900 1641.38900
zoomBox 19.09700 358.00300 2803.89500 1757.93800
zoomBox -251.29800 248.36800 3024.93700 1895.35100
zoomBox -569.40700 119.38600 3284.98700 2057.01300
zoomBox 721.75800 611.96000 2733.77600 1623.41300
zoomBox 1252.91100 799.84100 2488.54400 1421.00100
deselectAll
zoomBox 1638.25600 901.77000 2283.26500 1226.02000
zoomBox 1754.92700 932.76700 2220.94700 1167.03800
selectWire 2058.3200 843.4200 2058.7600 1049.3800 6 C_w_mat_idx
zoomBox 1872.14300 964.12500 2158.33800 1107.99700
zoomBox 1638.25300 901.55300 2283.26600 1225.80500
zoomBox 1111.12200 759.55800 2564.82200 1490.34200
zoomBox 943.90200 714.51400 2654.13900 1574.26000
zoomBox 747.17400 661.33900 2759.21800 1672.80500
zoomBox 515.72900 598.78000 2882.84000 1788.74100
zoomBox 243.44100 525.18200 3028.27800 1925.13600
zoomBox -76.89800 438.59600 3199.38100 2085.60100
zoomBox -453.76700 336.73000 3400.67900 2274.38300
saveDesign CHIP_placement.inn
redirect -quiet {set honorDomain [getAnalysisMode -honorClockDomains]} > /dev/null
timeDesign -preCTS -pathReports -drvReports -slackReports -numPaths 50 -prefix CHIP_preCTS -outDir timingReports
setOptMode -fixCap true -fixTran true -fixFanoutLoad true
optDesign -preCTS
saveDesign CHIP_preCTS.inn
set_ccopt_property update_io_latency false
create_ccopt_clock_tree_spec -file CHIP.CCOPT.spec -keep_all_sdc_clocks
get_ccopt_clock_trees
ccopt_check_and_flatten_ilms_no_restore
set_ccopt_property cts_is_sdc_clock_root -pin clk true
set_ccopt_property case_analysis -pin I_CLK/A 0
set_ccopt_property case_analysis -pin I_CLK/CEN 0
set_ccopt_property case_analysis -pin I_CLK/CSEN 1
set_ccopt_property case_analysis -pin I_CLK/OCEN 0
set_ccopt_property case_analysis -pin I_CLK/ODEN 0
set_ccopt_property case_analysis -pin I_CLK/PD 0
set_ccopt_property case_analysis -pin I_CLK/PU 1
create_ccopt_clock_tree -name clk -source clk -no_skew_group
set_ccopt_property clock_period -pin clk 30
create_ccopt_skew_group -name clk/func_mode -sources clk -auto_sinks
set_ccopt_property include_source_latency -skew_group clk/func_mode true
set_ccopt_property extracted_from_clock_name -skew_group clk/func_mode clk
set_ccopt_property extracted_from_constraint_mode_name -skew_group clk/func_mode func_mode
set_ccopt_property extracted_from_delay_corners -skew_group clk/func_mode {Delay_Corner_max Delay_Corner_min}
check_ccopt_clock_tree_convergence
get_ccopt_property auto_design_state_for_ilms
ccopt_design
setDrawView ameba
setDrawView place
saveDesign CHIP_CTS.inn
redirect -quiet {set honorDomain [getAnalysisMode -honorClockDomains]} > /dev/null
timeDesign -postCTS -pathReports -drvReports -slackReports -numPaths 50 -prefix CHIP_postCTS -outDir timingReports
setOptMode -fixCap true -fixTran true -fixFanoutLoad true
optDesign -postCTS
redirect -quiet {set honorDomain [getAnalysisMode -honorClockDomains]} > /dev/null
timeDesign -postCTS -hold -pathReports -slackReports -numPaths 50 -prefix CHIP_postCTS -outDir timingReports
addIoFiller -cell PFILL -prefix IOFILLER
addIoFiller -cell PFILL_9 -prefix IOFILLER
addIoFiller -cell PFILL_1 -prefix IOFILLER
addIoFiller -cell PFILL_01 -prefix IOFILLER -fillAnyGap
setDrawView ameba
setDrawView place
setNanoRouteMode -quiet -routeInsertAntennaDiode 1
setNanoRouteMode -quiet -routeAntennaCellName ANTENNA
setNanoRouteMode -quiet -timingEngine {}
setNanoRouteMode -quiet -routeWithTimingDriven 1
setNanoRouteMode -quiet -routeWithSiDriven 1
setNanoRouteMode -quiet -routeTdrEffort 10
setNanoRouteMode -quiet -routeTopRoutingLayer 6
setNanoRouteMode -quiet -routeBottomRoutingLayer 1
setNanoRouteMode -quiet -drouteEndIteration 1
setNanoRouteMode -quiet -routeWithTimingDriven true
setNanoRouteMode -quiet -routeWithSiDriven true
routeDesign -globalDetail -viaOpt -wireOpt
setDrawView fplan
setDrawView place
verifyConnectivity -type all -error 1000 -warning 50
zoomBox -941.72600 105.63500 3592.91700 2385.22700
zoomBox -437.77500 393.17500 2838.50400 2040.18000
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
saveDesign CHIP_nanoRoute.inn
setAnalysisMode -cppr none -clockGatingCheck true -timeBorrowing true -useOutputPinCap true -sequentialConstProp false -timingSelfLoopsNoSkew false -enableMultipleDriveNet true -clkSrcPath true -warn true -usefulSkew true -analysisType onChipVariation -log true
setExtractRCMode -engine postRoute -effortLevel signoff -coupled true -capFilterMode relOnly -coupling_c_th 3 -total_c_th 5 -relative_c_th 0.03 -lefTechFileMap LEF/qrc_lefdef.layermap
setExtractRCMode -engine postRoute
setExtractRCMode -effortLevel high
setDelayCalMode -SIAware true
redirect -quiet {set honorDomain [getAnalysisMode -honorClockDomains]} > /dev/null
timeDesign -postRoute -pathReports -drvReports -slackReports -numPaths 50 -prefix CHIP_postRoute -outDir timingReports
redirect -quiet {set honorDomain [getAnalysisMode -honorClockDomains]} > /dev/null
timeDesign -postRoute -hold -pathReports -slackReports -numPaths 50 -prefix CHIP_postRoute -outDir timingReports
saveDesign CHIP_postRoute.inn
redirect -quiet {set honorDomain [getAnalysisMode -honorClockDomains]} > /dev/null
timeDesign -signoff -pathReports -drvReports -slackReports -numPaths 50 -prefix CHIP_signOff -outDir timingReports
redirect -quiet {set honorDomain [getAnalysisMode -honorClockDomains]} > /dev/null
timeDesign -signoff -hold -pathReports -slackReports -numPaths 50 -prefix CHIP_signOff -outDir timingReports
getFillerMode -quiet
addFiller -cell FILL1 FILL16 FILL2 FILL32 FILL4 FILL64 FILL8 -prefix FILLER
saveDesign CHIP.inn
redirect -quiet {set honorDomain [getAnalysisMode -honorClockDomains]} > /dev/null
timeDesign -postRoute -pathReports -drvReports -slackReports -numPaths 50 -prefix CHIP_postRoute -outDir timingReports
redirect -quiet {set honorDomain [getAnalysisMode -honorClockDomains]} > /dev/null
timeDesign -postRoute -hold -pathReports -slackReports -numPaths 50 -prefix CHIP_postRoute -outDir timingReports
all_hold_analysis_views 
all_setup_analysis_views 
saveDesign CHIP.inn
write_sdf CHIP.sdf
saveNetlist CHIP.v
summaryReport -noHtml -outfile summaryReport.rpt
