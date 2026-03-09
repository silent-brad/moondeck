#!/bin/bash
# Run this inside 'nix develop' shell
espflash flash target/xtensa-esp32s3-espidf/release/moondeck --partition-table target/xtensa-esp32s3-espidf/release/partition-table.bin --monitor
