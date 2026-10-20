import os
import pty
import subprocess
import tempfile
import unittest
from pathlib import Path


PROJECT_DIR = Path(__file__).resolve().parents[1]
MATRIX_EFFECT = PROJECT_DIR / "bin" / "matrix-effect"


class MatrixEffectTests(unittest.TestCase):
    def setUp(self):
        self.state_home = tempfile.TemporaryDirectory(prefix="matrix state ")
        self.master_fd, self.slave_fd = pty.openpty()
        self.tty_device = os.ttyname(self.slave_fd)

    def tearDown(self):
        os.close(self.master_fd)
        os.close(self.slave_fd)
        self.state_home.cleanup()

    def run_effect(self, mode):
        environment = os.environ.copy()
        environment["XDG_STATE_HOME"] = self.state_home.name
        result = subprocess.run(
            [MATRIX_EFFECT, mode, self.tty_device],
            check=True,
            env=environment,
            capture_output=True,
            text=True,
        )
        output = os.read(self.master_fd, 128).decode()
        return result.stdout, output

    def test_each_effect_toggle_preserves_other_flags(self):
        for mode, expected_off_color in [
            ("background", "0e"),
            ("idle", "0d"),
            ("shake", "0b"),
            ("sparks", "07"),
        ]:
            with self.subTest(mode=mode):
                _, output = self.run_effect(mode)
                self.assertEqual(output, f"\x1b]12;#00ff{expected_off_color}\x07")

                _, output = self.run_effect(mode)
                self.assertEqual(output, "\x1b]12;#00ff0f\x07")


if __name__ == "__main__":
    unittest.main()
