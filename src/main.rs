use std::path::PathBuf;

pub use app::App;

pub mod app;
pub mod game;
pub mod lua;
pub mod tracing_integration;

fn main() -> color_eyre::Result<()> {
    color_eyre::install()?;
    let log_path = tracing_integration::initialize_logging()?;
    let result = App::run();
    ratatui::restore();
    rename_log(log_path);
    result
}

fn rename_log(log_path: PathBuf) {
    let file_stem = log_path.file_stem().unwrap().to_str().unwrap();
    let t = chrono::Local::now();
    let t = t.format("%Y-%m-%d_%H-%M-%S");
    let new_file_name = format!("{}_{}.log", file_stem, t);
    let new_log_path = log_path.with_file_name(new_file_name);
    if !new_log_path.exists() {
        std::fs::copy(&log_path, &new_log_path).unwrap();
        println!("Log written to: {}", new_log_path.to_str().unwrap());
    }
}
