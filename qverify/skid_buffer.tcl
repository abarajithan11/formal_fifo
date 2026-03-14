set IP skid_buffer

vlib build/qverify/work
vlog -sv -work build/qverify/work rtl/${IP}.sv formal/fifo_fvip.sv formal/tb_${IP}.sv

formal compile -d tb_${IP} -work build/qverify/work -sva
formal verify  -auto_constraint_off