#!/bin/zsh
set -eu
cd "${0:A:h}"
mkdir -p build/module-cache
swiftc -module-cache-path build/module-cache Sources/Geometry.swift Sources/Behavior.swift Tests/main.swift -o build/geometry-tests
build/geometry-tests

swiftc -module-cache-path build/module-cache Sources/Behavior.swift Sources/PetView.swift Tests/Rendering/main.swift -o build/render-tests -framework AppKit
build/render-tests
