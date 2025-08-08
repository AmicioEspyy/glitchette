use std::env;

fn main() {
    let out_dir = env::var("OUT_DIR").unwrap();
    
    println!("cargo:rustc-link-arg=-T");
    println!("cargo:rustc-link-arg=linker.ld");
    
    println!("cargo:rustc-link-arg=-nostdlib");
    
    println!("cargo:rustc-link-arg=--gc-sections");
    
    println!("cargo:rerun-if-changed=linker.ld");
    println!("cargo:rerun-if-changed=kernel/src/asm/");
}
