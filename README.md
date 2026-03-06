# Development of a Formally Verified FIFO

Make sure you have `qverify` (Mentor Graphics Questa Formal Tool) and/or `sby` (SymbiYosys - Open source tool) in your `$PATH`

```bash
make qverify IP=fifo_sync
make sby IP=fifo_sync

make qverify IP=skid_buffer
```