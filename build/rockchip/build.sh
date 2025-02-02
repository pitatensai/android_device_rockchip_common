#!/bin/bash
usage() {
    echo "USAGE: [-U] [-CK] [-A] [-p] [-o] [-u] [-v VERSION_NAME]  "
    echo "No ARGS means use default build option                  "
    echo "WHERE: -U = build uboot                                 "
    echo "       -C = build kernel with Clang                     "
    echo "       -K = build kernel                                "
    echo "       -A = build android                               "
    echo "       -p = will build packaging in IMAGE      "
    echo "       -o = build OTA package                           "
    echo "       -u = build update.img                            "
    echo "       -v = build android with 'user' or 'userdebug'    "
    echo "       -d = huild kernel dts name    "
    echo "       -V = build version    "
    echo "       -J = build jobs    "
    exit 1
}

source build/envsetup.sh >/dev/null
BUILD_UBOOT=false
BUILD_KERNEL_WITH_CLANG=false
BUILD_KERNEL=false
BUILD_ANDROID=false
BUILD_AB_IMAGE=false
BUILD_UPDATE_IMG=false
BUILD_OTA=false
BUILD_PACKING=false
BUILD_VARIANT=$(get_build_var TARGET_BUILD_VARIANT)
KERNEL_DTS=""
BUILD_VERSION=""

IS_MAC_OS=false

if [ "$(uname)" == "Darwin" ]; then
    IS_MAC_OS=true
fi

if [ "$IS_MAC_OS" = true ]; then
    export PATH=/usr/local/opt/gnu-sed/libexec/gnubin/:${PATH}
    alias diff=diff3
    JOB=$(sysctl -n hw.logicalcpu)
    JOB=$((JOB / 2))
else
    JOB=$(sed -n "N;/processor/p" /proc/cpuinfo | wc -l)
fi

unset NDK_ROOT
unset SDK_ROOT
ulimit -S -n 2048

BUILD_JOBS=${JOB}

CROSS_COMPILE_ARM32=../prebuilts/gcc/linux-x86/arm/gcc-linaro-6.3.1-2017.05-x86_64_arm-linux-gnueabihf/bin/arm-linux-gnueabihf-
CROSS_COMPILE_ARM64=../prebuilts/gcc/linux-x86/aarch64/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-

if [ "$IS_MAC_OS" = true ]; then
    CROSS_COMPILE_ARM32="../prebuilts/gcc/darwin-x86/arm/arm-unknown-linux-gnueabihf/bin/arm-unknown-linux-gnueabihf-"
    CROSS_COMPILE_ARM64="../prebuilts/gcc/darwin-x86/aarch64/aarch64-unknown-linux-gnu/bin/aarch64-unknown-linux-gnu-"
fi

export IS_MAC_OS=${IS_MAC_OS}
export JOB=${JOB}
export CROSS_COMPILE_ARM32=${CROSS_COMPILE_ARM32}
export CROSS_COMPILE_ARM64=${CROSS_COMPILE_ARM64}

# check pass argument
while getopts "UCKABpouv:d:V:J:" arg; do
    case $arg in
    U)
        echo "will build u-boot"
        BUILD_UBOOT=true
        ;;
    C)
        echo "will build kernel with Clang"
        BUILD_KERNEL=true
        BUILD_KERNEL_WITH_CLANG=true
        ;;
    K)
        echo "will build kernel"
        BUILD_KERNEL=true
        ;;
    A)
        echo "will build android"
        BUILD_ANDROID=true
        ;;
    B)
        echo "will build AB Image"
        BUILD_AB_IMAGE=true
        ;;
    p)
        echo "will build packaging in IMAGE"
        BUILD_PACKING=true
        ;;
    o)
        echo "will build ota package"
        BUILD_OTA=true
        ;;
    u)
        echo "will build update.img"
        BUILD_UPDATE_IMG=true
        ;;
    v)
        BUILD_VARIANT=$OPTARG
        ;;
    V)
        BUILD_VERSION=$OPTARG
        ;;
    d)
        KERNEL_DTS=$OPTARG
        ;;
    J)
        BUILD_JOBS=$OPTARG
        ;;
    ?)
        usage
        ;;
    esac
done

TARGET_PRODUCT=$(get_build_var TARGET_PRODUCT)
TARGET_BOARD_PLATFORM=$(get_build_var TARGET_BOARD_PLATFORM)

export PROJECT_TOP=$(gettop)

cp -rf ${PROJECT_TOP}/device/rockchip/common/external/minijail/gen_constants.sh ${PROJECT_TOP}/external/minijail/gen_constants.sh

#set jdk version
if [ "$IS_MAC_OS" = true ]; then
    # rm -rf external/v8/src/base/include
    # if [ "$KERNEL_ARCH" = "arm64" ]; then
    #     ln -s prebuilts/gcc/darwin-x86/aarch64/aarch64-unknown-linux-gnu/aarch64-unknown-linux-gnu/sysroot/usr/include external/v8/src/base
    # else
    #     ln -s prebuilts/gcc/darwin-x86/arm/arm-unknown-linux-gnueabihf/arm-unknown-linux-gnueabihf/sysroot/usr/include external/v8/src/base
    # fi
    # cp external/v8/Android.libbase_mac.bp external/v8/Android.libbase.bp
    JAVA_HOME="$(/usr/libexec/java_home -v 1.8)"
    cp -rf ${PROJECT_TOP}/device/rockchip/common/external/v8/Android.libbase_macos_bp ${PROJECT_TOP}/external/v8/Android.libbase.bp
else
    # cp external/v8/Android.libbase_linux.bp external/v8/Android.libbase.bp
    cp -rf ${PROJECT_TOP}/device/rockchip/common/external/v8/Android.libbase_linux_bp ${PROJECT_TOP}/external/v8/Android.libbase.bp
    JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
fi

cp -rf ${PROJECT_TOP}/device/rockchip/common/development/cmds/monkey/src/com/android/commands/monkey/Monkey.java ${PROJECT_TOP}/development/cmds/monkey/src/com/android/commands/monkey/
cp -rf ${PROJECT_TOP}/device/rockchip/common/hardware/ril/rild/rild.rc ${PROJECT_TOP}/hardware/ril/rild/
cp -rf ${PROJECT_TOP}/device/rockchip/common/external/v8/Android_bp ${PROJECT_TOP}/external/v8/Android.bp
cp -rf ${PROJECT_TOP}/device/rockchip/common/external/f2fs-tools/Android_bp ${PROJECT_TOP}/external/f2fs-tools/Android.bp
cp -rf ${PROJECT_TOP}/device/rockchip/common/external/usb_modeswitch/usb_dongle/Android_mk ${PROJECT_TOP}/external/usb_modeswitch/usb_dongle/Android.mk
cp -rf ${PROJECT_TOP}/device/rockchip/common/external/skia/Android_bp ${PROJECT_TOP}/external/skia/Android.bp


cp -rf ${PROJECT_TOP}/device/rockchip/common/external/minijail/libminijail.c ${PROJECT_TOP}/external/minijail/libminijail.c
cp -rf ${PROJECT_TOP}/device/rockchip/common/external/tinyalsa/pcm.c ${PROJECT_TOP}/external/tinyalsa/pcm.c
cp -rf ${PROJECT_TOP}/device/rockchip/common/system/hwservicemanager/ServiceManager.cpp ${PROJECT_TOP}/system/hwservicemanager/ServiceManager.cpp
cp -rf ${PROJECT_TOP}/device/rockchip/common/system/libhidl/transport/ServiceManagement.cpp ${PROJECT_TOP}/system/libhidl/transport/ServiceManagement.cpp
cp -rf ${PROJECT_TOP}/device/rockchip/common/system/netd/server/RouteController.cpp ${PROJECT_TOP}/system/netd/server/RouteController.cpp

cp -rf ${PROJECT_TOP}/device/rockchip/common/system/bt/bta/ag/bta_ag_main.cc ${PROJECT_TOP}/system/bt/bta/ag/bta_ag_main.cc

export JAVA_HOME=${JAVA_HOME}
export PATH=$JAVA_HOME/bin:$PATH
export CLASSPATH=.:$JAVA_HOME/lib:$JAVA_HOME/lib/tools.jar
# source environment and chose target product
BUILD_NUMBER=$(get_build_var BUILD_NUMBER)
BUILD_ID=$(get_build_var BUILD_ID)
# only save the version code
SDK_VERSION=$(get_build_var CURRENT_SDK_VERSION)
UBOOT_DEFCONFIG=$(get_build_var PRODUCT_UBOOT_CONFIG)
KERNEL_ARCH=$(get_build_var PRODUCT_KERNEL_ARCH)
KERNEL_DEFCONFIG=$(get_build_var PRODUCT_KERNEL_CONFIG)
if [ "$KERNEL_DTS" = "" ]; then
    KERNEL_DTS=$(get_build_var PRODUCT_KERNEL_DTS)
fi
echo "-------------------KERNEL_DTS:$KERNEL_DTS"
PACK_TOOL_DIR=RKTools/pack_firmware
IMAGE_PATH=rockdev/Image-$TARGET_PRODUCT

lunch $TARGET_PRODUCT-$BUILD_VARIANT

if [ "$KERNEL_ARCH" = "arm64" ]; then
    CROSS_COMPILE="${CROSS_COMPILE_ARM64}"
else
    CROSS_COMPILE="${CROSS_COMPILE_ARM32}"
fi

export CROSS_COMPILE=${CROSS_COMPILE}

DATE=$(date +%Y%m%d.%H%M)
STUB_PATH=Image/"$TARGET_PRODUCT"_"$BUILD_VARIANT"_"$KERNEL_DTS"_"$BUILD_VERSION"_"$DATE"
STUB_PATH="$(echo $STUB_PATH | tr '[:lower:]' '[:upper:]')"
export STUB_PATH=$PROJECT_TOP/$STUB_PATH
export STUB_PATCH_PATH=$STUB_PATH/PATCHES

# build uboot
if [ "$BUILD_UBOOT" = true ]; then
    echo "start build uboot"
    cd u-boot && make clean && make mrproper && make distclean && ./make.sh $UBOOT_DEFCONFIG && cd -
    if [ $? -eq 0 ]; then
        echo "Build uboot ok!"
    else
        echo "Build uboot failed!"
        exit 1
    fi
fi

ADDON_ARGS="CROSS_COMPILE=${CROSS_COMPILE}"

if [ "$IS_MAC_OS" = true ]; then
    if [ "$KERNEL_ARCH" = "arm64" ]; then
        ADDON_ARGS="${ADDON_ARGS} HOSTCFLAGS=-I../prebuilts/gcc/darwin-x86/aarch64/macos/include"
    else
        ADDON_ARGS="${ADDON_ARGS} HOSTCFLAGS=-I../prebuilts/gcc/darwin-x86/arm/macos/include"
    fi
fi

if [ "$BUILD_KERNEL_WITH_CLANG" = true ]; then
    if [ "$IS_MAC_OS" = true ]; then
        ADDON_ARGS="${ADDON_ARGS} CC=../prebuilts/clang/host/darwin-x86/clang-r383902b/bin/clang LD=../prebuilts/clang/host/darwin-x86/clang-r383902b/bin/ld.lld"
    else
        ADDON_ARGS="${ADDON_ARGS} CC=../prebuilts/clang/host/linux-x86/clang-r383902b/bin/clang LD=../prebuilts/clang/host/linux-x86/clang-r383902b/bin/ld.lld"
    fi
fi

# build kernel
if [ "$BUILD_KERNEL" = true ]; then
    echo "Start build kernel"
    cd kernel && make distclean && make $ADDON_ARGS ARCH=$KERNEL_ARCH $KERNEL_DEFCONFIG -j${JOB} && make $ADDON_ARGS ARCH=$KERNEL_ARCH $KERNEL_DTS.img -j${JOB} && cd -
    if [ $? -eq 0 ]; then
        echo "Build kernel ok!"
    else
        echo "Build kernel failed!"
        exit 1
    fi

    if [ "$KERNEL_ARCH" = "arm64" ]; then
        KERNEL_DEBUG=kernel/arch/arm64/boot/Image
    else
        KERNEL_DEBUG=kernel/arch/arm/boot/zImage
    fi
    cp -rf $KERNEL_DEBUG $OUT/kernel
fi

echo "package resoure.img with charger images"
cd u-boot && ./scripts/pack_resource.sh ../kernel/resource.img && cp resource.img ../kernel/resource.img && cd -

# build android
if [ "$BUILD_ANDROID" = true ]; then
    # build OTA
    if [ "$BUILD_OTA" = true ]; then
        INTERNAL_OTA_PACKAGE_OBJ_TARGET=obj/PACKAGING/target_files_intermediates/$TARGET_PRODUCT-target_files-*.zip
        INTERNAL_OTA_PACKAGE_TARGET=$TARGET_PRODUCT-ota-*.zip
        if [ "$BUILD_AB_IMAGE" = true ]; then
            echo "make ab image and generate ota package"
            make installclean
            make -j$BUILD_JOBS
            make otapackage -j$BUILD_JOBS
            make dist -j$BUILD_JOBS
            ./mkimage_ab.sh ota
        else
            echo "generate ota package"
            make installclean
            make -j$BUILD_JOBS
            make dist -j$BUILD_JOBS
            ./mkimage.sh ota
        fi
        cp $OUT/$INTERNAL_OTA_PACKAGE_TARGET $IMAGE_PATH/
        cp $OUT/$INTERNAL_OTA_PACKAGE_OBJ_TARGET $IMAGE_PATH/
    else # regular build without OTA
        echo "start build android"
        make installclean
        make -j$BUILD_JOBS
        # check the result of make
        if [ $? -eq 0 ]; then
            echo "Build android ok!"
        else
            echo "Build android failed!"
            exit 1
        fi
    fi
fi

if [ "$BUILD_OTA" != true ]; then
    # mkimage.sh
    echo "make and copy android images"
    ./mkimage.sh
    if [ $? -eq 0 ]; then
        echo "Make image ok!"
    else
        echo "Make image failed!"
        exit 1
    fi
fi

if [ "$BUILD_UPDATE_IMG" = true ]; then
    mkdir -p $PACK_TOOL_DIR/rockdev/Image/
    cp -f $IMAGE_PATH/* $PACK_TOOL_DIR/rockdev/Image/

    echo "Make update.img"
    if [[ $TARGET_PRODUCT =~ "PX30" ]]; then
        cd $PACK_TOOL_DIR/rockdev && ./mkupdate_px30.sh
    elif [[ $TARGET_PRODUCT =~ "rk356x_box" ]]; then
        if [ "$BUILD_AB_IMAGE" = true ]; then
            cd $PACK_TOOL_DIR/rockdev && ./mkupdate_ab_$TARGET_PRODUCT.sh
        else
            cd $PACK_TOOL_DIR/rockdev && ./mkupdate_$TARGET_PRODUCT.sh
        fi
    else
        if [ "$BUILD_AB_IMAGE" = true ]; then
            cd $PACK_TOOL_DIR/rockdev && ./mkupdate_"$TARGET_BOARD_PLATFORM"_ab.sh
        else
            cd $PACK_TOOL_DIR/rockdev && ./mkupdate_$TARGET_BOARD_PLATFORM.sh
        fi
    fi

    if [ $? -eq 0 ]; then
        echo "Make update image ok!"
    else
        echo "Make update image failed!"
        exit 1
    fi
    cd -
    mv -f $PACK_TOOL_DIR/rockdev/update.img $IMAGE_PATH/
    rm -rf $PACK_TOOL_DIR/rockdev/Image
fi

if [ "$BUILD_PACKING" = true ]; then
    echo "make and copy packaging in IMAGE "

    mkdir -p $STUB_PATH
    mkdir -p $STUB_PATH/IMAGES/
    cp $IMAGE_PATH/* $STUB_PATH/IMAGES/

    #Generate patches

    .repo/repo/repo forall -c "$PROJECT_TOP/device/rockchip/common/gen_patches_body.sh"
    .repo/repo/repo manifest -r -o out/commit_id.xml
    #Copy stubs
    cp out/commit_id.xml $STUB_PATH/manifest_${DATE}.xml

    mkdir -p $STUB_PATCH_PATH/kernel
    cp kernel/.config $STUB_PATCH_PATH/kernel
    cp kernel/vmlinux $STUB_PATCH_PATH/kernel

    cp build.sh $STUB_PATH/build.sh
    #Save build command info
    echo "uboot:   ./make.sh $UBOOT_DEFCONFIG" >>$STUB_PATH/build_cmd_info.txt
    echo "kernel:  make ARCH=$KERNEL_ARCH $KERNEL_DEFCONFIG && make ARCH=$KERNEL_ARCH $KERNEL_DTS.img" >>$STUB_PATH/build_cmd_info.txt
    echo "android: lunch $TARGET_PRODUCT-$BUILD_VARIANT && make installclean && make" >>$STUB_PATH/build_cmd_info.txt
    echo "version: $SDK_VERSION" >>$STUB_PATH/build_cmd_info.txt
    echo "finger:  $BUILD_ID/$BUILD_NUMBER/$BUILD_VARIANT" >>$STUB_PATH/build_cmd_info.txt
fi
