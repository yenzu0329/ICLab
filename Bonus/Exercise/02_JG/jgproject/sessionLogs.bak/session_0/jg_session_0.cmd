# ----------------------------------------
# Jasper Version Info
# tool      : Jasper 2023.03
# platform  : Linux 3.10.0-1160.88.1.el7.x86_64
# version   : 2023.03 FCS 64 bits
# build date: 2023.03.29 16:16:18 UTC
# ----------------------------------------
# started   : 2023-05-13 16:37:54 CST
# hostname  : ee22.EEHPC
# pid       : 46478
# arguments : '-label' 'session_0' '-console' '//127.0.0.1:36784' '-style' 'windows' '-data' 'AAAAgHicY2RgYLCp////PwMYMFcBCQEGHwZfhiAGVyDpzxAGpOGA8QGUYcPIgAwYAxtQaAYGVphCmAog5mMoYihlyGPQYyhhSGbIAQkDAMP4DIY=' '-proj' '/RAID2/COURSE/iclab/iclab100/Bonus_formal_verification/Exercise/02_JG/jgproject/sessionLogs/session_0' '-init' '-hidden' '/RAID2/COURSE/iclab/iclab100/Bonus_formal_verification/Exercise/02_JG/jgproject/.tmp/.initCmds.tcl' 'run.tcl'
clear -all

jasper_scoreboard_3 -init

set ABVIP_INST_DIR /RAID2/COURSE/iclab/iclabta01/cadence_vip/tools/abvip
# set ABVIP_INST_DIR /grid/avs/install/vipcat/11.3/latest/tools/abvip
# set ABVIP_INST_DIR ~/cadence_vip/vips/abvip
abvip -set_location $ABVIP_INST_DIR
set_visualize_auto_load_debugging_tables on

analyze -sv09  -f jg.f
analyze -sv09  top.sv
elaborate -top top -no_precondition -extract_covergroups

clock SystemClock
reset ~inf.rst_n



# ------------------------ LAN Version ---------------------------
assert -disable *prot* *len* *user* *lock* *qos* *region* *cache* *last* *size* *burst* *awid* *arid*
assume {slave.awsize==4}               -name slave_awsize
assume {slave.awid==0}                 -name slave_awid
assume {slave.wid==0}                  -name slave_wid
assume {slave.wlast==1}                -name slave_wlast
assume {slave.arsize==4}               -name slave_arsize
assume {slave.arid==1}                 -name slave_arid
assume {slave.rlast==1}                -name slave_rlast
assume {slave.awburst==0}              -name slave_awburst_fixed
assume {slave.arburst==0}              -name slave_arburst_fixed
assume {&slave.wstrb==1}               -name slave_wstrb

# Good For TA
#get_needed_assumption -property {<embedded>::top.sc_w.genblk6.core.genblk7.COVER[1].data_in}
prove -bg -all
visualize -violation -property <embedded>::top.assert_wdata -new_window
