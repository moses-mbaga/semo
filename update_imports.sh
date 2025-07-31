#!/bin/bash

# Update all import paths from "package:semo/" to "package:index/"
find lib -name "*.dart" -type f -exec sed -i 's/package:semo\//package:index\//g' {} \;

# Update the class name in components/semo_player.dart
if [ -f "lib/components/semo_player.dart" ]; then
  mv lib/components/semo_player.dart lib/components/index_player.dart
  sed -i 's/SemoPlayer/IndexPlayer/g' lib/components/index_player.dart
  # Update references to SemoPlayer in other files
  find lib -name "*.dart" -type f -exec sed -i 's/SemoPlayer/IndexPlayer/g' {} \;
  # Update import paths for the renamed file
  find lib -name "*.dart" -type f -exec sed -i 's/import "package:index\/components\/semo_player.dart"/import "package:index\/components\/index_player.dart"/g' {} \;
fi

echo "Import paths updated successfully!"