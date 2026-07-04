export ARCH=arm64
export SUBARCH=arm64
export PATH="$HOME/zyc-clang19/bin:$PATH"
export USE_CCACHE=1
export CCACHE_EXEC=$(which ccache)

make O=out ARCH=arm64 clean
make O=out ARCH=arm64 mrproper
make O=out ARCH=arm64 vendor/xiaomi/mi845_defconfig
scripts/kconfig/merge_config.sh -O out/ out/.config arch/arm64/configs/vendor/xiaomi/polaris.config
scripts/kconfig/merge_config.sh -O out/ out/.config arch/arm64/configs/vendor/xiaomi/droidspaces.config

# Remove any stale image so a failed build can never be packaged as if it succeeded.
rm -f out/arch/arm64/boot/Image.gz-dtb

make -j$(nproc) O=out ARCH=arm64 CC="ccache clang -fuse-ld=lld" LD=ld.lld CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- CROSS_COMPILE_COMPAT=arm-linux-gnueabi- LLVM_IAS=1 KCFLAGS="-Wno-error"
BUILD_RC=$?

# AnyKernel3 packaging (only if the compile actually succeeded AND produced a fresh image)
if [ "$BUILD_RC" -eq 0 ] && [ -f out/arch/arm64/boot/Image.gz-dtb ]; then
    echo "Build successful! Packaging with AnyKernel3..."
    cp out/arch/arm64/boot/Image.gz-dtb AnyKernel3/
    cd AnyKernel3
    zip -r9 ak3.zip * -x .git README.md ak3.zip
    cd ..
    echo "Done! Package is at AnyKernel3/ak3.zip"
else
    echo "Build failed, skip packaging."
    exit 1
fi

