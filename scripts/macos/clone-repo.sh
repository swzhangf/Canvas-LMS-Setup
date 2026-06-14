#!/bin/bash
# clone-repo.sh
INSTALL_PATH="$1"
USE_MIRROR="${2:-false}"
CANVAS_DIR="$INSTALL_PATH/canvas-lms"
[ -d "$CANVAS_DIR" ] && echo "Already exists: $CANVAS_DIR" && exit 0
mkdir -p "$INSTALL_PATH"
if [ "$USE_MIRROR" = "true" ]; then
    git clone "https://gitee.com/xiong-yuhai/canvas-Lms.git" "$CANVAS_DIR"
else
    git clone "https://github.com/instructure/canvas-lms.git" "$CANVAS_DIR"
fi
echo "Done!"