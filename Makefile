IP ?= fifo_sync

.PHONY: sby qverify clean

sby:
	sby -f sby/$(IP).sby -d build/sby

qverify:
	mkdir -p build/qverify
	qverify -c -od build/qverify -do qverify/$(IP).tcl

clean:
	rm -rf build