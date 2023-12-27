#!/bin/sh

dir="./zig-out/bin"
files=($(ls "$dir" | xargs -n 1 basename))

total=0
for file in "${files[@]}"; do
  output=$( { time ./zig-out/bin/$file; } 2>&1 )
  real_time=$(echo "$output" | grep 'real' | awk '{gsub(/m|s/, " "); print $2 * 60 + $3}')

  echo "$file: ${real_time}s"
  total=$(echo "$total + $real_time" | bc)
done

echo "Total time: ${total}s"
echo "AVG time: $(echo "scale=4; $total / ${#files[@]}" | bc)s"
