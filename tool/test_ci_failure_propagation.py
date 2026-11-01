import os
import shutil
import subprocess
import sys
import tempfile

sys.stdout.reconfigure(encoding='utf-8')

def get_bash():
    git_bash = r"C:\Program Files\Git\bin\bash.exe"
    if os.path.exists(git_bash):
        return git_bash
    git_usr_bash = r"C:\Program Files\Git\usr\bin\bash.exe"
    if os.path.exists(git_usr_bash):
        return git_usr_bash
    b = shutil.which("bash")
    if b and "System32" not in b:
        return b
    return b

def test_pipeline_failure_capture():
    """Verify that pipefail captures failures in pipelines."""
    bash_path = get_bash()

    if bash_path:
        # Deliberately failing pipeline
        cmd = [
            bash_path,
            "-c",
            'set -o pipefail; status=0; (exit 42) 2>&1 | cat || status=$?; echo "CAPTURED_STATUS:$status"'
        ]
        res = subprocess.run(cmd, capture_output=True, text=True)
        if "CAPTURED_STATUS:42" in res.stdout:
            print("  PASS: set -o pipefail accurately captured exit status 42 across pipeline.")
        else:
            print(f"  FAIL: Expected 42, got:\n{res.stdout}")
            sys.exit(1)

def test_aggregate_gate_verdict():
    """Verify aggregate verdict logic fails closed on any gate error or missing gate."""
    bash_path = get_bash()
    if not bash_path or not os.path.exists(bash_path):
        print("  Skipping bash aggregate test (no bash binary).")
        return

    with tempfile.TemporaryDirectory() as tmp_dir:
        gates_dir = os.path.join(tmp_dir, "gates")
        os.makedirs(gates_dir, exist_ok=True)

        agg_script = '''
        failed=0
        required_gates=("gate1" "gate2" "gate3")
        for gate in "${required_gates[@]}"; do
          status_file="''' + gates_dir.replace('\\', '/') + '''/${gate}.status"
          if [ ! -f "$status_file" ]; then
            failed=1
          else
            code=$(cat "$status_file" | tr -d '[:space:]')
            if [ "$code" -ne 0 ]; then
              failed=1
            fi
          fi
        done
        exit $failed
        '''

        # Case A: Missing gate -> must fail (exit 1)
        with open(os.path.join(gates_dir, "gate1.status"), "w") as f:
            f.write("0\n")
        with open(os.path.join(gates_dir, "gate2.status"), "w") as f:
            f.write("0\n")
        # gate3 is missing!
        res_a = subprocess.run([bash_path, "-c", agg_script])
        assert res_a.returncode == 1, f"Expected aggregate failure on missing gate, got {res_a.returncode}"
        print("  PASS: Aggregate check correctly failed on missing gate.")

        # Case B: Failing gate -> must fail (exit 1)
        with open(os.path.join(gates_dir, "gate3.status"), "w") as f:
            f.write("1\n") # gate3 failed!
        res_b = subprocess.run([bash_path, "-c", agg_script])
        assert res_b.returncode == 1, f"Expected aggregate failure on failed gate, got {res_b.returncode}"
        print("  PASS: Aggregate check correctly failed on non-zero gate exit code.")

        # Case C: All gates pass -> must pass (exit 0)
        with open(os.path.join(gates_dir, "gate3.status"), "w") as f:
            f.write("0\n") # all 3 are 0
        res_c = subprocess.run([bash_path, "-c", agg_script])
        assert res_c.returncode == 0, f"Expected aggregate pass when all 0, got {res_c.returncode}"
        print("  PASS: Aggregate check passed cleanly when all gates succeeded.")

def main():
    print("==================================================")
    print("CI FAILURE PROPAGATION PROBE TEST SUITE")
    print("==================================================")
    print("\n[1/2] Testing pipeline exit code capture with pipefail...")
    test_pipeline_failure_capture()
    print("\n[2/2] Testing aggregate gate verdict logic...")
    test_aggregate_gate_verdict()
    print("\n--------------------------------------------------")
    print("ALL CI PROPAGATION TESTS PASSED!")
    print("--------------------------------------------------")

if __name__ == "__main__":
    main()
