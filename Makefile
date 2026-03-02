IP ?= fifo_sync

.PHONY: sby qverify clean

sby:
	sby -f sby/$(IP).sby -d build/sby

qverify:
	mkdir -p build/qverify
	qverify -c -od build/qverify -do qverify/$(IP).tcl

veri:
	mkdir -p build/veri
	verilator --binary -j 0 --trace --timing --Mdir ./build/veri \
		--top-module tb_fifo_sync \
		rtl/fifo_sync.sv \
		tb/tb_fifo_sync.sv \
		tb/axis_vip/tb/axis_sink.sv \
		tb/axis_vip/tb/axis_source.sv \
		-Irtl/ -Itb/axis_vip/tb/
	./build/veri/Vtb_fifo_sync

clean:
	rm -rf build