set IP fifo_sync

vlib build/qverify/work
vlog -sv -work build/qverify/work rtl/${IP}.sv formal/tb_${IP}.sv

formal compile -d tb_${IP} -work build/qverify/work -sva
formal verify  -auto_constraint_off