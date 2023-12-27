#!/bin/sh

dir="./zig-out/bin"
files=($(ls "$dir" | xargs -n 1 basename))

concatenated=""
for file in "${files[@]}"; do
    concatenated+="./zig-out/bin/$file;"
done

time sh -c "$concatenated"
