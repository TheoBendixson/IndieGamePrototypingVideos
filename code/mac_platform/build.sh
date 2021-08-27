echo "Building Mooselutions"

# pushd moves us into a directory where we will exectue commands
pushd ../../build/mac_os/

# clang will be invoked from inside of the build directory
clang -g -framework AppKit -o Mooselutions ../../code/mac_platform/mac_os_main.mm

popd

echo "Finished Building Mooselutions"
