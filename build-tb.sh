#!/bin/bash
#
# Copyright (C) 2020 azrim.
# All rights reserved.

# Init
KERNEL_DIR="${PWD}"
KERN_IMG="${KERNEL_DIR}"/out/arch/arm64/boot/Image.gz-dtb
ANYKERNEL="${HOME}"/Build/kernel/anykernel
COMPILER_STRING="Proton Clang 15.0.0"

# Repo URL
CLANG_REPO="https://gitlab.com/LeCmnGend/proton-clang"
ANYKERNEL_REPO="https://github.com/zhantech/Anykernel3-tissot.git" 
ANYKERNEL_BRANCH="Anykernel3"

# Compiler
CLANG_DIR="${HOME}"/Build/kernel/clang-proton
if ! [ -d "${CLANG_DIR}" ]; then
    git clone "$CLANG_REPO" -b clang-15 --depth=1 "$CLANG_DIR"
fi

# git clone https://github.com/baalajimaestro/aarch64-maestro-linux-android.git -b 07032020-9.2.1 --depth=1 "${KERNEL_DIR}/gcc"
# git clone https://github.com/baalajimaestro/arm-maestro-linux-gnueabi.git -b 07032020-9.2.1 --depth=1 "${KERNEL_DIR}/gcc32"

# Defconfig
DEFCONFIG="tissot_defconfig"
REGENERATE_DEFCONFIG="false" # unset if don't want to regenerate defconfig

# Costumize
KERNEL="Pringgodani"
RELEASE_VERSION="2.1"
DEVICE="Tissot"
KERNELTYPE="OC-Treble"
KERNEL_SUPPORT="10 - 13"
KERNELNAME="${KERNEL}-${DEVICE}-${KERNELTYPE}"
TEMPZIPNAME="${KERNELNAME}.zip"
ZIPNAME="${KERNELNAME}.zip"

# Regenerating Defconfig
regenerate() {
    cp out/.config arch/arm64/configs/"${DEFCONFIG}"
    git add arch/arm64/configs/"${DEFCONFIG}"
    git commit -m "defconfig: Regenerate"
}

# Building
makekernel() {
    echo ".........................."
    echo ".     Building Kernel    ."
    echo ".........................."
    export PATH="${HOME}"/Build/kernel/clang-proton/bin:$PATH
    # export CROSS_COMPILE=${KERNEL_DIR}/gcc/bin/aarch64-maestro-linux-gnu-
    # export CROSS_COMPILE_ARM32=${KERNEL_DIR}/gcc32/bin/arm-maestro-linux-gnueabi-
    rm -rf "${KERNEL_DIR}"/out/arch/arm64/boot # clean previous compilation
    mkdir -p out
    make O=out ARCH=arm64 ${DEFCONFIG}
    if [[ "${REGENERATE_DEFCONFIG}" =~ "true" ]]; then
        regenerate
    fi
    make -j$(nproc --all) CC=clang CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- O=out ARCH=arm64

    # Check If compilation is success
    if ! [ -f "${KERN_IMG}" ]; then
        echo -e "Kernel compilation failed, See buildlog to fix errors"
        exit 1
    fi
}

# Packing kranul
packingkernel() {
    echo "........................"
    echo ".    Packing Kernel    ."
    echo "........................"
    # Copy compiled kernel
    if [ -d "${ANYKERNEL}" ]; then
        rm -rf "${ANYKERNEL}"
    fi
    git clone "$ANYKERNEL_REPO" -b "$ANYKERNEL_BRANCH" "${ANYKERNEL}"
    cp "${KERN_IMG}" "${ANYKERNEL}"/Image.gz-dtb

    # Zip the kernel, or fail
    cd "${ANYKERNEL}" || exit
    zip -r9 "${TEMPZIPNAME}" ./*

    # Sign the zip before sending it to Telegram
    # curl -sLo zipsigner-3.0.jar https://raw.githubusercontent.com/baalajimaestro/AnyKernel2/master/zipsigner-3.0.jar
    # java -jar zipsigner-3.0.jar "${TEMPZIPNAME}" "${ZIPNAME}"
}

# Starting
echo "<b>STARTING KERNEL BUILD</b>"
echo "Device: ${DEVICE}"
echo "Kernel Name: ${KERNEL}"
echo "Build Type: ${KERNELTYPE}"
echo "Release Version: ${RELEASE_VERSION}"
echo "Linux Version: $(make kernelversion)"
echo "Android Supported: ${KERNEL_SUPPORT}"
START=$(TZ=Asia/Jakarta date +"%s")
makekernel
packingkernel
END=$(TZ=Asia/Jakarta date +"%s")
DIFF=$(( END - START ))
echo "Build for ${DEVICE} with ${COMPILER_STRING} succeed took $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)!"

echo "<b>Changelog :</b>"
echo "- Compile with Proton Clang 15.0.0"
echo "- Bump 2.1"
echo "- Upstremed Kernel to 4.9.337"
echo "- More Changelogs : https://github.com/zhantech/android_kernel_msm8953/commits/Pringgodani-OC"

echo "........................"
echo ".    Build Finished    ."
echo "........................"
