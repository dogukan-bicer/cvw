#Kip Macsai-Goren and Kevin Kim
#Purpose is to manually make the B extension tests
import os

f = open("genBScript.sh", "w")
WALLY = os.getenv("WALLY")
os.chdir(f"{WALLY}/tests/riscof/riscof_work/rv64i_m/B/src")

lines = ""

#BUILDS B TESTS
for testname in os.listdir():
    lines = lines + f"""cd {WALLY}/tests/riscof/riscof_work/rv64i_m/B/src/{testname}/ref;riscv64-unknown-elf-gcc -march=rv64izba_zbb_zbc_zbs          -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles         -T {WALLY}/tests/riscof/sail_cSim/env/link.ld         -I {WALLY}/tests/riscof/sail_cSim/env/         -I {WALLY}/addins/riscv-arch-test/riscv-test-suite/env -mabi=lp64  {WALLY}/addins/riscv-arch-test/riscv-test-suite/rv64i_m/B/src/{testname} -o ref.elf -DTEST_CASE_1=True -DXLEN=64;riscv64-unknown-elf-objdump -D ref.elf > ref.elf.objdump;riscv_sim_RV64 -z268435455 -i --test-signature={WALLY}/tests/riscof/riscof_work/rv64i_m/B/src/{testname}/ref/Reference-sail_c_simulator.signature ref.elf > add.uw-01.log 2>&1;
rsync -a {WALLY}/tests/riscof/riscof_work/rv64i_m/ {WALLY}/tests/riscof/work/riscv-arch-test/rv64i_m/ || echo "error suppressed";
riscv64-unknown-elf-elf2hex --bit-width 64 --input {WALLY}/tests/riscof/riscof_work/rv64i_m/B/src/{testname}/ref/ref.elf --output {WALLY}/tests/riscof/work/riscv-arch-test/rv64i_m/B/src/{testname}/ref/ref.elf.memfile;
extractFunctionRadix.sh {WALLY}/tests/riscof/work/riscv-arch-test/rv64i_m/B/src/{testname}/ref/ref.elf.objdump;
"""

os.chdir(f"{WALLY}/tests/riscof/riscof_work/rv64i_m/I/src")

#BUILDS I TESTS
for testname in os.listdir():
    lines = lines + f"""cd {WALLY}/tests/riscof/riscof_work/rv64i_m/I/src/{testname}/ref;riscv64-unknown-elf-gcc -march=rv64izba_zbb_zbc_zbs          -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles         -T {WALLY}/tests/riscof/sail_cSim/env/link.ld         -I {WALLY}/tests/riscof/sail_cSim/env/         -I {WALLY}/addins/riscv-arch-test/riscv-test-suite/env -mabi=lp64  {WALLY}/addins/riscv-arch-test/riscv-test-suite/rv64i_m/I/src/{testname} -o ref.elf -DTEST_CASE_1=True -DXLEN=64;riscv64-unknown-elf-objdump -D ref.elf > ref.elf.objdump;riscv_sim_RV64 -z268435455 -i --test-signature={WALLY}/tests/riscof/riscof_work/rv64i_m/I/src/{testname}/ref/Reference-sail_c_simulator.signature ref.elf > add.uw-01.log 2>&1;
rsync -a {WALLY}/tests/riscof/riscof_work/rv64i_m/ {WALLY}/tests/riscof/work/riscv-arch-test/rv64i_m/ || echo "error suppressed";
riscv64-unknown-elf-elf2hex --bit-width 64 --input {WALLY}/tests/riscof/riscof_work/rv64i_m/I/src/{testname}/ref/ref.elf --output {WALLY}/tests/riscof/work/riscv-arch-test/rv64i_m/I/src/{testname}/ref/ref.elf.memfile;
extractFunctionRadix.sh {WALLY}/tests/riscof/work/riscv-arch-test/rv64i_m/I/src/{testname}/ref/ref.elf.objdump;
"""




f.write(lines)
f.close()

