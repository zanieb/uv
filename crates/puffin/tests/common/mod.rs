#![allow(dead_code)]

use std::path::PathBuf;

use assert_cmd::Command;
use assert_fs::assert::PathAssert;
use assert_fs::fixture::PathChild;
use assert_fs::TempDir;
use insta_cmd::get_cargo_bin;

use puffin_interpreter::Interpreter;

pub(crate) const BIN_NAME: &str = "puffin";

pub(crate) const INSTA_FILTERS: &[(&str, &str)] = &[
    (r"--cache-dir .*", "--cache-dir [CACHE_DIR]"),
    (r"(\d+\.)?\d+(ms|s)", "[TIME]"),
    (r"v\d+\.\d+\.\d+", "v[VERSION]"),
];

/// Create a virtual environment named `.venv` in a temporary directory.
pub(crate) fn create_venv_py312(temp_dir: &TempDir, cache_dir: &TempDir) -> PathBuf {
    create_venv(temp_dir, cache_dir, "python3.12")
}

/// Create a virtual environment named `.venv` in a temporary directory with the given
/// Python version. Expected format for `python` is "python<version>".
pub(crate) fn create_venv(temp_dir: &TempDir, cache_dir: &TempDir, python: &str) -> PathBuf {
    #[cfg(windows)]
    let python = {
        use std::str::FromStr;

        // TODO(konstin): Change caller to pass in the minor version
        let python_version =
            puffin_interpreter::PythonVersion::from_str(&python.replace("python", ""))
                .expect("Test is using invalid python version");
        Interpreter::find_python(&python_version)
            .expect("`py --list-paths` failed")
            .expect("Python version is not installed")
    };

    let venv = temp_dir.child(".venv");
    Command::new(get_cargo_bin(BIN_NAME))
        .arg("venv")
        .arg(venv.as_os_str())
        .arg("--cache-dir")
        .arg(cache_dir.path())
        .arg("--python")
        .arg(python)
        .current_dir(temp_dir)
        .assert()
        .success();
    venv.assert(predicates::path::is_dir());
    venv.to_path_buf()
}
