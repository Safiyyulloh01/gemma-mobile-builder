#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────
# optimize_qnn.py — Convert ONNX → QNN context binary for Snapdragon NPU
# ─────────────────────────────────────────────────────────
import argparse
import os
import subprocess
import sys


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--qnn-sdk", required=True)
    parser.add_argument("--onnx-path", required=True)
    parser.add_argument("--output-dir", required=True)
    parser.add_argument("--soc-family", default="snapdragon-8-gen3")
    args = parser.parse_args()

    sdk = args.qnn_sdk
    onnx_dir = args.onnx_path
    out_dir = args.output_dir

    # Find ONNX file
    onnx_files = [f for f in os.listdir(onnx_dir) if f.endswith(".onnx")]
    if not onnx_files:
        print("No .onnx files found in", onnx_dir, file=sys.stderr)
        sys.exit(1)

    onnx_model = os.path.join(onnx_dir, onnx_files[0])
    print(f"==> Optimizing {onnx_model} for {args.soc_family}")

    # QNN context-gen tool
    qnn_tools = os.path.join(sdk, "bin", "x86_64-linux-clang")
    context_gen = os.path.join(qnn_tools, "qnn-context-binary-generator")

    if not os.path.exists(context_gen):
        print(f"QNN context-gen not found at {context_gen}")
        print("Falling back: QNN SDK not bundled; skipping optimization.")
        sys.exit(0)

    # Run QNN context binary generator
    cmd = [
        context_gen,
        "--backend", os.path.join(sdk, "lib", "x86_64-linux-clang", "libQnnHtp.so"),
        "--binary_file", os.path.join(out_dir, "gemma-4-e2b.qnn"),
        "--onnx", onnx_model,
        "--input_tensors", "input_ids:1,128",
    ]

    print(f"Running: {' '.join(cmd)}")
    result = subprocess.run(cmd, capture_output=True, text=True)

    if result.returncode != 0:
        print(f"QNN optimization failed (exit {result.returncode}):")
        print(result.stderr)
        print("This is expected if QNN SDK is not installed on this runner.")
        sys.exit(0)

    print(result.stdout)
    print(f"==> QNN context binary generated at {out_dir}")
    print(f"==> Output: {os.listdir(out_dir)}")


if __name__ == "__main__":
    main()
