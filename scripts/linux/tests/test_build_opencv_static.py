import subprocess
import tempfile
from pathlib import Path
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "build_opencv_static.sh"
STAMP = ".stackwallet-opencv-4.10.0-71d3237a093b60a27601c20e9ee6c3e52154e8b1"


class BuildOpenCvStaticTest(unittest.TestCase):
    def test_check_only_requires_matching_config_and_stamp(self):
        with tempfile.TemporaryDirectory(prefix="opencv-static-check-") as temp:
            prefix = Path(temp)

            missing = subprocess.run(
                [str(SCRIPT), "--check-only", str(prefix)],
                capture_output=True,
                text=True,
            )
            self.assertNotEqual(missing.returncode, 0)

            config = prefix / "lib/cmake/opencv4/OpenCVConfig.cmake"
            config.parent.mkdir(parents=True)
            config.touch()
            (prefix / ".stackwallet-opencv-old").touch()
            stale = subprocess.run(
                [str(SCRIPT), "--check-only", str(prefix)],
                capture_output=True,
                text=True,
            )
            self.assertNotEqual(stale.returncode, 0)

            (prefix / STAMP).touch()
            current = subprocess.run(
                [str(SCRIPT), "--check-only", str(prefix)],
                capture_output=True,
                text=True,
            )
            self.assertEqual(
                current.returncode,
                0,
                current.stdout + current.stderr,
            )


if __name__ == "__main__":
    unittest.main()
